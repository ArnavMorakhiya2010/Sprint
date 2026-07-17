# Sprint

An uncompromising productivity app for high-achieving IB students. SwiftUI + SwiftData
+ CoreMotion, built around strict study mechanics rather than generic to-do UI.

## Status

**Phase 1 & 2 (in progress):** global theme, SwiftData models, onboarding, splash, and the
full Focus Engine (Pomodoro leaning-enforcement + FocusFlight) are implemented, including
the post-session audit and 5-minute cooldown. The Task Engine and Accountability Calendar
are not yet built.

## Setup

This repo currently ships only Swift source (no `.xcodeproj`) so it can be reviewed and
diffed cleanly. To run it:

1. In Xcode 16+, **File > New > Project > iOS > App**, name it `Sprint`, interface
   **SwiftUI**, and set the minimum deployment target to **iOS 17.0** (required by
   SwiftData).
2. Delete the template's generated `ContentView.swift` and `Info.plist`.
3. Drag the `Sprint/` folder from this repo into the new project (choose "Copy items if
   needed" and add to the app target).
4. Build and run on a physical device — the Landscape Arc Timer, the leaning forfeit
   check, and the splash haptics all require real accelerometer/gyro/haptic hardware and
   won't behave correctly in the Simulator.

## Architecture so far

- `Theme/Color+Theme.swift`, `Theme/Font+Theme.swift` — the fixed five-color palette
  (`Color.theme.skyBlue/navy/teal/beige/white`) and rounded type scale. Every view should
  build from these, never system colors.
- `Models/Subject.swift`, `Models/StudyTask.swift`, `Models/FocusSession.swift` —
  SwiftData models. `StudyTask` (not `Task`) to avoid colliding with Swift's concurrency
  type. `FocusSession` also carries `departureName`/`arrivalName` for FocusFlight runs.
- `App/SplashView.swift` — animated wordmark reveal with synced launch haptics, shown on
  every app open.
- `App/OnboardingView.swift` — first-run name/age/bedtime capture into `@AppStorage`.
  `App/RootView.swift` gates the rest of the app behind `hasCompletedOnboarding`.
- `Focus/MotionManager.swift` — CoreMotion device-motion wrapper publishing `isLeaning`:
  true only when the device reads as both landscape and inclined (propped against
  something), not flat and not held bolt upright.
- `Focus/Destination.swift` — the 10 hardcoded FocusFlight destinations.
- `Focus/HapticsManager.swift` — every haptic pattern the Focus Engine fires, including
  the launch beats and the heavier multi-pulse success sequence.
- `Focus/FocusEngine.swift` — the full session state machine for both modes:
  `configuring → armed (Pomodoro only, 5s leaning grace) → running → forfeited` or
  `→ audit → cooldown (5 min)`. FocusFlight skips the armed phase and fails instead via
  `scenePhase` leaving `.active` (no FamilyControls/Screen Time entitlement required).
  Every attempt — success or failure — is written to SwiftData the moment it starts.
- `Focus/ArcDial.swift`, `Focus/LandscapeArcTimerView.swift` — the full-screen drag-to-set
  semicircle dial (sized off `GeometryReader` + `safeAreaInsets` so nothing is clipped by
  the notch or home indicator) and every phase screen built on top of the engine,
  including the mode toggle, flight destination pickers, audit form, and cooldown lockout.
- `App/ContentView.swift`, `App/HomeStubView.swift`, `App/OrientationObserver.swift` —
  orientation-based routing (portrait → Home stub, landscape → the timer).

## Known gaps / things to verify on-device

- The leaning-detection thresholds in `MotionManager` (landscape via gravity.x/y, incline
  via gravity.z in `0.2...0.85`) are a physically-reasoned heuristic but haven't been
  hardware-verified in this environment (no macOS/Xcode toolchain available here) —
  confirm on a real phone propped at a few different angles and tune if needed.
- `GeometryReader`'s `safeAreaInsets` behavior when nested inside an ancestor
  `.ignoresSafeArea()` (used to size the full-screen arc dial) is standard, documented
  SwiftUI behavior but should be visually confirmed on an iPhone 13 in Xcode Previews or
  on-device before trusting the dial isn't clipped.
- "Boot to Home on forfeit" still returns to the timer's own setup screen rather than a
  real Home destination — iOS doesn't allow an app to force its own interface rotation,
  and there's no Home screen yet to route to. Connects properly once the Task Engine
  exists as the actual root.
- The Sessions-style analytics dashboard (total time focused, subject breakdown,
  success/failure rates) is the one remaining piece of the original Phase 2 spec and is
  intentionally not built yet.
