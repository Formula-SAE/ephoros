import "package:client/types/record.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("Record", () {
    test("can be constructed with valid values", () {
      final now = DateTime.now();
      final record = Record(
        id: 1,
        sensor: "temp",
        module: "mod1",
        section: "A",
        date: now,
      );
      expect(record.id, 1);
      expect(record.sensor, "temp");
      expect(record.module, "mod1");
      expect(record.section, "A");
      expect(record.date, now);
    });

    test("fromJson parses valid JSON", () {
      final dateStr = "2024-06-01T12:34:56.000";
      final json = {
        "id": 42,
        "sensor": "humidity",
        "module": "mod2",
        "section": "B",
        "date": dateStr,
      };
      final record = Record.fromJson(json);
      expect(record.id, 42);
      expect(record.sensor, "humidity");
      expect(record.module, "mod2");
      expect(record.section, "B");
      expect(record.date, DateTime.parse(dateStr));
    });

    test("fromJson parses valid JSON (id as string)", () {
      final dateStr = "2024-06-01T12:34:56.000";
      final json = {
        "id": "42",
        "sensor": "humidity",
        "module": "mod2",
        "section": "B",
        "date": dateStr,
      };
      final record = Record.fromJson(json);
      expect(record.id, 42);
      expect(record.sensor, "humidity");
      expect(record.module, "mod2");
      expect(record.section, "B");
      expect(record.date, DateTime.parse(dateStr));
    });

    test("fromJson throws FormatException for missing fields", () {
      expect(() => Record.fromJson({}), throwsA(isA<FormatException>()));
      expect(
        () => Record.fromJson({
          "id": 1,
          "sensor": "s",
          "module": "m",
          "section": "A",
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Record.fromJson({
          "id": 1,
          "sensor": "s",
          "module": "m",
          "date": "2024-06-01",
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test("fromJson throws FormatException for invalid id", () {
      final json = {
        "id": "not_an_int",
        "sensor": "s",
        "module": "m",
        "section": "A",
        "date": "2024-06-01",
      };
      expect(() => Record.fromJson(json), throwsA(isA<FormatException>()));
    });

    test("fromJson throws FormatException for invalid date", () {
      final json = {
        "id": 1,
        "sensor": "s",
        "module": "m",
        "section": "A",
        "date": "not_a_date",
      };
      expect(() => Record.fromJson(json), throwsA(isA<FormatException>()));
    });

    test("copyWith returns a new Record with updated fields", () {
      final now = DateTime.now();
      final record = Record(
        id: 1,
        sensor: "temp",
        module: "mod1",
        section: "A",
        date: now,
      );
      final newDate = now.add(const Duration(days: 1));
      final updated = record.copyWith(
        id: 2,
        sensor: "humidity",
        module: "mod2",
        section: "B",
        date: newDate,
      );
      expect(updated.id, 2);
      expect(updated.sensor, "humidity");
      expect(updated.module, "mod2");
      expect(updated.section, "B");
      expect(updated.date, newDate);

      final unchanged = record.copyWith();
      expect(unchanged.id, record.id);
      expect(unchanged.sensor, record.sensor);
      expect(unchanged.module, record.module);
      expect(unchanged.section, record.section);
      expect(unchanged.date, record.date);
    });
  });
}
