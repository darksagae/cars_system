/// Base URL for NSB web portal sync APIs.
class CloudApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'NSB_CLOUD_API_URL',
    defaultValue: 'https://access.nsbmotors.com',
  );
}
