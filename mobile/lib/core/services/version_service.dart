import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static VersionService? _instance;
  static VersionService get instance => _instance ??= VersionService._();

  VersionService._();

  PackageInfo? _packageInfo;

  /// Inicializa el servicio de versiones
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      _packageInfo = null;
    }
  }

  /// Obtiene la versión de la aplicación
  String get version => _packageInfo?.version ?? '2.0.2';

  /// Obtiene el número de build
  String get buildNumber => _packageInfo?.buildNumber ?? '1';

  /// Obtiene el nombre de la aplicación
  String get appName => _packageInfo?.appName ?? 'Tennis Management';

  /// Obtiene el nombre del paquete
  String get packageName =>
      _packageInfo?.packageName ?? 'com.tennis.management';

  /// Obtiene la versión completa (versión + build)
  String get fullVersion => '$version+$buildNumber';

  /// Obtiene la versión para mostrar en UI
  String get displayVersion => 'v$version';

  /// Obtiene información detallada de la versión
  Map<String, String> get versionInfo => {
    'version': version,
    'buildNumber': buildNumber,
    'appName': appName,
    'packageName': packageName,
    'fullVersion': fullVersion,
    'displayVersion': displayVersion,
  };

  /// Verifica si la versión actual es mayor que la especificada
  bool isVersionGreaterThan(String otherVersion) {
    final current = _parseVersion(version);
    final other = _parseVersion(otherVersion);

    for (int i = 0; i < 3; i++) {
      if (current[i] > other[i]) return true;
      if (current[i] < other[i]) return false;
    }
    return false;
  }

  /// Parsea una versión en formato "1.2.3" a lista de enteros
  List<int> _parseVersion(String version) {
    return version.split('.').map((v) => int.tryParse(v) ?? 0).toList();
  }
}
