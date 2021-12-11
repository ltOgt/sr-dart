import 'package:small_read/small_read.dart';
import 'package:test/test.dart';

void main() {
  group('Encode', () {
    test('Nested Map', () {
      final map = {
        "f1": "v1",
        "f2": "v2",
        "o1": {
          "f3": 3,
          "o2": {
            "f4": 4,
          },
        },
      };
      final expected = [
        "f1:v1",
        "f2:v2",
        "o1::3",
        ".f3:3",
        ".o2::1",
        "..f4:4",
        "",
      ].join("\n");
      expect(SmallReadConverter.encode(map), equals(expected));
    });
  });

  group('Decode', () {
    test('Nested Map', () {
      final expected = {
        "f1": "v1",
        "f2": "v2",
        "o1": {
          "f3": '3',
          "o2": {
            "f4": '4',
          },
        },
      };
      final sr = [
        "f1:v1",
        "f2:v2",
        "o1::3",
        ".f3:3",
        ".o2::1",
        "..f4:4",
        "",
      ].join("\n");
      expect(SmallReadConverter.decode(sr), equals(expected));
    });
  });
}
