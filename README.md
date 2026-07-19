# Sprint

An uncompromising productivity app for high-achieving IB students. SwiftUI + SwiftData
+ CoreMotion. Visual design and app structure follow a reference design system and
sitemap (palette, type, component language, a mascot concept called "Pom", and a 4-tab
navigation: Home, To-do, Reports, Settings) — the app itself keeps the Sprint name, since
renaming it wasn't explicitly requested.

## Status

The full sitemap's top-level structure now exists: a floating pill tab bar over Home
(Focus), To-do List, Reports, and Settings, plus onboarding and a chatbot. What's real vs.
stubbed, honestly:

**Fully functional:** onboarding (name/age/subjects/bedtime), the Home tab's timer card
(drag-to-set circular ring, subject picker, Pomodoro/FocusFlight toggle), the full-screen
deep-focus session (leaning/landscape enforcement, FocusFlight's live map, audit,
5-minute cooldown with break suggestions), a synthesized ambient soundscape and
completion alarm, the To-do List (search, add/edit/delete, sticky-note cards, real
SwiftData persistence), Reports (time/streak/subject stats), and the functional parts of
Settings (profile editing, sleep lockout time, default soundscape, reset onboarding).

**Deliberately stubbed, not faked:** the sitemap also calls for things that need
infrastructure this project doesn't have — a real backend (Google sign-in, password
change, account deactivation are shown visibly disabled with a "Soon" badge, not wired to
fake success), and a real AI chatbot (needs an LLM API key and provider choice nobody's
made; `ChatbotView` ships a keyword-matched local responder instead, and says up front
that it isn't real AI). Screenshot-triggered social sharing from the reference's UI Flows
was not built in this pass.

**Not yet built:** literal auth/signup/OTP screens (no backend to authenticate against),
and Task Decay / Frog lockout / Time-Blindness Timeline from the original spec (the
To-do List here is the reference's simpler search+sticky-note+CRUD version).

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
6. Build and run on a physical device (an iPhone 13 or similar — see "iPhone 13" below)
   — the timer ring drag, the leaning forfeit check, the splash/alarm/haptics, and the
   ambient audio all require real accelerometer/gyro/speaker hardware and won't behave
   correctly in the Simulator.

## iPhone 13

Every screen is built with fluid layout (`GeometryReader`, `ScrollView`, `Spacer`, system
fonts sized in points) rather than hardcoded frames, so it isn't pinned to one device —
but it has specifically been reasoned through against the iPhone 13's 390×844pt portrait
size (curved corners, no Dynamic Island, home-indicator safe area) for the tab bar's
bottom inset, the timer card's proportions, and the to-do grid's two-column layout at
that width. Landscape sizing for the deep-focus session reuses the same math that was
checked against the iPhone 13's 844×390pt landscape size in an earlier pass.

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
  Primary buttons are orange-filled with cream text; secondary/disabled are peach. Task
  cards are rotated sticky notes in cycling pastel tones.
- **Pom** (`Focus/PomMascotView.swift`): idle, running, sleeping, and celebrating poses —
  see Setup #5 for how to swap the placeholder for real artwork.

## Architecture

### App shell
- `App/SprintApp.swift`, `App/RootView.swift` — entry point; splash on every launch, then
  onboarding (first run) or `MainTabView`.
- `App/MainTabView.swift` — the floating pill tab bar (Home, To-do, Reports, Settings)
  from the sitemap, owning the shared `SoundscapePlayer` via `.environmentObject`.
- `App/HomeTabView.swift` — the Home/Focus tab: session setup (subject, duration via the
  timer card, Pomodoro/FocusFlight toggle, chatbot entry point) lives here in portrait,
  reachable from the tab bar — no longer gated behind physically rotating the device.
  Calling `engine.start()` presents `FocusSessionView` as a full-screen cover.
- `App/SplashView.swift`, `App/OnboardingView.swift` — launch reveal; first-run
  name → age → subjects → bedtime flow, with subjects saved as real `Subject` records.

### Focus Engine
- `Focus/FocusEngine.swift` — the session state machine for both modes:
  `configuring → armed (Pomodoro only, 5s leaning grace) → running → forfeited` or
  `→ audit → cooldown`. FocusFlight skips the armed phase and fails via `scenePhase`
  leaving `.active` instead (no FamilyControls/Screen Time entitlement required). Every
  attempt is written to SwiftData the moment it starts.
- `Focus/FocusSessionView.swift` — the full-screen deep-focus cover presented once a
  session starts: armed/running/forfeited/audit/cooldown only (setup itself lives on the
  Home tab now). Background flips cream → charcoal for armed/running per the spec's "Dark
  Mode Focus State," with Pom and secondary chrome hidden there.
- `Focus/PomTimerRing.swift`, `Focus/PomodoroCardView.swift` — the full circular ring
  (starts at 12 o'clock, fills clockwise, generic over flat color or gradient) and the
  dark rounded timer card built on top of it, matching the reference image exactly: Pom
  perched on the arc, reset/edit icon buttons instead of text buttons.
- `Focus/MotionManager.swift` — CoreMotion wrapper publishing `isLeaning`.
- `Focus/Destination.swift`, `Focus/FlightCalculator.swift`, `Focus/FlightMapView.swift` —
  FocusFlight: 10 real short-haul European cities, a real great-circle
  distance/duration calculation (capped at 120 minutes), and a live MapKit route with the
  plane animating continuously via `withAnimation` between engine ticks.
- `Focus/SoundscapePlayer.swift` — Off/Rain/Coffee Shop/Chill Beats, all synthesized
  on-device via `AVAudioEngine` (no bundled recordings needed). Fixed a real bug in this
  pass: the audio source node was missing an explicit `format:`, causing a mismatch
  against the rest of the connection graph that could silently produce no sound.
- `Focus/AlarmPlayer.swift` — a synthesized 4-beep completion alarm.
- `Focus/BreakActivity.swift` — cooldown's rotating micro-activity suggestions.
- `Focus/HapticsManager.swift` — every haptic pattern the engine fires.

### Other tabs
- `Todo/TodoListView.swift`, `Todo/TaskCardView.swift`, `Todo/AddTaskView.swift` — the
  To-do List tab: search, a floating add button, tasks as rotated sticky-note cards
  (tap to edit, checkbox to complete), backed by the existing `StudyTask` SwiftData model.
- `Reports/ReportsView.swift` — total time focused, a per-subject bar breakdown, success
  rate, and recent sessions, from a live `@Query` over `FocusSession`.
- `Settings/SettingsView.swift` — Profile (name/age/bedtime, real), Default Sound (real —
  sets `SoundscapePlayer`'s starting state via `MainTabView`), Account rows that need a
  backend (visibly disabled, "Soon"), About/Privacy static info sheets, and a Reset
  Onboarding action in place of Logout (there's no session to log out of without a
  backend).
- `Chatbot/ChatbotView.swift` — chat UI wired to a local keyword-matched responder, not
  a real AI — see Status above.

### Models
- `Models/Subject.swift`, `Models/StudyTask.swift`, `Models/FocusSession.swift` —
  SwiftData models. `StudyTask` (not `Task`) to avoid colliding with Swift's concurrency
  type.

## Known gaps / things to verify on-device

- No font or mascot image assets ship in this repo (see Setup #4–5) — both degrade
  gracefully (system font; a shape-built placeholder) rather than breaking, but neither
  matches the reference until you add the real files.
- All audio (soundscapes + alarm) is synthesized and reasoned-through, but literally
  unheard in this environment (no macOS/Xcode toolchain or speaker here) — confirm the
  character and levels on a real device.
- The leaning-detection thresholds in `MotionManager` and the `airplane` SF Symbol's
  rotation offset in `FlightMapView` are similarly reasoned but unverified on hardware.
- The flight route is a straight linear interpolation between two coordinates, not a
  geodesic — reads fine as a stylized short-haul tracker, isn't literal navigation.
- Nothing in this codebase has been compiled — there's no macOS/Xcode toolchain in this
  environment. Everything was written and re-read carefully for correctness (one real bug
  already caught and fixed this way: a `View` protocol conflict from a stray `let body:
  String` property), but building it in Xcode before relying on it is still essential.
