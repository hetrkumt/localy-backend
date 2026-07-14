// 파일 위치: lib/core/config/app_config.dart
// 앱 전체에서 사용될 상수 값들을 정의합니다.

class AppConfig {
  // API 게이트웨이 기본 URL (사용자님 환경에 맞게 수정됨)
  // 네이버 클라우드 플랫폼 '서비스 환경'의 'Web 서비스 URL'에서 /api 이전 부분
  static const String baseUrl = 'http://localy4782.iptime.org:9000/api';

  // 네이버 지도 클라이언트 ID (사용자님 정보로 수정됨)
  // 네이버 클라우드 플랫폼 'Application key'의 'Client ID' 값
  // !!! 중요: 실제 운영 시에는 이 ID를 코드에 직접 하드코딩하는 것보다
  // 환경 변수나 별도의 설정 파일을 통해 관리하는 것이 더 안전합니다. !!!
  static const String naverMapClientId = 'strj5pmclm'; // 이미지에서 확인된 Client ID

  // Android 앱 패키지 이름 (이미지에서 확인된 정보)
  // 이 값은 Flutter 프로젝트의 android/app/build.gradle 파일의 applicationId와 일치해야 하며,
  // 네이버 클라우드 플랫폼의 'Android 앱 패키지 이름'에 등록된 값과도 일치해야 합니다.
  // Dart 코드 내에서 직접 사용될 일은 적을 수 있지만, 참고용으로 관리할 수 있습니다.
  static const String androidPackageName = 'com.example.localy_front_flutter';

// iOS Bundle ID (iOS 앱을 빌드하고 네이버 지도를 사용한다면 필요)
// static const String iosBundleId = 'YOUR_IOS_BUNDLE_ID'; // 필요시 주석 해제 및 값 입력

// 기타 앱 전반에 걸친 설정값들
// 예: API 요청 타임아웃 시간(초)
// static const int defaultTimeoutSeconds = 30;
}
