# AfterWork 架構

iOS App，SwiftUI + [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.23，資料存在 Firebase Firestore。

三個分頁：**目標**（長期目標與細項）、**今天**（今日習慣與任務）、**回顧**（日曆與每日成就）。

---

## 目錄結構

```
AfterWork/
├── AfterWorkApp.swift        @main，建立唯一的 Store
├── AppDelegate.swift         FirebaseApp.configure()、UIKit 外觀設定
├── AppFeature.swift          根 reducer：分頁切換 + 唯一的資料訂閱點
├── AppView.swift             TabView
│
├── Shared/                   跨分頁共用的基礎設施
│   ├── SharedStateKeys.swift    三個 @Shared(.inMemory) key
│   ├── FirestoreStream.swift    snapshot listener → AsyncStream
│   └── WriteFailureAlert.swift  寫入失敗的提示
│
├── 目標/
│   ├── GoalsFeature/View        目標列表
│   ├── GoalsModel.swift         Goal / GoalItem
│   ├── GoalsRepository.swift
│   ├── 卡片/GoalFeature/View    單一目標卡片（細項增刪、排序、加入今日）
│   └── 表單/GoalFormFeature/View 新增與編輯目標
│
├── 今天/
│   ├── TodayFeature/View
│   ├── HabitManageFeature.swift + Views/HabitManageSheet.swift
│   ├── TodayTaskSheetFeature.swift + Views/TodayTaskSheet.swift
│   ├── Models/       HabitModel、TodayTaskModel
│   └── Repositories/ HabitsRepository、TodayTasksRepository
│
├── 回顧/
│   ├── CalendarFeature/View     月曆 + 成就卡
│   └── Views/AchievementCardView.swift
│
├── Helper/    Color+App（語意色票）、DateFormatter+Ext
└── Manager/   UserInfoManager（UserDefaults）
```

Xcode 專案使用 **file system synchronized groups**，新增檔案不需要動 `project.pbxproj`。

---

## Reducer 樹

```
AppFeature
├── Scope → GoalsFeature
│            ├── ifLet(\.$goalForm) → GoalFormFeature
│            └── forEach(\.goals)   → GoalFeature      (State == Goal)
├── Scope → TodayFeature
│            ├── ifLet(\.$habitManage) → HabitManageFeature
│            ├── ifLet(\.$taskSheet)   → TodayTaskSheetFeature
│            └── ifLet(\.$alert)
└── Scope → CalendarFeature            (純讀取，沒有 effect)
```

子 feature 一律透過 `delegate` action 往上回報，父層決定要不要關閉畫面、要不要寫進資料庫。子 feature 自己不碰 repository（唯一例外是 `GoalsFeature`，它是目標資料的寫入者）。

---

## 資料流

這是整個 app 最重要的一段。三份資料（habits、tasks、goals）有**兩條進入畫面的路徑**，各自解決不同的問題。

```
                    Firestore
                        │
        ① 讀：snapshot listener（AsyncStream）
                        │
                        ▼
          AppFeature.task 的三條長效 effect
                        │
                 .habitsUpdated / .tasksUpdated / .goalsUpdated
                        │
                        ▼
        ┌──────  @Shared(.inMemory) 三個共享陣列  ──────┐
        │                    ▲                          │
        ▼                    │ ③ 樂觀更新（同步、零延遲）  ▼
  TodayFeature ──────────────┘                    CalendarFeature
        │
        │ ② 寫：Repository 的逐筆 CRUD
        ▼
    Firestore ──（成功則 listener 回推；失敗則回滾 + 跳 alert）
```

### ① 讀取：一個訂閱點

`AppFeature.task`（由 `AppView` 的 `.task` 觸發）用 `.merge` 起三條長效 effect，各自 `.cancellable(id:, cancelInFlight: true)`。每條都在讀 `FirestoreStream.swift` 包出來的 `AsyncStream`：

```swift
firestoreCollectionStream("habits", as: Habit.self)   // addSnapshotListener + onTermination { listener.remove() }
```

**為什麼是 listener 不是每次進畫面 `getDocuments`：**

1. 本地寫入會被 Firestore 的 latency compensation 立刻回吐，畫面不必等 server 來回。
2. 其他裝置改的資料會自己推進來。
3. 各分頁不必再各自 `onAppear` 重抓 —— 這正是「今天勾完任務、切到回顧字沒變」那個 bug 的根源。

**沒有任何 View 會為了拿資料而觸發抓取。** 三個分頁都沒有 fetch 用的 `onAppear`。

### ② 寫入：逐筆 CRUD，樂觀更新

寫入**不走** shared key，而是走 repository 的逐筆 API（`updateTask`、`saveHabit`、`updateGoalDetails`…）。順序固定是：

1. 先改共享狀態（畫面立刻反應）
2. 再送 Firestore，`await` 到伺服器確認為止
3. 失敗 → `.writeFailed(error)` → `state.alert = .writeFailed(error)`

第 3 步不能省。因為是樂觀更新，寫入最終失敗時 Firestore 會**回滾那筆 pending write**，listener 隨即把舊值推回來 —— 沒有 alert 的話，使用者只會看到「剛勾好的任務自己取消勾選」，卻沒有任何線索。

> ⚠️ **寫入一律「自己編碼 + 走 async 的 `setData(_:)`」，不要用 Codable 版的 `setData(from:)`。**
>
> `setData(from:)` 的 `completion` 是選填參數，不傳就是**同步 throwing** —— 加 `await` 沒有作用（編譯器會警告 "no 'async' operations occur within 'await' expression"），而且它只會在**編碼失敗**時 throw；伺服器拒絕（權限、安全規則）永遠傳不回來，上面第 3 步就形同虛設。
>
> 正確寫法（跟 `updateGoalDetails` 一致）：
> ```swift
> let data = try Firestore.Encoder().encode(habit)
> try await documentRef.setData(data)   // ObjC 橋接的 async 版，會等 server ack
> ```
>
> 代價：離線時 completion 永遠不會被呼叫，effect 會一直掛著直到重新連線。這沒有使用者可見的副作用（畫面早就樂觀更新過了，而且離線不會觸發回滾），只是會累積待決的 task。

### ③ 共享狀態：讓本地變更同步傳播

`Shared/SharedStateKeys.swift` 定義三個 in-memory key：

| key | 型別 | 內容 |
|---|---|---|
| `.habits` | `IdentifiedArrayOf<Habit>` | 全部習慣，不分日期 |
| `.todayTasks` | `IdentifiedArrayOf<TodayTask>` | 全部任務，不分日期 |
| `.goals` | `IdentifiedArrayOf<Goal>` | 全部目標，含細項 |

三個 feature 都用同一組名稱宣告：`allHabits` / `allTasks` / `allGoals`。**一律存完整清單**，要看哪一段由各 feature 自己篩（例如今天分頁只顯示今天排到的習慣）。

**AsyncStream 與 @Shared 不是二選一，它們解不同軸向的問題：**

|  | AsyncStream | @Shared(.inMemory) |
|---|---|---|
| 解決 | 何時有新資料（時間軸） | 誰看得到（空間軸） |
| 來源 | Firestore、其他裝置 | 本地任一 feature 的寫入 |
| 延遲 | 網路來回，離線時無限 | 同步、零延遲 |

只有 stream 沒有 shared 的話，今天分頁勾完任務，回顧分頁得等 server echo 回來才知道；離線時永遠等不到。

---

## GoalsFeature 是唯一的例外

`GoalsFeature` 用 `.forEach(\.goals, action: \.goal)`，而 `forEach` 需要 `WritableKeyPath<State, IdentifiedArray<…>>`；`@Shared` 的 `wrappedValue` 沒有 setter，接不上。所以目標分頁保留自己的儲存屬性 `var goals`，由 `AppFeature` 在 `.goalsUpdated` 時餵一份進去。

餵的時候必須保留 `Goal.LocalEditing`：

```swift
struct Goal {
    /// 只存在本地、不會寫進 Firestore 的編輯狀態
    struct LocalEditing: Equatable, Sendable {
        var isAddingItem = false
        var newItemTitle = ""
        var expanded: Bool?
    }
    var local = LocalEditing()
}
```

整份換掉會把使用者打到一半的細項標題洗掉。收成一包（而不是逐欄保留）是為了讓「之後加新欄位卻忘了保留」變成不可能 —— 那種 bug 的症狀是輸入到一半的字被遠端推播吃掉，非常難查。

**要徹底移除這段手動同步**，得把 `GoalFeature.State` 從 `typealias State = Goal` 改成持有 `@Shared var goal: Goal`（TCA 的 "Deriving shared state"：`Shared($allGoals[id: id])`）。但那會讓 `GoalFeature` 每個就地修改都要包 `withLock`，而且集合的成員增減仍然要對帳 —— 同步不會消失，只會換形狀。目前判斷不划算。

---

## Dependencies

| Dependency | 用途 |
|---|---|
| `habitsRepository` / `todayTasksRepository` / `goalsRepository` | Firestore 讀寫，各含一個 `stream*` 與逐筆 CRUD |
| `\.date` | 所有會被寫進資料的時間 |
| `\.uuid` | 所有新建實體的 id |
| `\.dismiss` | 未使用（目前由父層 nil 掉 presentation state） |

三個 repository 都有 `liveValue` / `testValue` / `previewValue`：

- `testValue` 全部是 `unimplemented(…)` —— 測試裡忘了覆寫就會大聲失敗，不會偷偷連上真的 Firestore。
- `previewValue` 回傳假資料 —— 預設會落到 `liveValue`，而 SwiftUI 預覽環境沒有跑 `FirebaseApp.configure()`。

### 時間與 id 的規則

**會被寫進資料的，一律走 dependency。** Repository 只做 I/O，不再自己補 `updatedTime`（以前會，導致本地 state 與雲端的時間戳不一致）；時間由 reducer 設好再交出去，`updateGoalDetails` 因此也多收一個 `Date` 參數。

**例外：State 的預設值。** `TodayFeature.today`、`CalendarFeature.selectedDate` / `currentMonth` 仍然用 `Date()`。它們是「畫面初始停在哪」的種子值，不是會被持久化的資料。改成讀 dependency 的話，測試裡建 `AppFeature.State()` 就會踩到未實作的 `date` 而失敗。測試要控時間直接指定這些欄位即可。

`TodayFeature.today` 另有一個作用：所有「今天的」清單都以它為基準篩選。若在計算屬性裡直接呼叫 `Date()`，跨日時 state 沒有變化，SwiftUI 不會重繪。進畫面／回到前景／收到系統跨日通知時，`.refreshToday` 會用 `@Dependency(\.date)` 對時。

---

## 慣例

### Presentation

一律 `@Presents` + `PresentationAction` + `.ifLet(\.$xxx, action: \.xxx)`：`habitManage`、`taskSheet`、`alert`、`goalForm`。

`goalForm` 雖然不是 sheet 而是自繪的 overlay，也走同一套（scrim 點擊送 `.goalForm(.dismiss)`）。

### 衍生資料放在 State，不放在 View

「選了某天 → 那天有哪些成就」這類邏輯屬於 State 的計算屬性，View 只負責畫。`CalendarFeature.State` 上有：

- `achievementTasks` — 選中那天的今日任務 + 目標細項，統一成 `AchievementTask`
- `achievementHabits` — 選中那天執行過的習慣
- `habitTypesByDay: [Date: Set<HabitType>]` — 日曆格子的小圓點

同理 `TodayFeature.State` 的 `habits` / `todayTasks` / `goalItems` 都是從共享陣列篩出來的計算屬性。

⚠️ **計算屬性每次讀取都會重算。** `habitTypesByDay` 做成 dictionary 就是為了讓 `MonthGridView` **整頁讀一次**再分給 42 個格子；每格自己去掃全部習慣的 `completedDates` 是 42 × N 次日期比對，而且每次重繪重來。

### 顏色

色票放在 `Assets.xcassets/Colors`，`Helper/Color+App.swift` 只補推導出來的語意色。`labelSecondary` / `labelTertiary` / `onFill` 是各自獨立的色票而非 opacity 疊出來的 —— 深色模式用 opacity 推導會讓次要文字掉到 2.3:1。NavigationBar 與 TabBar 是 UIKit 畫的，在 `AppDelegate.configureAppearance()` 統一設定。

---

## 測試

`AfterWorkTests/`，使用 swift-testing（`@Test`）+ TCA `TestStore`。

| 檔案 | 守的東西 |
|---|---|
| `TodayCalendarSyncTests` | 今天分頁勾任務／勾習慣後，回顧分頁**當下**就是新的；寫入失敗會跳提示而不是無聲回滾 |
| `AppFeatureStreamTests` | Firestore 推播會灌進共享狀態讓兩個分頁一起看到；目標推播不會洗掉正在輸入中的細項 |
| `CalendarDerivedStateTests` | 成就卡與日曆圓點的衍生邏輯（這幾段以前寫在 View 裡，完全測不到） |

寫測試時：

- 用 `$0.date = .constant(fixedDate)` 固定時間，`fixedDate` 同時拿去建 model，State 的 `today` / `selectedDate` 直接指定。
- Repository 的 `stream*` 用 `AsyncStream.makeStream(of:)` 手動推值，測完 `await subscription.cancel()`。
- 共享狀態在斷言 closure 裡用 `$0.$allTasks.withLock { … }` 修改。

### 建置與執行

```bash
xcodebuild -project AfterWork.xcodeproj -scheme AfterWork \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:AfterWorkTests test
```

---

## 已知取捨與未來工作

**取捨**

- 每個 collection 各掛一條全程存活的 listener。Firestore 按文件讀取計費，資料量長大後可以讓 `stream*` 帶 query 條件（例如只訂當月）—— 訂閱集中在 `AppFeature`，只要改一個地方。
- 沒有選 TCA 的「自訂 `SharedKey`」方案（把 listener 包進 shared key 裡）。原因是 `SharedKey.save` 的粒度是**整個集合**，跟逐筆 document 的寫入對不上：每次 `withLock` 都會觸發一次整包 save，還得自己 diff 才知道哪一筆變了。

**未來工作**

- `Goal.isExpanded` 的 getter/setter 直接讀寫 `UserInfoManager.shared`（UserDefaults）。一個 Codable 的 Firestore 模型不該碰 UserDefaults，而且這條路徑在測試裡不可覆寫。要處理時建議連同上面的 `GoalFeature.State` 一起搬。
- `GoalsView` 的 `store.scope(state: \.uncompletedGoals, …)` 指向會 filter + sort 的計算屬性。能動，但目標一達 100% 就會從「未完成」跳到「已完成」段，element store 的身分靠 id 維持，動畫可能會抖。
