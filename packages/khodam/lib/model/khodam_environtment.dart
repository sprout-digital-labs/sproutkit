class KhodamEnvironment {
  /// API URL used by the app
  final String? apiUrl;

  /// Name of the environment (e.g., production, development)
  final String? environmentName;

  /// Version of the current environment (e.g., v1.0.0)
  final String? environmentVersion;

  /// Constructor for the environment settings
  const KhodamEnvironment({
    this.apiUrl,
    this.environmentName,
    this.environmentVersion,
  });
}