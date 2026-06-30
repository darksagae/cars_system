import 'dart:async';
import 'package:postgres/postgres.dart';
import '../config/postgres_config.dart';

/// Direct connection manager for Neon PostgreSQL in Sales System
class PostgresService {
  static Future<void> initialize() async {
    print('🔌 PostgresService initialized (direct connection to Neon)');
  }

  static Future<Connection> _connect() async {
    if (!PostgresConfig.isConfigured) {
      throw StateError(
        'Postgres is not configured. Set POSTGRES_PRISMA_URL (Vercel Neon) or '
        'POSTGRES_HOST / POSTGRES_USER / POSTGRES_PASSWORD.',
      );
    }
    return await Connection.open(
      Endpoint(
        host: PostgresConfig.host,
        database: PostgresConfig.database,
        username: PostgresConfig.username,
        password: PostgresConfig.password,
        port: PostgresConfig.port,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );
  }

  /// Execute a parameterized query and return matching rows
  static Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? parameters}) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(Sql.named(query), parameters: parameters);
      final List<Map<String, dynamic>> list = [];
      for (final row in result) {
        final Map<String, dynamic> map = {};
        for (var i = 0; i < result.schema.columns.length; i++) {
          final col = result.schema.columns[i];
          var val = row[i];
          if (val is Map) {
            val = Map<String, dynamic>.from(val);
          }
          map[col.columnName ?? 'column_$i'] = val;
        }
        list.add(map);
      }
      return list;
    } finally {
      await conn.close();
    }
  }

  /// Execute a parameterized statement (INSERT/UPDATE/DELETE)
  static Future<void> execute(String query, {Map<String, dynamic>? parameters}) async {
    final conn = await _connect();
    try {
      await conn.execute(Sql.named(query), parameters: parameters);
    } finally {
      await conn.close();
    }
  }
}
