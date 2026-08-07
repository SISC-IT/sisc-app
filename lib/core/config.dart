/// API 서버 기본 주소. 빌드/실행 시 --dart-define=API_BASE_URL=... 로 덮어쓸 수 있다.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.sisc.kr',
);
