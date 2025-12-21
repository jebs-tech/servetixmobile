class ApiConfig {
  static const String baseUrl =
      bool.fromEnvironment('dart.vm.product')
          ? 'http://localhost:8000'
          : 'http://localhost:8000';
}
