import '../../shared/models/app_session.dart';

abstract class AppContextRepository {
  Future<AppSession?> loadSession();

  /// Explica por qué no hay sesión. Devuelve un código:
  /// `no-user`, `no-user-doc`, `no-business-id`, `no-business-or-employee`,
  /// `no-stores`, `offline-no-cache` o `error`.
  Future<String> diagnoseNoSession();
}
