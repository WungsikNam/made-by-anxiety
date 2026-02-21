# 🍏 Apple HIG Visual Director Audit & Directives
**To:** Claude Code (Engineering Lead)
**From:** Anti-Gravity (Visual Director, iOS/watchOS HIG Specialist)
**Reference:** `ui-ux-pro-max-skill` & Apple Human Interface Guidelines (2024)

## 🚨 1. iOS UI/UX Violations & Correction Orders 

### 🛑 Touch Target Size Violation (Critical)
* **Location**: `breathing_screen.dart` > `_buildControl` (Bottom Control Bar)
* **Status**: `Icon(size: 22)` with `padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)`. The effective touch width is ~30pt.
* **HIG Rule**: Apple HIG stringently dictates a minimum touch target of **44x44pt** for all interactive elements to ensure reliable hit-testing and maintain the Thumb Zone ergonomics.
* **Directive**: Increase `horizontal` padding or explicitly wrap the `GestureDetector` child in a `SizedBox(width: 44, height: 44)` minimum. Use `HitTestBehavior.opaque` to ensure the extended padding registers the tap.

### 🛑 Safe Area & Dynamic Island Margin (Warning)
* **Location**: `breathing_screen.dart` > `Positioned(top: 20, left: 20)` ("Made by Anxiety" text).
* **Status**: Currently inside a `SafeArea`, but the hardcoded top/left padding of 20pt can visually crowd the Dynamic Island or the hardware's rounded corners on iPhone 14/15 Pro models. 
* **HIG Rule**: Respect the `Safe Area` organically. Avoid anchoring UI elements too closely to hardware sensors.
* **Directive**: Change `Positioned(top: 20)` to dynamic visual padding or use `SliverSafeArea` / `LayoutBuilder` to proportionally space branding text away from the notch/island.

---

## 🚨 2. watchOS UI/UX Violations & Correction Orders

### 🛑 Container-Driven Layout Absence (Critical)
* **Location**: Entire Application (Currently relying on absolute Flutter widget sizing).
* **Status**: 56pt Fonts and 60pt Paddings will catastrophically overflow on a 41mm/45mm Apple Watch display.
* **HIG Rule**: watchOS UI must be strictly **container-based** (SwiftUI Groups/VStack) flowing vertically. Text must be highly legible at a glance (Minimum **11pt** Dynamic Type).
* **Directive**: 
  1. DO NOT attempt to shoehorn the existing Flutter UI directly into watchOS.
  2. Create a separate `WatchApp` native target using SwiftUI via Xcode.
  3. Ensure breathing instructions use `.font(.system(size: 16, weight: .medium, design: .rounded))` for maximum readability on small displays.

### 🛑 Digital Crown & Haptic Feedback (Critical)
* **Location**: `_hapticForPhase()` inside Dart.
* **Status**: `HapticFeedback.lightImpact()` uses iOS CoreHaptics. This **will silently fail** or feel cheap on an Apple Watch Taptic Engine.
* **HIG Rule**: watchOS requires semantic haptics to guide the user without looking.
* **Directive**: In the new SwiftUI target, trigger `WKInterfaceDevice.current().play(.click)` (or `.directionUp`/`.directionDown`) synchronously with the breathing curve to simulate physical inhalation.

---

## 📊 3. TestFlight Performance & Battery Efficiency Prediction

Based on the current architecture (`FluidBreathShape` CustomPainter + Wakelock + Infinite Animation Controllers), here is the prediction for 실기기 (Physical iOS/watchOS Device) testing:

| Metric | Prediction | iOS Impact | watchOS Impact |
| :--- | :--- | :--- | :--- |
| **ProMotion (120Hz) Rendering** | ⚠️ Moderate | On iOS Impeller, the `CustomPainter` will hit 120fps smoothly. *However*, repainting every frame for 10+ minutes sequentially will cause thermal throttling. | **Severe**. watchOS cannot sustain continuous custom repaints without heavily draining the microscopic battery. Use native SwiftUI `withAnimation` instead of frame-by-frame painters.
| **Battery Drain (Wakelock)** | 🛑 High | Keeping the screen awake (`WakelockPlus.enable()`) during an extended grounding session will drain ~3-5% battery per session on an iPhone Pro. | **Critical**. Apple Watch will aggressively force-sleep the screen after 70 seconds regardless of UI wakelocks, unless running an active `HKWorkoutSession` (HealthKit).
| **Memory Footprint** | ✅ Excellent | No heavy assets, purely math-based vectors. <50MB RAM overhead. | Outstanding. Perfectly suited for watchOS memory constraints.

### 🛠️ Final Architect Directive for Engineeer (Claude)
**"Implement the iOS minimum target size (44pt) fixes immediately inside the Flutter codebase. Afterward, halt all Dart modifications for the Watch implementation and initialize `xcodebuild` integration for a pure Native SwiftUI watchOS companion app."**
