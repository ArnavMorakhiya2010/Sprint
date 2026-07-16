# Sprint

An uncompromising productivity app for high-achieving IB students. SwiftUI + SwiftData
+ CoreMotion, built around strict study mechanics rather than generic to-do UI.

## Status

**Phase 1 (in progress):** global theme, SwiftData models, and the Focus Engine's
Landscape Arc Timer with CoreMotion face-down enforcement are implemented. The Task
Engine and Accountability Calendar are not yet built.

## Setup

This repo currently ships only Swift source (no `.xcodeproj`) so it can be reviewed and
diffed cleanly. To run it:

1. In Xcode 16+, **File > New > Project > iOS > App**, name it `Sprint`, interface
   **SwiftUI**, and set the minimum deployment target to **iOS 17.0** (required by
   SwiftData).
2. Delete the template's generated `ContentView.swift` and `Info.plist`.
3. Drag the `Sprint/` folder from this repo into the new project (choose "Copy items if
   needed" and add to the app target).
4. Build and run on a physical device — the Landscape Arc Timer and Face-Down Forfeit
   both require real accelerometer/gyro data and won't behave correctly in the
   Simulator.

## Architecture so far

- `Theme/Color+Theme.swift`, `Theme/Font+Theme.swift` — the fixed five-color palette
  (`Color.theme.paper/ink/moss/marigold/sand`) and rounded type scale. Every view should
  build from these, never system colors.
- `Models/Subject.swift`, `Models/StudyTask.swift`, `Models/FocusSession.swift` —
  SwiftData models. `StudyTask` (not `Task`) to avoid colliding with Swift's concurrency
  type.
- `Focus/MotionManager.swift` — CoreMotion device-motion wrapper publishing
  face-up/face-down state.
- `Focus/HapticsManager.swift` — every haptic pattern the Focus Engine fires.
- `Focus/FocusEngine.swift` — the session state machine: configuring → armed (5s
  face-down grace) → running → forfeited/completed. Logs every attempt to SwiftData,
  success or failure.
- `Focus/ArcDial.swift`, `Focus/LandscapeArcTimerView.swift` — the drag-to-set semicircle
  dial and the full landscape screen built on top of the engine.
- `App/` — app entry point, `ModelContainer` setup, and orientation-based routing
  (portrait → Home stub, landscape → the timer).

## Known gaps / things to verify on-device

- The face-down gravity threshold in `MotionManager` (`z > 0.75`) is a standard
  convention but hasn't been hardware-verified in this environment (no macOS/Xcode
  toolchain available here) — confirm on a real phone and tune if needed.
- "Boot to Home on forfeit" currently returns to the timer's own setup screen rather than
  a real Home destination, since iOS doesn't allow an app to force its own interface
  rotation and there's no Home screen yet to route to. This will connect properly once
  the Task Engine (Phase 3) exists as the actual root.
- Post-session audit (focus rating + notes), the 5-minute cooldown screen, FocusFlight
  (Screen Time blocking), and the analytics dashboard are the rest of Phase 2 / Module 1
  and are intentionally not built yet — the request asked for the arc timer and
  CoreMotion logic first.
