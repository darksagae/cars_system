import 'package:postgres/postgres.dart';
import 'lib/config/postgres_config.dart';

void main() async {
  final conn = await Connection.open(
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

  try {
    final result = await conn.execute('SELECT * FROM "Brand" LIMIT 1');
    for (final row in result) {
      final map = {};
      for (var i = 0; i < result.schema.columns.length; i++) {
        final col = result.schema.columns[i];
        map[col.columnName] = row[i];
      }
      print('Brand Map: $map');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await conn.close();
  }
}
