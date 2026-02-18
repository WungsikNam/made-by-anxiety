# UI/UX 가이드 – Made by Anxiety : Breathe Right Now

이 문서는 **불안 상태의 사용자**, 특히 **불을 끄고 혼자 있는 밤**이라는 사용 맥락을 전제로 설계된 UI/UX 기준 문서다.

이 앱의 UI는 '보이기 위해' 존재하지 않고,
UX는 '설득하기 위해' 존재하지 않는다.

> 목표는 단 하나다.
> **생각보다 먼저, 숨이 시작되게 하는 것.**

---

## 1. UX 철학 (Experience Principles)

### 1.1 이 앱의 UX는 치료가 아니다

* 사용자를 고치지 않는다
* 상태를 분석하지 않는다
* 나아질 것이라고 약속하지 않는다

이 앱은 **불안한 순간을 통과하기 위한 안전한 통로**다.

---

### 1.2 인지 부하 최소화 원칙

불안 상태의 사용자는 다음을 할 수 없다:

* 읽기
* 판단하기
* 선택하기

따라서 UX는 다음을 제거한다:

* 선택지
* 설명
* 성취 구조

UX는 **행동 하나만 남긴다: 호흡**

---

## 2. 전문가 인용 콘텐츠의 UX 포지션 (중요)

### 결론부터

❌ **명상 시작 직전(Immediate Pre-breath)** 에 전문가 설명을 넣지 않는다.
⭕ **첫 사용 혹은 선택적 진입 지점** 에만 배치한다.

이유:

* 불안 발현 순간에는 '이해'보다 '안전 신호'가 먼저다
* 전문가의 말은 신뢰를 주지만, 즉각성은 떨어진다

---

## 3. 전문가 콘텐츠 UX 적용 전략

### 3.1 사용 목적

전문가 인용은:

* 사용자를 설득하기 위함 ❌
* 기능을 설명하기 위함 ❌

👉 **"이 앱을 믿어도 된다"는 배경 신뢰 형성용**이다.

---

### 3.2 배치 위치 (권장)

#### A. 첫 실행 후, 자동 호흡 1회 종료 뒤

* 강제 아님
* 닫기 버튼 즉시 제공

#### B. Settings / About 섹션

* 평소에 읽을 수 있는 위치
* 불안 순간에는 노출 안 됨

---

## 4. 전문가 콘텐츠 UX 설계 방식

### 절대 규칙

* 실명 노출은 **최소한**
* 논문/권위 강조 ❌
* 짧은 문장 + 해석 최소

---

### 4.1 전문가 카드 UI (Example)

**Card Structure**

* Background: 기존 다크 배경보다 살짝 밝은 톤
* Text: 최대 2줄
* Interaction: Swipe 또는 Close

---

### 4.2 실제 UX 문구 (가공본)

#### Trauma-informed care

> "Breath is the fastest way to tell your nervous system:
> you are safe, right now."

*— trauma therapy principle*

---

#### Mindfulness

> "As long as you're breathing,
> more things are right than wrong."

*— mindfulness-based therapy*

---

#### Neuroscience

> "Breathing is the fastest tool
> to change the brain's level of alertness."

*— neuroscience research*

⚠️ Physiological sigh는 **기능 설명에만 사용**

> "Two short inhales through the nose,
> one long exhale through the mouth."

---

## 5. UI 구성 (MVP 기준)

### 5.1 전체 화면 구조

```
┌────────────────────────┐
│  Made by Anxiety        │  ← 매우 작게, 좌측 상단
│                        │
│        ○               │
│     (Breathing)        │  ← 중심: 호흡 애니메이션
│        ○               │
│                        │
│   "Breathe right now." │  ← 짧은 UX 문구
│                        │
│  🔊   〰️   ✕           │  ← Sound / Haptic / Exit
└────────────────────────┘
```

---

### 5.2 색상 사용 규칙 (요약)

* Background: 거의 검정에 가까운 차콜
* 호흡 요소: 따뜻한 회색
* 텍스트: 주장하지 않는 중간 톤

👉 **색은 행동을 방해하지 않아야 한다**

---

## 6. UX 라이팅 규칙 (재정리)

### 기본 원칙

* 짧게
* 현재형
* 지시형
* 평가 없음

---

## 6-1. Auto Breathing + Haptic (진동 연동)

### 6-1.1 기능 정의

* Auto Breathing은 **시각 애니메이션 + 진동(Haptic)** 이 함께 작동하는 것을 기본값으로 한다.
* 진동은 소리의 대체 수단이 아니라 **신체 감각 기반 리듬 가이드**다.

---

### 6-1.2 작동 방식

* 앱 실행 즉시 호흡 애니메이션과 함께 진동 시작
* 진동 패턴은 호흡 페이즈와 1:1로 매칭

**Inhale**

* 부드러운 연속 진동 (점진적)

**Exhale**

* 더 길고 느린 연속 진동

* Hold 단계는 진동 없음

---

### 6-1.3 강도 및 빈도 규칙

* 진동 강도는 **약함(Light)** 기준
* 반복 타격형 진동 금지
* 각 페이즈당 1회 흐름형 진동만 허용

---

### 6-1.4 사용자 제어 (Breathing Control)

* Breathing Screen 하단에 **Breathing On/Off 아이콘** 제공
* 기본값: ON
* 사용자가 Off 선택 시:

  * 호흡 애니메이션 정지
  * 진동 즉시 중단
  * 화면은 **정적 상태(안정 프레임)** 로 유지

---

### 6-1.5 Off 상태 UX 규칙

* 자동 재시작 ❌
* 경고/확인 팝업 ❌
* "다시 켜세요" 유도 ❌
* 사용자가 직접 다시 On 할 때만 재개

---

### 6-1.6 UX 원칙

* Breathing Off는 **회피가 아니라 선택**으로 취급
* On/Off 전환에 대한 평가 문구 없음
* 상태 변화는 아이콘만으로 표현

---

## 7. Optional Reality Grounding (Visual)

### 7.1 기능 정의

* 본 기능은 **현실 인식(Visual Grounding)** 을 돕기 위한 **선택적 UX 흐름**이다.
* 호흡 세션을 방해하거나 대체하지 않는다.
* 사용자가 원할 때만 실행된다.

---

### 7.2 진입 방식

* Breathing Screen 내 **단일 아이콘 버튼** 제공
* 텍스트 라벨 없음
* 버튼은 항상 동일 위치에 고정

---

### 7.3 실행 타이밍

* 사용자가 버튼을 누른 즉시 시작
* 별도 안내 화면 없음
* 호흡 애니메이션은 **중단되지 않음**

---

### 7.4 UX 흐름 (3-Turn Structure)

**Turn 1**

> Name one thing you can see.

(약 10–15초 유지)

**Turn 2**

> One more thing you can see.

(약 10–15초 유지)

**Turn 3**

> That's enough.
> Stay here.

---

### 7.5 UI 표현 규칙

* 기존 텍스트 위치에 동일한 스타일로 표시
* 한 줄 초과 금지
* 페이드 인/아웃만 사용
* 색상 변화 없음

---

### 7.6 종료 규칙

* Turn 3 종료 후 자동으로 호흡 UX로 복귀
* 완료, 성공, 평가 메시지 없음
* 로그 기록 없음

---

### 7.7 내부 명칭

* Internal Feature Name: **Reality Grounding (Visual, Optional)**
* 사용자에게 기능명 노출 없음

---

## 8. UX 흐름 요약

1. App Open
2. Auto Breathing
3. (Optional) Visual Grounding – 3 Turns
4. Breathing Continues
5. Exit Anytime

---

## 9. UX 선언

> 이 앱은 사용자를 훈련하지 않는다.
> 대신, 사용자가 **지금 여기에 머물 수 있게 한다.**
