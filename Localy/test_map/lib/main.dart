import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // flutter_naver_map 패키지 임포트
// import 'dart:developer'; // log 함수 사용 시 필요 (현재는 debugPrint 사용)

void main() async {
  // Flutter 엔진 및 위젯 바인딩 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("네이버 지도 SDK 초기화를 시도합니다 (flutter_naver_map v1.2.1 기준)...");

  // 네이버 지도 SDK 초기화 (flutter_naver_map v1.1.0 이상 방식)
  // !!! 중요: 현재 사용 중인 버전이 1.2.1이므로 이 방식이 올바릅니다. !!!
  // 만약 "The method 'ensureInitialized' isn't defined..." 오류가 계속 발생한다면,
  // 다음 단계를 반드시 수행하세요:
  // 1. `pubspec.yaml` 파일에서 `flutter_naver_map: ^1.2.1` (또는 사용 중인 정확한 버전) 확인.
  // 2. 터미널에서 `flutter clean` 실행.
  // 3. 터미널에서 `flutter pub get` 실행 (오류/경고 메시지 없는지 확인).
  // 4. 사용 중인 IDE(VS Code, Android Studio 등)를 완전히 종료 후 프로젝트 다시 열기.
  // 5. 프로젝트 루트의 `.dart_tool` 폴더를 삭제한 후 위 3, 4번 단계 다시 시도.
  try {
    await FlutterNaverMap.ensureInitialized(
      clientId: 'strj5pmclm', // NCP 콘솔의 Client ID와 일치해야 함 (사용자님 ID)
      onAuthFailed: (error) {
        debugPrint("********* [테스트 앱 v1.2.1] 네이버맵 인증오류 : $error *********");
      },
    );
    debugPrint("네이버 지도 SDK 초기화 호출 완료 (v1.2.1 방식).");
  } catch (e) {
    debugPrint("네이버 지도 SDK 초기화 중 예외 발생 (v1.2.1 방식): $e");
    if (e.toString().contains("MissingPluginException")) {
      debugPrint(">>> MissingPluginException 발생! 네이티브 설정(AndroidManifest.xml 등) 또는 플러그인 등록에 문제가 있을 수 있습니다.");
    }
  }

  runApp(const MyApp()); // 지도 UI 포함된 앱 실행
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '네이버 지도 테스트 (v1.2.1)',
      theme: ThemeData(
        primarySwatch: Colors.blue, // 테마 색상 변경 (예시)
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('네이버 지도 (v1.2.1)'),
        ),
        body: NaverMap(
          options: const NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(37.5666102, 126.9783881), // 예: 서울 시청
              zoom: 15,
            ),
            mapType: NMapType.basic,
            indoorEnable: true, // 실내 지도 활성화
            locale: Locale('ko'), // 지도 언어 설정
            // v1.2.1에서 사용 가능한 옵션들 (오류 발생 시 버전 호환성 재확인 필요)
            compassEnable: true,
            scaleBarEnable: true,
            zoomControlEnable: true,
            locationButtonEnable: false, // 현위치 버튼 (권한 및 추가 설정 필요)
            logoClickEnable: true,
            logoAlign: NLogoAlign.leftBottom,
            liteModeEnable: false,
            nightModeEnable: false,
            scrollGesturesEnable: true,
            zoomGesturesEnable: true,
            tiltGesturesEnable: true,
            rotateGesturesEnable: true,
            stopGesturesEnable: true,
            useGLSurfaceView: false, // Android에서 GLSurfaceView 사용 여부
            activeLayerGroups: [ // v1.1.0 이상에서 사용 가능
              NLayerGroup.building,
              NLayerGroup.transit,
              // NLayerGroup.bicycle, // 자전거 도로
              // NLayerGroup.traffic, // 실시간 교통 정보 (별도 라이선스 필요할 수 있음)
              // NLayerGroup.terrain, // 지형도
              // NLayerGroup.cadastral, // 지적도
            ],
          ),
          onMapReady: (NaverMapController controller) {
            debugPrint('[테스트 앱 v1.2.1] 네이버맵 로딩 완료! 컨트롤러: $controller');
          },
          onMapTapped: (NPoint point, NLatLng latLng) {
            debugPrint('[테스트 앱 v1.2.1] 지도 터치됨: 화면좌표=$point, 위경도=$latLng');
          },
          onSymbolTapped: (NSymbolInfo symbolInfo) {
            debugPrint('[테스트 앱 v1.2.1] 심벌 터치됨: $symbolInfo');
          },
          onCameraChange: (NCameraUpdateReason reason, bool animated) {
            // debugPrint('[테스트 앱 v1.2.1] 카메라 변경: 이유=$reason, 애니메이션=$animated');
          },
          onCameraIdle: () {
            // debugPrint('[테스트 앱 v1.2.1] 카메라 이동 멈춤');
          },
          onSelectedIndoorChanged: (NSelectedIndoorInfo? selectedIndoor) { // v1.1.0 이상 타입
            debugPrint('[테스트 앱 v1.2.1] 실내 영역 변경: $selectedIndoor');
          },
        ),
      ),
    );
  }
}

// === pubspec.yaml 및 버전 확인 중요 ===
// 1. `pubspec.yaml` 파일에서 `flutter_naver_map`의 버전이 `^1.2.1` (또는 정확히 `1.2.1`)로 명시되어 있는지 확인합니다.
//
// 2. `pubspec.lock` 파일에서 실제로 설치된 `flutter_naver_map` 버전이 `1.2.1`인지 확인합니다.
//
// 3. "The method 'ensureInitialized' isn't defined..." 또는 "Undefined class 'NSelectedIndoorInfo'..." 와 같은 오류가
//    계속 발생한다면, 프로젝트의 캐시 또는 IDE의 분석기 문제일 가능성이 매우 높습니다.
//    다음 단계를 반드시 시도해보세요:
//    a. 터미널에서 `flutter clean` 실행
//    b. 터미널에서 `flutter pub get` 실행 (콘솔에 오류/경고 메시지가 없는지 확인)
//    c. 사용 중인 IDE(VS Code, Android Studio 등)를 완전히 종료 후 프로젝트를 다시 엽니다.
//    d. 프로젝트 루트의 `.dart_tool` 폴더를 삭제한 후 위 a, b, c 단계를 다시 시도합니다.
//
// 4. `import 'package:flutter_naver_map/flutter_naver_map.dart';` 구문이 파일 상단에 올바르게 있는지 확인합니다.
