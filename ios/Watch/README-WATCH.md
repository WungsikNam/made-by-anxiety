# 🍏 Apple Watch (watchOS) 연동 가이드

윈도우(Windows) 환경에서 미리 작성된 네이티브 SwiftUI 워치 앱 코드를, 맥북(Mac)으로 이동한 뒤 실제 컴파일하고 연결하는 방법입니다.

## 🚀 Xcode 설정 5단계

1. **프로젝트 열기**
   - 맥북에서 이 프로젝트 폴더를 열고, 터미널에서 `flutter clean` & `flutter pub get` & `cd ios && pod install` 수행
   - `ios/Runner.xcworkspace` 파일을 **Xcode**로 켭니다 (파란색 아이콘 말고 흰색 워크스페이스 아이콘 실행).

2. **워치 타겟(Target) 생성**
   - Xcode 최상단 메뉴에서 **File** > **New** > **Target...** 클릭
   - 상단 탭에서 **watchOS** 선택 후 **App** 아이콘 클릭 -> Next
   - **Product Name**: `WatchApp` (반드시 동일하게)
   - Interface: `SwiftUI`, Language: `Swift` 설정 후 Finish.

3. **작성된 코드 덮어쓰기 (핵심)**
   - Xcode 왼쪽 프로젝트 네비게이터에 새로 생긴 `WatchApp` 폴더가 보입니다.
   - 키보드로 해당 폴더 안에 있는 기본 생성 파일(`WatchAppApp.swift`, `ContentView.swift`)을 먼저 삭제(Move to Trash)합니다.
   - 그리고 `WatchApp` 폴더를 우클릭 -> **Add Files to "Runner"...** 클릭
   - 제가 미리 만들어둔 `ios/Watch/WatchApp.swift`와 `ios/Watch/ContentView.swift`를 선택해서 추가합니다.

4. **실행 및 햅틱 테스트**
   - Xcode 상단 중앙의 시뮬레이터 선택 창에서 **Apple Watch Series 9 (또는 실기기 연결)**을 선택합니다.
   - ▷ (Run) 버튼을 눌러 빌드합니다.

## ✨ 구현 기능
이 코드에는 앱의 핵심 기능인 **Apple Watch Taptic Engine 전용 햅틱 피드백** 로직이 완벽하게 4-1.5-6 리듬(들숨-멈춤-날숨)에 맞춰 구현되어 있습니다. 단순히 핸드폰 앱을 복사한 것이 아니라 워치에 특화된 네이티브 진동 질감을 줍니다.
