# Functional Specification – Made by Anxiety : Breathe Right Now (Flutter)

## 0. Scope & Principles (Non‑negotiables)
- **Immediate Action:** app launch → breathing starts within **0.5s**.
- **Present‑Focused:** no “improve/feel better” promises, no future framing.
- **Fail‑Safe:** user can lose rhythm/stop; **flow never breaks**.
- **Non‑Judgmental:** no streaks, scores, progress, or “correct breathing.”
- **Offline‑First:** all core functionality works without network.

**Platforms:** iOS + Android (Flutter single codebase)  
**MVP includes:** Breathing session, minimal guidance copy, sound/haptic/visual cues, frictionless exit, internal-only logging.

---

## 1. User Journeys

### 1.1 Primary Journey (MVP)
1) Open app (cold start or resume)  
2) **Breathing starts automatically** (visual + optional haptic/audio)  
3) User continues as long as desired  
4) User exits anytime (no confirmations)  
5) App returns to breathing on next open

### 1.2 Error/Edge Journeys
- No network → identical UX (no warnings)
- App interrupted (call, lock screen) → on resume: **continue immediately**
- User taps randomly / rapid interactions → no failure states
- Low power mode / silent mode → adapt gracefully (haptics optional, audio respects OS)

---

## 2. Information Architecture / Screens

### 2.1 Screen List (MVP)
1. **BreathingScreen (Home + Session)**
2. **SettingsSheet (optional minimal)** – only if required for accessibility: sound/haptics toggles, text size (otherwise rely on system).

**Explicitly excluded:** onboarding tutorials, account/login, goals, reminders, community, content library.

---

## 3. Core Feature Definitions

## 3.1 Instant Breathing (Auto-start)
**Goal:** On launch, start breathing guide without user decision-making.

**Behavior**
- App launches directly into `BreathingScreen`.
- Within **0.5s**, the session enters `Running` state and starts animation/timer.
- A single primary control exists (optional): `Pause/Resume` (may be hidden); `Exit` is always available but low-friction.

**Acceptance Criteria**
- Cold start → first inhale cue starts ≤ 500ms on target devices.
- No blocking async operations on startup (no remote config, no analytics network calls).
- All assets needed for first cycle are **bundled** and preloaded.

**Implementation Notes (Flutter)**
- Preload assets in `main()` before `runApp()` where feasible:
  - `WidgetsFlutterBinding.ensureInitialized()`
  - `precacheImage(...)` for first-frame visuals
  - `AudioPlayer.setSourceAsset(...)` prewarm (see §6)

---

## 3.2 Breathing Engine (Timed Guidance)
**Goal:** Provide a steady, calming, low-cognitive-load breathing cadence.

### 3.2.1 Default Pattern (MVP)
- Use a simple, consistent cycle. Recommended baseline:
  - Inhale: **4s**
  - Hold: **0–2s** (optional; default 0s if wanting simpler)
  - Exhale: **6s** (longer exhale supports down-regulation)
- Cycle repeats indefinitely until user exits.

> Note: avoid claiming medical outcomes; this is a product behavior choice.

### 3.2.2 Cues
- **Visual:** expanding/contracting orb/ring; minimal text overlays.
- **Audio:** optional soft cue at phase changes (not continuous narration).
- **Haptics:** optional gentle pulse on phase changes.

**Acceptance Criteria**
- Phase timings remain accurate within ±100ms across cycles.
- If app is backgrounded, on resume the engine restarts a fresh cycle immediately (no “resume exactly where left off” needed for MVP; prioritize simplicity and immediacy).

**Flutter Implementation**
- A `BreathingController` (e.g., `ChangeNotifier`/`Cubit`) manages state and phase transitions using a single ticker/timer.
- Use `TickerProviderStateMixin` + `AnimationController` for smooth visuals.
- Prefer `AnimationController.duration` for each phase; chain phases deterministically.

---

## 3.3 Fail‑Safe Flow (No “wrong” state)
**Goal:** The app never tells the user they are doing it incorrectly.

**Behavior**
- No breath detection, no microphone, no sensor validation.
- No “Try again” or “Focus” prompts.
- If user pauses, nothing is lost; resuming simply restarts a cycle.
- If the user taps/interrupts the animation, UI remains stable.

**Acceptance Criteria**
- There is **no** error state displayed during a session.
- Any internal exceptions are caught and do not surface UI alerts.
- If audio fails to play, visual guidance continues uninterrupted.

---

## 3.4 Low‑Intervention UX Writing (Copy System)
**Goal:** Use minimal, directive present-tense copy that accompanies, not motivates.

### 3.4.1 Copy Rules
- One short sentence max per phase.
- No future promises (“you will feel better”).
- No performance framing (“correct breathing”).
- Avoid questions.

### 3.4.2 Copy Library (MVP)
**Inhale**
- “Breathe in.”
- “Just this breath.”

**Exhale**
- “Breathe out.”
- “Long exhale.”

**Grounding**
- “You’re here.”
- “Right now.”

**Fallback (when needed)**
- “It’s okay.” (use sparingly)

**Acceptance Criteria**
- Copy appears at most once per phase; fades out quickly.
- Localization-ready: all copy in one place (`AppStrings`).

---

## 3.5 No Fixed Sessions (Infinite, user-controlled)
**Goal:** No time selection, no “session completed” framing.

**Behavior**
- No 3/5/10 minute options.
- No end screen. On exit, app closes or returns to idle minimal state (but MVP can simply stop).
- User can exit anytime via a single gesture/button.

**Acceptance Criteria**
- No “Congratulations” or completion messaging.
- Exit has no confirmation modal.

---

## 3.6 Offline‑First
**Goal:** All core features work with airplane mode.

**Behavior**
- All assets bundled locally.
- No required API calls.
- Optional analytics must be disabled by default or queued locally (MVP: skip).

**Acceptance Criteria**
- Full breathing functionality available without network.
- No network error banners.

---

## 3.7 Invisible Logging (Internal Only)
**Goal:** Collect minimal telemetry for product improvement without user-facing judgment.

**What to log (MVP)**
- `session_start` timestamp
- `session_end` timestamp
- `duration_seconds`
- `exit_method` (back gesture / close button / app background)
- `audio_enabled`, `haptics_enabled`
- `crash_flag` (if previous session ended unexpectedly)

**Storage**
- Local-only (e.g., `shared_preferences` or `hive`).
- Provide an easy way to purge logs (SettingsSheet optional).

**Acceptance Criteria**
- No UI shows counts or streaks.
- Logging cannot delay first breath start.

---

## 4. UI/UX Spec (BreathingScreen)

### 4.1 Layout
- Center: breathing orb/ring animation
- Top-left (small): brand mark text “Made by Anxiety”
- Bottom: minimal controls (optional)
  - `Sound` toggle
  - `Haptics` toggle
  - `Exit` (icon)

### 4.2 States
- `Running` (default)
- `Paused` (optional; if included, text: “Pause” / “Resume”)
- `MutedAudio` (indicator only; no message)
- `ReducedMotion` (if OS setting detected, reduce animations)

### 4.3 Accessibility
- Respect system text scaling.
- Provide semantic labels for controls.
- Support reduced motion (less animation, still timed cues).

---

## 5. Data Model (Local)

### 5.1 Entities
**SessionLog**
- `id: String`
- `startedAt: DateTime`
- `endedAt: DateTime`
- `durationSec: int`
- `exitMethod: String`
- `audioEnabled: bool`
- `hapticsEnabled: bool`
- `appVersion: String`
- `platform: String`

### 5.2 Storage
- MVP: `shared_preferences` (simple append JSON list) or `hive` (preferred for scale).
- Ensure writes are async and **not on launch path**.

---

## 6. Flutter Architecture & Packages (Recommendations)

### 6.1 State Management
- Simple MVP: `ChangeNotifier` + `Provider`
- Scalable MVP+: `flutter_bloc` (Cubit)

### 6.2 Audio
- `just_audio` (asset audio, preloading support)
- Respect OS silent mode (iOS) decisions; avoid forcing playback.

### 6.3 Haptics
- `flutter/services` → `HapticFeedback` (built-in)
- Keep intensity minimal; allow toggle.

### 6.4 Local Storage
- MVP simple: `shared_preferences`
- Recommended: `hive` (structured logs)

### 6.5 App Lifecycle
- Use `WidgetsBindingObserver` to handle background/resume:
  - On resume: immediately start a new cycle.
  - On pause: stop timers to save battery.

---

## 7. Performance Requirements
- Cold start to first inhale cue: **≤ 0.5s**
- 60fps animation on mid-range devices
- Battery: timers paused when backgrounded; no constant CPU loops

---

## 8. QA / Acceptance Test Checklist (MVP)
- [ ] Launch starts breathing instantly (cold + warm)
- [ ] Airplane mode: identical behavior
- [ ] Interruptions: call/lock → resume starts breathing immediately
- [ ] Audio toggle works; silent mode handled gracefully
- [ ] Haptics toggle works
- [ ] No screens with streaks/stats/completion
- [ ] No error dialogs during session (exceptions handled)
- [ ] Copy is minimal, directive, present-focused

