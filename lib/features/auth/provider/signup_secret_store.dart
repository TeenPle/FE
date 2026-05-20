/// 회원가입 중 필요한 민감 입력값을 Riverpod State 밖에 임시 보관한다.
///
/// 비밀번호는 최종 가입 요청 전까지만 메모리에 유지하고, 가입 완료/초기화 시 즉시 지운다.
/// 화면 상태나 DevTools Provider Inspector에 평문 비밀번호가 노출되지 않도록 별도 저장소로 분리했다.
class SignupSecretStore {
  SignupSecretStore._();

  static String _password = '';
  static String _passwordConfirm = '';

  static String get password => _password;
  static String get passwordConfirm => _passwordConfirm;
  static bool get hasPassword =>
      _password.trim().isNotEmpty && _password == _passwordConfirm;

  static void savePassword({
    required String password,
    required String passwordConfirm,
  }) {
    _password = password;
    _passwordConfirm = passwordConfirm;
  }

  static void clear() {
    _password = '';
    _passwordConfirm = '';
  }
}
