import "package:client/config/config.dart";
import "package:flutter_test/flutter_test.dart";

class MockFileReader implements FileReader {
  MockFileReader(this._json);

  final String _json;

  @override
  Future<String> readAsString() async => _json;
}

void main() {
  group("SensorConfig", () {
    test("should validate sensor config properties", () {
      final validConfig = const SensorConfig(
        name: "NTC-1",
        id: 1,
        section: "Battery",
        module: "Module 1",
        type: 0,
      );

      expect(validConfig.name, "NTC-1");
      expect(validConfig.id, 1);
      expect(validConfig.section, "Battery");
      expect(validConfig.module, "Module 1");
      expect(validConfig.type, 0);
    });

    test("should create from JSON", () {
      final json = {
        "name": "NTC-1",
        "id": 1,
        "section": "Battery",
        "module": "Module 1",
        "type": 1,
      };

      final config = SensorConfig.fromJSON(json);

      expect(config.name, "NTC-1");
      expect(config.id, 1);
      expect(config.section, "Battery");
      expect(config.module, "Module 1");
      expect(config.type, 1);
    });
  });

  group("Config.fromJSON", () {
    test("should create config with multiple sensors", () async {
      final json = MockFileReader("""
[
  {
    "name": "NTC-1",
    "id": 1,
    "section": "Battery",
    "module": "Module 1",
    "type": 1
  },
  {
    "name": "NTC-2",
    "id": 2,
    "section": "Battery",
    "module": "Module 1",
    "type": 1
  },
  {
    "name": "NTC-3",
    "id": 3,
    "section": "Battery",
    "module": "Module 1",
    "type": 1
  }
]
""");

      final config = await Config.fromJSON(json);

      expect(config.sensors.length, 3);
      expect(config.sensors[0].name, "NTC-1");
      expect(config.sensors[1].name, "NTC-2");
      expect(config.sensors[2].name, "NTC-3");
      expect(config.sensors[0].id, 1);
      expect(config.sensors[1].id, 2);
      expect(config.sensors[2].id, 3);
      expect(config.sensors[0].section, "Battery");
      expect(config.sensors[1].section, "Battery");
      expect(config.sensors[2].section, "Battery");
      expect(config.sensors[0].module, "Module 1");
      expect(config.sensors[1].module, "Module 1");
      expect(config.sensors[2].module, "Module 1");
      expect(config.sensors[0].type, 1);
      expect(config.sensors[1].type, 1);
      expect(config.sensors[2].type, 1);
    });

    test("should handle single sensor", () async {
      final json = MockFileReader("""
[
  {
    "name": "Single Sensor",
    "id": 1,
    "section": "Test Section",
    "module": "Test Module",
    "type": 0
  }
]
""");

      final config = await Config.fromJSON(json);

      expect(config.sensors.length, 1);
      expect(config.sensors[0].name, "Single Sensor");
    });

    test("should handle empty sensor list", () async {
      final json = MockFileReader("[]");

      final config = await Config.fromJSON(json);

      expect(config.sensors.length, 0);
    });

    test("should throw error on malformed JSON", () async {
      final json = MockFileReader("""
[
  {
    "name": "NTC-1",
    "id": 1,
    "section": "Battery",
    "module": "Module 1",
    "type": 1
  },
  {
    "name": "NTC-2"
    "id": 2,
    "section": "Battery",
    "module": "Module 1",
    "type": 1
  }
]
""");

      expect(
        () async => await Config.fromJSON(json),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test("should handle missing required fields", () async {
      final json = MockFileReader("""
[
  {
    "name": "NTC-1",
    "id": 1,
    "section": "Battery",
    "module": "Module 1"
  }
]
""");

      expect(
        () async => await Config.fromJSON(json),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });
}
