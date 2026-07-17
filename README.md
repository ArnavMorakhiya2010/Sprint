# Sprint

An uncompromising productivity app for high-achieving IB students. SwiftUI + SwiftData
+ CoreMotion, built around strict study mechanics rather than generic to-do UI. Visual
design follows a reference design system (palette, type, component language, and a
mascot concept called "Pom") — the app itself keeps the Sprint name, since renaming it
wasn't explicitly requested.

## Status

**Phase 1 & 2 (in progress):** global theme, SwiftData models, onboarding (name, age,
subjects, bedtime), splash, and the full Focus Engine — Pomodoro with leaning-enforcement,
a subject picker, and a full circular timer ring; FocusFlight with a live short-haul map;
a built-in synthesized ambient soundscape; a completion alarm; break-activity suggestions;
and a basic analytics dashboard — are implemented. The Task Engine and Accountability
Calendar are not yet built.

## Setup

This repo currently ships only Swift source (no `.xcodeproj`) so it can be reviewed and
diffed cleanly. To run it:

1. In Xcode 16+, **File > New > Project > iOS > App**, name it `Sprint`, interface
   **SwiftUI**, and set the minimum deployment target to **iOS 17.0** (required by
   SwiftData and the MapKit `Map`/`MapCameraPosition` APIs).
2. Delete the template's generated `ContentView.swift` and `Info.plist`.
3. Drag the `Sprint/` folder from this repo into the new project (choose "Copy items if
   needed" and add to the app target).
4. **Optional — Poppins font.** `Font+Theme.swift` references `"Poppins-Regular"` /
   `-Medium` / `-SemiBold` / `-Bold` by name. `Font.custom` falls back to the system font
   automatically if they aren't registered, so nothing breaks without this step — but to
   get real Poppins, download the family from Google Fonts, add the `.ttf` files to the
   app target, and list them under **Info.plist → Fonts provided by application
   (`UIAppFonts`)**.
5. **Optional — Pom mascot artwork.** `PomMascotView` looks for images named `pom_idle`,
   `pom_running`, `pom_sleeping`, `pom_celebrating` in the asset catalog first. This tool
   has no way to generate the actual illustrated character art from the reference — add
   real exports to `Assets.xcassets` under those exact names to use them. Without them, a
   simple shape-built placeholder (circle body, glasses, a leaf, stick limbs) is drawn
   instead — a rough stand-in, not a reproduction of the reference illustrations.
6. Build and run on a physical device — the timer ring drag, the leaning forfeit check,
   the splash/alarm/haptics, and the ambient audio all require real
   accelerometer/gyro/speaker hardware and won't behave correctly in the Simulator.

## Design system

- **Palette** (`Theme/Color+Theme.swift`): `cream` #F7EBE1 (background), `orange` #F58D4C
  (primary accent/buttons), `peach` #F4B9B8 (secondary/disabled), `espresso` #34271F
  (primary text). Plus `charcoal`, a reasoned near-black extension for the one state the
  spec describes but doesn't give a hex for — the deep-focus dark background — since only
  four swatches were provided.
- **Type** (`Theme/Font+Theme.swift`): Poppins, with the exact named scale from spec —
  `h1Large`/`h1Small`/`h2`/`h3`/`bodyLarge`/`bodyMedium1`/`bodyMedium2`/`bodySmall`/
  `button` — plus one addition outside that scale, `timerDigits(_:)`, for the massive
  session-clock numerals, which are far larger than H1.
- **Components**: pill-shaped (`Capsule`) buttons and text fields throughout, per spec.
  Primary buttons are orange-filled with cream text; secondary/disabled are peach.
- **Pom** (`Focus/PomMascotView.swift`): idle, running, sleeping, and celebrating poses —
  see Setup #5 for how to swap the placeholder for real artwork.

## Architecture so far

- `Models/Subject.swift`, `Models/StudyTask.swift`, `Models/FocusSession.swift` —
  SwiftData models. `StudyTask` (not `Task`) to avoid colliding with Swift's concurrency
  type. `FocusSession` carries `departureName`/`arrivalName` for FocusFlight runs.
- `App/SplashView.swift` — Pom + wordmark reveal with synced launch haptics, shown on
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
- `Focus/SoundscapePlayer.swift` — the built-in ambient player, all three options fully
  synthesized on-device via `AVAudioEngine` (no bundled recordings, so nothing is ever
  silent because a file is missing): Rain (low-passed white noise), Coffee Shop
  (band-passed noise with a slow amplitude swell approximating murmur), Chill Beats (a
  soft, slowly breathing three-note chord — an ambient pad, not an actual rhythmic beat,
  since a convincing recorded/sequenced track isn't something this tool can generate).
  Reachable from a small corner control visible in every Focus Engine phase.
- `Focus/FocusEngine.swift` — the full session state machine for both modes:
  `configuring → armed (Pomodoro only, 5s leaning grace) → running → forfeited` or
  `→ audit → cooldown (5 min, with two random BreakActivity suggestions)`. FocusFlight
  skips the armed phase and fails instead via `scenePhase` leaving `.active` (no
  FamilyControls/Screen Time entitlement required). `selectedSubject` is live/mutable
  during `.configuring`, not fixed at init. Every attempt — success or failure — is
  written to SwiftData the moment it starts.
- `Focus/PomTimerRing.swift` — the full circular progress ring from the reference (starts
  at 12 o'clock, fills clockwise), replacing the earlier semicircle arc dial. Doubles as
  the interactive Pomodoro duration control (drag anywhere on the ring in `.configuring`)
  and the passive elapsed-progress indicator while running.
- `Focus/FlightMapView.swift` — FocusFlight's running screen: a live (non-interactive)
  MapKit route, with the plane's position driven by an `animatedProgress` state updated
  inside `withAnimation(.linear(duration: 1))` on every engine tick, so it glides
  continuously between the once-per-second updates instead of hopping.
- `Focus/LandscapeArcTimerView.swift` — assembles every phase screen. Background flips
  between cream (light) and charcoal (the spec's "Dark Mode Focus State") depending on
  phase — charcoal only for `armed`/`running`, with Pom and secondary chrome hidden there
  to "fade away and prevent distractions," matching spec. Also hosts the Pomodoro subject
  picker, the boarding-pass-style FocusFlight setup card, the mode toggle (positioned
  below the ring/card, not overlapping it), and the soundscape control overlay.
- `Analytics/AnalyticsView.swift` — total time focused, a per-subject bar breakdown, a
  success-rate tile, and a recent-sessions list, all from a live `@Query` over
  `FocusSession`. Presented as a sheet from a "View Analytics" button on the Home stub.
- `App/ContentView.swift`, `App/HomeStubView.swift`, `App/OrientationObserver.swift` —
  orientation-based routing (portrait → Home stub, landscape → the timer).

## Known gaps / things to verify on-device

- No font or mascot image assets ship in this repo (see Setup #4–5) — both degrade
  gracefully (system font; a shape-built placeholder) rather than breaking, but neither
  matches the reference until you add the real files.
- No audio assets are needed anymore — all three soundscapes are synthesized. They (plus
  `AlarmPlayer`) are reasoned-through but literally unheard in this environment (no
  macOS/Xcode toolchain or speaker here) — confirm the character and levels on a real
  device.
- The leaning-detection thresholds in `MotionManager` and the `airplane` SF Symbol's
  rotation offset in `FlightMapView` are similarly reasoned but unverified on hardware.
- `GeometryReader`'s `safeAreaInsets` behavior when nested inside an ancestor
  `.ignoresSafeArea()` (used to size the full-screen ring) is standard, documented SwiftUI
  behavior but should be visually confirmed on-device — the Pomodoro setup screen in
  particular stacks mascot + picker + ring + toggle + button in one landscape column and
  hasn't been checked for vertical crowding on a real screen.
- The flight route is a straight linear interpolation between two coordinates, not a
  geodesic — reads fine as a stylized short-haul tracker, isn't literal navigation.
- "Boot to Home on forfeit" still returns to the timer's own setup screen rather than a
  real Home destination — iOS doesn't allow an app to force its own interface rotation,
  and there's no Home screen yet to route to. Connects properly once the Task Engine
  exists as the actual root.
