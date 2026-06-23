import 'postgres_config.secrets.dart';

class PostgresConfig {
  static const String host = 'ep-bitter-fire-a81vc85m.eastus2.azure.neon.tech';
  static const String database = 'neondb';
  static const String username = 'neondb_owner';
  static const int port = 5432;
  static const bool ssl = true;

  static String get password {
    const fromEnv = String.fromEnvironment('POSTGRES_PASSWORD');
    if (fromEnv.isNotEmpty) return fromEnv;
    return PostgresSecrets.password;
  }
}
