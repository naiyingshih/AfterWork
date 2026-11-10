# AfterWork

<p align="center">
  <img width="120" height="120" alt="Afterwork" src="https://github.com/user-attachments/assets/17cd2e27-3aea-4997-b1f9-41edd5003833" />
</p>

<p align="center">
  <img width="18%" height="18%" alt="Goals — Light@3x" src="https://github.com/user-attachments/assets/34c1dc35-9e35-442f-bab3-2a655ee62034" />
  <img width="18%" height="18%" alt="Today — Light@3x" src="https://github.com/user-attachments/assets/826dea75-d836-4a67-bbf2-4e61746ec24b" />
  <img width="18%" height="18%" alt="Review — Light@3x" src="https://github.com/user-attachments/assets/c0311bcb-a5a7-454a-97db-c17e1ccb7da9" />
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

<p align="leading">
  <img width="18%" height="18%" alt="Goal Form — Light" src="https://github.com/user-attachments/assets/6f9b6943-b968-4136-b65d-9edb315a062c" />
  <img width="18%" height="18%" alt="goal_addDetail" src="https://github.com/user-attachments/assets/27bebd76-43be-4c5d-80e7-82ae3e0233bd" />
  <img width="18%" height="18%" alt="goal_edit" src="https://github.com/user-attachments/assets/81989e9a-bf80-43f3-910a-927d93ceadc4" />
</p>

#### Completion Tracked Automatically
- Check off the last sub-task and the goal is stamped with a finish date (完成日) and moves to "已完成". Uncheck any sub-task and it moves back to "未完成".
- Unfinished goals are sorted by target date, so the most urgent one stays on top. Checked sub-tasks sink to the bottom of the card.

#### Send a Step to Today
Swipe right on a sub-task and tap "加入今天" to put it on today's task list.

<img width="18%" height="18%" alt="goal_addToToday" src="https://github.com/user-attachments/assets/23ae7cdf-569b-4758-9e4e-7ca2fb17727b" />

---
### ◆ Today（今天）
#### Build Habits Day by Day
- Tap a habit tag to mark it done for today — the 🔥 counter goes up each time you complete it. Long-press a tag to edit or delete the habit.
- Pick a habit type — 健康, 家務, 學習 — or choose "其他" and give it one of eight custom tag colors.
- Flexible repeat rules: 每天, 每週, 每月, or 自訂 (every N days / weeks / months / years), with an optional end date. A habit only shows up on the days it's scheduled.

<p align="leading">
  <img width="18%" height="18%" alt="Habit Sheet — Light" src="https://github.com/user-attachments/assets/aa48d647-b114-43a0-a42e-ffa2b7001651" />
  <img width="18%" height="18%" alt="Today — Light" src="https://github.com/user-attachments/assets/0b9c1c66-3cd4-4a05-a3f4-6b803cf41a05" />
</p>

#### Plan Today's Tasks
- Tap "+ 建立" to add a quick task for today, or "從目標拉取" to jump to the Goals tab and pick sub-tasks.
- Sub-tasks pulled from a goal show where they came from (來自「目標名稱」), and checking them off here updates the goal's progress too.
- Swipe left to remove a task. Removing a goal sub-task here only takes it off today's list — it stays in the goal.
- The list starts fresh every day and refreshes automatically when the date changes or when you return to the app.

<p align="leading">
  <img width="18%" height="18%" alt="Task Sheet — Light" src="https://github.com/user-attachments/assets/aadcc58e-d890-4a5e-960e-f96276d806f0" />
  <img width="18%" height="18%" alt="Today_delete" src="https://github.com/user-attachments/assets/c13b9a8f-ed26-417b-9496-77caf56c458c" />
</p>

---
### ◆ Review（回顧）
#### Look Back on Your Progress
- A monthly calendar marks each day with colored dots for the habits you completed (up to four per day). Swipe or tap the arrows to switch months.
- Tap any date to open its achievement card (成就): that day's tasks and whether you finished them (完成任務), plus the habits you kept up (執行習慣).

<img width="18%" height="18%" alt="Review — Light" src="https://github.com/user-attachments/assets/1a049638-83dd-47e9-aea5-b28a8ded9e76" />

---

**Requirements:** iOS 17.0+
- Designed for both Light and Dark Mode, with every color contrast-checked for readability.
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
