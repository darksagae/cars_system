/// Base URL for NSB cloud APIs (access.nsbmotors.com).
class CloudApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'NSB_CLOUD_API_URL',
    defaultValue: 'https://access.nsbmotors.com',
  );
}
