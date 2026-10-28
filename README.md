세종투자연구회 어플 개발 및 관리, 배포

## 앱 식별자

| 플랫폼 | ID |
| --- | --- |
| iOS Bundle ID | `kr.sisc.siscApp` |
| Android applicationId | `kr.sisc.sisc_app` |

## iOS 배포 (Codemagic → App Store Connect / TestFlight)

빌드/배포 설정은 레포 루트의 [`codemagic.yaml`](codemagic.yaml)에 정의되어 있음 (workflow: `ios-appstore`).

- **코드 사이닝**: Codemagic 자동 사이닝 사용. 인증서/프로비저닝 프로파일은 수동 생성 불필요, 빌드 시 `xcode-project use-profiles`가 App Store Connect API 키로 자동 발급/조회.
- **App Store Connect API 키 (Codemagic integration reference name)**: `sumtagi-appstore`
  - Codemagic 대시보드 → Teams → Integrations → App Store Connect 에서 관리
  - 해당 키는 인증서/프로파일 자동 생성을 위해 Admin 또는 App Manager 권한 필요
- **업로드 범위**: 빌드 성공 시 TestFlight까지 자동 업로드 (`submit_to_testflight: true`). 심사(App Store Review) 제출은 App Store Connect에서 수동으로 진행.
- **빌드 실패/성공 알림**: 이메일 (`kimsungil322@gmail.com`)

### 사전에 Apple 쪽에서 준비해 둔 것

1. **App ID 등록** — Apple Developer Portal → Certificates, Identifiers & Profiles → Identifiers에 `kr.sisc.siscApp` 등록
2. **App Store Connect 앱 레코드 생성** — My Apps에 Bundle ID `kr.sisc.siscApp`, SKU `kr.sisc.siscApp`로 앱 생성 완료

### 빌드 트리거

Codemagic → Applications → 이 레포 선택 → `ios-appstore` workflow → Start new build

### 참고사항

- `ios/` 폴더에 `Podfile`이 아직 커밋되어 있지 않음 (윈도우 환경에서 개발해 `pod install`을 로컬에서 돌린 적 없음). Codemagic macOS 빌드 머신에서 Flutter 툴체인이 자동 생성할 것으로 예상되나, CocoaPods 관련 에러가 나면 `Podfile`을 직접 생성해 커밋해야 할 수 있음.
- 버전/빌드 번호는 `pubspec.yaml`의 `version` 필드(`<version>+<build>`)로 관리됨. TestFlight는 동일 빌드 번호 재업로드를 거부하므로, 재배포 전 빌드 번호를 올려야 함.
