import 'dart:io';

/// Optional direct Neon access (WhatsApp queue, remote commands, etc.).
///
/// Use the same vars as Vercel + Neon integration — do not hardcode hosts in repo.
/// Preferred: `POSTGRES_PRISMA_URL`
/// Or: `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DATABASE`, `POSTGRES_PORT`
///
/// Local example (after `vercel env pull` in web/NSB_Web):
///   export POSTGRES_PRISMA_URL='...'
///   flutter run -d linux
class PostgresConfig {
  PostgresConfig._();

  static String _read(String key) {
    final os = Platform.environment[key];
    if (os != null && os.trim().isNotEmpty) return os.trim();
    final compiled = String.fromEnvironment(key);
    if (compiled.isNotEmpty) return compiled;
    return '';
  }

  static bool get isConfigured {
    if (_connectionUrl.isNotEmpty) return true;
    return _read('POSTGRES_HOST').isNotEmpty &&
        _read('POSTGRES_USER').isNotEmpty &&
        _read('POSTGRES_PASSWORD').isNotEmpty;
  }

  static String get _connectionUrl {
    final prisma = _read('POSTGRES_PRISMA_URL');
    if (prisma.isNotEmpty) return prisma;
    return _read('DATABASE_URL');
  }

  static late final _Endpoint _resolved = _resolve();

  static String get host => _resolved.host;
  static int get port => _resolved.port;
  static String get database => _resolved.database;
  static String get username => _resolved.username;
  static String get password => _resolved.password;

  static _Endpoint _resolve() {
    final url = _connectionUrl;
    if (url.isNotEmpty) {
      return _Endpoint.fromConnectionUrl(url);
    }

    return _Endpoint(
      host: _read('POSTGRES_HOST'),
      port: int.tryParse(_read('POSTGRES_PORT').isEmpty ? '5432' : _read('POSTGRES_PORT')) ??
          5432,
      database: _read('POSTGRES_DATABASE').isEmpty ? 'neondb' : _read('POSTGRES_DATABASE'),
      username: _read('POSTGRES_USER'),
      password: _read('POSTGRES_PASSWORD'),
    );
  }
}

class _Endpoint {
  const _Endpoint({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  static _Endpoint fromConnectionUrl(String raw) {
    final normalized = raw.replaceFirst(RegExp(r'^postgresql:'), 'postgres:');
    final uri = Uri.parse(normalized);
    final db = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return _Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: db.isEmpty ? 'neondb' : db,
      username: Uri.decodeComponent(uri.userInfo.split(':').first),
      password: uri.userInfo.contains(':')
          ? Uri.decodeComponent(uri.userInfo.split(':').skip(1).join(':'))
          : '',
    );
  }
}
