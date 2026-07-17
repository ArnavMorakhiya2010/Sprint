# Sprint

An uncompromising productivity app for high-achieving IB students. SwiftUI + SwiftData
+ CoreMotion, built around strict study mechanics rather than generic to-do UI.

## Status

**Phase 1 & 2 (in progress):** global theme, SwiftData models, onboarding (name, age,
subjects, bedtime), splash, and the full Focus Engine — Pomodoro with leaning-enforcement
and a subject picker, FocusFlight with a live short-haul map, a built-in ambient
soundscape, a completion alarm, break-activity suggestions, and a basic analytics
dashboard — are implemented. The Task Engine and Accountability Calendar are not yet
built.

## Setup

This repo currently ships only Swift source (no `.xcodeproj`) so it can be reviewed and
diffed cleanly. To run it:

1. In Xcode 16+, **File > New > Project > iOS > App**, name it `Sprint`, interface
   **SwiftUI**, and set the minimum deployment target to **iOS 17.0** (required by
   SwiftData and the MapKit `Map`/`MapCameraPosition` APIs).
2. Delete the template's generated `ContentView.swift` and `Info.plist`.
3. Drag the `Sprint/` folder from this repo into the new project (choose "Copy items if
   needed" and add to the app target).
4. **Optional — real ambient audio.** `SoundscapePlayer` ships a fully working, synthesized
   "Rain" (filtered white noise, no asset needed). "Chill Beats" and "Coffee Shop" expect
   looping MP3s named exactly `chill_beats.mp3` and `coffee_shop.mp3` added to the app
   target's bundle resources — this repo doesn't (and can't) ship real recorded/melodic
   audio. Without those files, picking those two options is silent (no crash) until you
   add them.
5. Build and run on a physical device — the Landscape Arc Timer, the leaning forfeit
   check, the splash/alarm/haptics, and the ambient audio all require real
   accelerometer/gyro/speaker hardware and won't behave correctly in the Simulator.

## Architecture so far

- `Theme/Color+Theme.swift`, `Theme/Font+Theme.swift` — the fixed six-color palette
  (`Color.theme.white/pearl/khaki/taupe/cacao/leather`) and rounded type scale.
- `Models/Subject.swift`, `Models/StudyTask.swift`, `Models/FocusSession.swift` —
  SwiftData models. `StudyTask` (not `Task`) to avoid colliding with Swift's concurrency
  type. `FocusSession` carries `departureName`/`arrivalName` for FocusFlight runs.
- `App/SplashView.swift` — animated wordmark reveal with synced launch haptics, shown on
  every app open.
- `App/OnboardingView.swift` — first-run name → age → subjects → bedtime flow. Subjects
  are typed in as chips and saved as real `Subject` records via `modelContext`, so they're
  immediately available to the Pomodoro subject picker. `App/RootView.swift` gates the
  rest of the app behind `hasCompletedOnboarding`.
- `Focus/MotionManager.swift` — CoreMotion device-motion wrapper publishing `isLeaning`:
  true only when the device reads as both landscape and inclined (propped against
  something), not flat and not held bolt upright.
- `Focus/Destination.swift` — 10 short-haul Western/Central European cities (all
  real-world under ~2 hours apart) for FocusFlight, each with a real coordinate and a
  3-letter boarding-pass-style code.
- `Focus/FlightCalculator.swift` — turns a Departure/Arrival pair into a real great-circle
  distance (`CLLocation.distance(from:)`) and a duration at a fixed cruise speed plus
  ground overhead, hard-capped at 120 minutes. FocusFlight's length is always this
  computed value, never something the user drags to set.
- `Focus/BreakActivity.swift` — the cooldown's rotating micro-activity suggestions (drink
  water, jumping jacks, the 20-20-20 eye rule, etc).
- `Focus/HapticsManager.swift` — every haptic pattern the Focus Engine fires.
- `Focus/AlarmPlayer.swift` — a synthesized 4-beep alarm (a precomputed sine-wave
  `AVAudioPCMBuffer` played via `AVAudioPlayerNode`) fired the instant a session
  completes, alongside the haptics — zero bundled-asset dependency.
- `Focus/SoundscapePlayer.swift` — the built-in ambient player: Off / Rain (synthesized,
  low-passed white noise via `AVAudioEngine` + `AVAudioSourceNode`) / Chill Beats / Coffee
  Shop (the latter two play a bundled loop if present — see Setup above). Reachable from a
  small corner control visible in every Focus Engine phase, so there's never a reason to
  background the app for music.
- `Focus/FocusEngine.swift` — the full session state machine for both modes:
  `configuring → armed (Pomodoro only, 5s leaning grace) → running → forfeited` or
  `→ audit → cooldown (5 min, with two random BreakActivity suggestions)`. FocusFlight
  skips the armed phase and fails instead via `scenePhase` leaving `.active` (no
  FamilyControls/Screen Time entitlement required). `selectedSubject` is live/mutable
  during `.configuring`, not fixed at init. Every attempt — success or failure — is
  written to SwiftData the moment it starts.
- `Focus/ArcDial.swift` — the Pomodoro duration dial: tick marks, a soft glow layer, and a
  Taupe→Cacao gradient progress stroke with a bordered knob. Pomodoro-only — FocusFlight
  has nothing for it to set.
- `Focus/FlightMapView.swift` — FocusFlight's running screen: a live (non-interactive)
  MapKit route, with the plane's position driven by an `animatedProgress` state that's
  updated inside `withAnimation(.linear(duration: 1))` on every engine tick, so it glides
  continuously between the once-per-second updates instead of hopping.
- `Focus/LandscapeArcTimerView.swift` — assembles every phase screen: the Pomodoro subject
  picker (`@Query`-driven `Menu` over saved `Subject`s, defaulting to "General"), the
  boarding-pass-style FocusFlight setup card, the mode toggle positioned below the
  dial/card, and the soundscape control overlay.
- `Analytics/AnalyticsView.swift` — total time focused, a per-subject bar breakdown, a
  success-rate tile, and a recent-sessions list, all from a live `@Query` over
  `FocusSession`. Presented as a sheet from a "View Analytics" button on the Home stub.
- `App/ContentView.swift`, `App/HomeStubView.swift`, `App/OrientationObserver.swift` —
  orientation-based routing (portrait → Home stub, landscape → the timer).

## Known gaps / things to verify on-device

- No audio assets ship in this repo (see Setup #4) — Chill Beats/Coffee Shop are silent
  until you add `chill_beats.mp3`/`coffee_shop.mp3`. Rain needs no asset.
- The leaning-detection thresholds in `MotionManager`, the `airplane` SF Symbol's rotation
  offset in `FlightMapView`, and the synthesized audio in `AlarmPlayer`/`SoundscapePlayer`
  are all reasoned-through but unheard/unverified in this environment (no macOS/Xcode
  toolchain or speaker available here) — confirm on a real device.
- `GeometryReader`'s `safeAreaInsets` behavior when nested inside an ancestor
  `.ignoresSafeArea()` (used to size the full-screen arc dial) is standard, documented
  SwiftUI behavior but should be visually confirmed on-device.
- The flight route is a straight linear interpolation between two coordinates, not a
  geodesic — reads fine as a stylized short-haul tracker, isn't literal navigation.
- "Boot to Home on forfeit" still returns to the timer's own setup screen rather than a
  real Home destination — iOS doesn't allow an app to force its own interface rotation,
  and there's no Home screen yet to route to. Connects properly once the Task Engine
  exists as the actual root.
