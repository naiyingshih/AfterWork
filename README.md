# AfterWork

<p align="center">
  <img src="AfterWork/Assets.xcassets/AppIcon.appiconset/AppIcon1024x1024.png" width="120" alt="AfterWork app icon"/>
</p>

<!-- TODO: 在 GitHub 編輯器拖曳上傳截圖後，把下方所有 src="TODO" 換成 user-attachments 網址 -->
<p align="center">
  <img width="18%" height="18%" alt="goals" src="TODO" />
  <img width="18%" height="18%" alt="today" src="TODO" />
  <img width="18%" height="18%" alt="review" src="TODO" />
</p>

## Description

AfterWork is an iOS app for turning your after-work hours into steady progress. Break long-term goals into small, actionable steps, pull them into today's to-do list alongside your daily habits, and look back on a calendar to see everything you've accomplished — all synced in real time with Firebase Firestore.

<br />

## Features

### ◆ Goals（目標）
#### Break Big Goals into Small Steps
- Create a goal with a title, an optional description, and an optional target date (預計完成日期).
- Add sub-tasks (細項) right on the goal card — drag to reorder, swipe left to delete.
- A progress bar on each card shows how much of the goal is done. Long-press a card to edit or delete it.

<img width="250" alt="goalCard" src="TODO" />

#### Completion Tracked Automatically
- Check off the last sub-task and the goal is stamped with a finish date (完成日) and moves to "已完成". Uncheck any sub-task and it moves back to "未完成".
- Unfinished goals are sorted by target date, so the most urgent one stays on top. Checked sub-tasks sink to the bottom of the card.

#### Send a Step to Today
Swipe right on a sub-task and tap "加入今天" to put it on today's task list.

<img width="250" alt="addToToday" src="TODO" />

---
### ◆ Today（今天）
#### Build Habits Day by Day
- Tap a habit tag to mark it done for today — the 🔥 counter goes up each time you complete it. Long-press a tag to edit or delete the habit.
- Pick a habit type — 健康, 家務, 學習 — or choose "其他" and give it one of eight custom tag colors.
- Flexible repeat rules: 每天, 每週, 每月, or 自訂 (every N days / weeks / months / years), with an optional end date. A habit only shows up on the days it's scheduled.

<img width="250" alt="habit" src="TODO" />

#### Plan Today's Tasks
- Tap "+ 建立" to add a quick task for today, or "從目標拉取" to jump to the Goals tab and pick sub-tasks.
- Sub-tasks pulled from a goal show where they came from (來自「目標名稱」), and checking them off here updates the goal's progress too.
- Swipe left to remove a task. Removing a goal sub-task here only takes it off today's list — it stays in the goal.
- The list starts fresh every day and refreshes automatically when the date changes or when you return to the app.

<img width="250" alt="todayTasks" src="TODO" />

---
### ◆ Review（回顧）
#### Look Back on Your Progress
- A monthly calendar marks each day with colored dots for the habits you completed (up to four per day). Swipe or tap the arrows to switch months.
- Tap any date to open its achievement card (成就): that day's tasks and whether you finished them (完成任務), plus the habits you kept up (執行習慣).

<img width="250" alt="calendar" src="TODO" />

---
#### ! Always in Sync
- A change made in one tab shows up instantly in the others, and is kept in sync with Firestore in real time.
- If a save fails, the app lets you know instead of silently reverting your change.
- Designed for both Light and Dark Mode, with every color contrast-checked for readability.

**Requirements:** iOS 17.0+

<br />

## Technical Approach

### Architecture
- The Composable Architecture (TCA) — a single feature tree rooted at `AppFeature`; child features report back to their parents through delegate actions
- Firestore snapshot listeners wrapped in `AsyncStream`, subscribed once at the app root
- `@Shared` in-memory state, so every tab sees local changes without waiting for the server
- Optimistic updates with per-document writes; failed writes surface an alert
- Swift Dependencies for repositories, date, and UUID, all replaceable in tests
- Unit tests with Swift Testing and TCA `TestStore`

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full data flow and design decisions.

### Frameworks & Libraries
- SwiftUI
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- Firebase Firestore
- Swift Testing
