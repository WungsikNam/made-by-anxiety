# Design System: Tactical Anxiety Anchor

## Pattern
- **Name:** Bioluminescent Fluid SOS Tool
- **Conversion Focus:** Immediate Action but Guided.
- **Color Strategy:** Dynamic shift from anxious to calm.
- **Sections:** 1. Home Screen -> 2. Breath Onboarding -> 3. Base Breath (4x) -> 4. Tactical Breath (4x) -> 5. Reality Grounding (Cognitive Training).

## Style
- **Name:** Zero-Friction Eclipse
- **Keywords:** OLED pitch black, pure white, subtle glow, perfect ring, clinical, minimalist
- **Best For:** Panic attacks, extreme anxiety, rapid grounding
- **Performance:** ⚡ Excellent | **Accessibility:** ✓ High-contrast, Haptic-first

## Colors (Eclipse Transition)
| State | Role | Hex | Notes |
|-------|------|-----|-------|
| 🔴 Anxious (Start) | Background | `#000000` | True OLED Black |
| 🔴 Anxious (Start) | Eclipse Ring | `#4A4A4A` | Dim, tight, heavy grey glow |
| 🟢 Calm (Target) | Background | `#050505` | Almost black |
| 🟢 Calm (Target) | Eclipse Ring | `#FFFFFF` | Bright, pure white, expanded soft glow |
| ⚪ Universal | Text/Icons | `rgba(255,255,255,0.7)` | Minimalist, never blinding |

*Notes: Background and eclipse ring colors smoothly interpolate from Anxious (Dim/Tight) to Calm (Bright/Expanded) over the first few minutes of breathing.*

## Typography
- **Heading:** Lora (Elegant, calming)
- **Body:** Raleway (Minimalist, readable)
- **Mood:** tactical, organic, protective, serious
- **Google Fonts:** Lora & Raleway

## Key Effects & Animations
- **Shape:** Bioluminescent Fluid/Metaball. Not a perfect circle. Tense/bumpy on inhale, smooth/liquid on exhale.
- **Scale:** Breathing scale mapping to physiological sighs.
- **Color Transition:** Slow, imperceptible easing from violet to sage.

## Extreme Haptics (Eyes-Closed Operation)
- **Inhale:** Gentle but accelerating rumble (simulated via multiple light impacts).
- **Top-up (Hold):** Distinct, sharp click (`HapticFeedback.selectionClick()`).
- **Exhale:** Long, fading, soft vibration (simulated via spread-out light impacts).
- **Goal:** User can perfectly track the breath cycle with eyes squeezed shut.

## Avoid (Anti-patterns)
- Rigid geometric shapes (perfect circles/squares)
- Static, unchanging "black" backgrounds
- Complex menus or onboarding flows
- Weak or non-existent haptics
