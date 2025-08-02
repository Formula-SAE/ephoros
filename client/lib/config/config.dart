import "dart:convert";
import "dart:io";

abstract interface class FileReader {
  Future<String> readAsString();
}

class FileAdapter implements FileReader {
  const FileAdapter(this._file);

  final File _file;

  @override
  Future<String> readAsString() => _file.readAsString();
}

class Config {
  const Config._(this._sensors);
  final List<SensorConfig> _sensors;

  List<SensorConfig> get sensors => _sensors;

  static Future<Config> fromJSON(FileReader reader) async {
    try {
      final jsonString = await reader.readAsString();
      final json = jsonDecode(jsonString) as List<dynamic>;

      final sensors = json.map((e) {
        final sensorConfig = SensorConfig.fromJSON(e);
        if (!sensorConfig.validate()) {
          throw ConfigurationException("Invalid sensor config: $e");
        }
        return sensorConfig;
      }).toList();

      return Config._(sensors);
    } catch (e) {
      throw ConfigurationException("Invalid JSON: $e");
    }
  }
}

class SensorConfig {
  const SensorConfig({
    required this.name,
    required this.id,
    required this.section,
    required this.module,
    required this.type,
  });

  SensorConfig.fromJSON(Map<String, dynamic> json)
    : name = json["name"],
      id = json["id"],
      section = json["section"],
      module = json["module"],
      type = json["type"];

  final String name;
  final int id;
  final String section;
  final String module;
  final int type;

  bool validate() =>
      name.isNotEmpty &&
      id >= 0 &&
      section.isNotEmpty &&
      module.isNotEmpty &&
      type >= 0;
}

class ConfigurationException implements Exception {
  const ConfigurationException(this.message);

  final String message;
}
