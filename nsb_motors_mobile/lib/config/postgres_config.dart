import 'dart:io';

/// Optional direct Neon access (legacy queues / WhatsApp processor).
///
/// Control panel auth and admin APIs use [CloudControlService] + Vercel — not this file.
///
/// Configure via environment (same as Vercel + Neon integration):
///   POSTGRES_PRISMA_URL  — preferred
/// or POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD, …
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
  static const bool ssl = true;

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
