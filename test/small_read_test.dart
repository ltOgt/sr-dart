import 'package:small_read/small_read.dart';
import 'package:test/test.dart';

void main() {
  group('Encode / Decode', () {
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
      final mapStr = {
        "f1": "v1",
        "f2": "v2",
        "o1": {
          "f3": "3",
          "o2": {
            "f4": "4",
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
      expect(SmallReadConverter.encode(map), equals(sr));
      expect(SmallReadConverter.decode(sr), equals(mapStr));
    });

    test('Nested List', () {
      final map = {
        "f1": "v1",
        "f2": "v2",
        "l1": [
          3,
          {
            "f4": 4,
          },
        ],
      };
      final mapStr = {
        "f1": "v1",
        "f2": "v2",
        "l1": [
          "3",
          {
            "f4": "4",
          },
        ],
      };
      final sr = [
        "f1:v1",
        "f2:v2",
        "l1:::3",
        ".:3",
        ".::1",
        "..f4:4",
        "",
      ].join("\n");
      expect(SmallReadConverter.encode(map), equals(sr));
      expect(SmallReadConverter.decode(sr), equals(mapStr));
    });

    test("Complex Example", () {
      // Taken from https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/JSON

      final map = {
        "squadName": "Super hero squad",
        "homeTown": "Metro City",
        "formed": 2016,
        "secretBase": "Super tower",
        "active": true,
        "members": [
          {
            "name": "Molecule Man",
            "age": 29,
            "secretIdentity": "Dan Jukes",
            "powers": ["Radiation resistance", "Turning tiny", "Radiation blast"]
          },
          {
            "name": "Madame Uppercut",
            "age": 39,
            "secretIdentity": "Jane Wilson",
            "powers": ["Million tonne punch", "Damage resistance", "Superhuman reflexes"]
          },
          {
            "name": "Eternal Flame",
            "age": 1000000,
            "secretIdentity": "Unknown",
            "powers": ["Immortality", "Heat Immunity", "Inferno", "Teleportation", "Interdimensional travel"]
          }
        ]
      };
      final mapStr = {
        "squadName": "Super hero squad",
        "homeTown": "Metro City",
        "formed": "2016",
        "secretBase": "Super tower",
        "active": "true",
        "members": [
          {
            "name": "Molecule Man",
            "age": "29",
            "secretIdentity": "Dan Jukes",
            "powers": ["Radiation resistance", "Turning tiny", "Radiation blast"]
          },
          {
            "name": "Madame Uppercut",
            "age": "39",
            "secretIdentity": "Jane Wilson",
            "powers": ["Million tonne punch", "Damage resistance", "Superhuman reflexes"]
          },
          {
            "name": "Eternal Flame",
            "age": "1000000",
            "secretIdentity": "Unknown",
            "powers": ["Immortality", "Heat Immunity", "Inferno", "Teleportation", "Interdimensional travel"]
          }
        ]
      };
      final sr = [
        "squadName:Super hero squad",
        "homeTown:Metro City",
        "formed:2016",
        "secretBase:Super tower",
        "active:true",
        "members:::26",
        ".::7",
        "..name:Molecule Man",
        "..age:29",
        "..secretIdentity:Dan Jukes",
        "..powers:::3",
        "...:Radiation resistance",
        "...:Turning tiny",
        "...:Radiation blast",
        ".::7",
        "..name:Madame Uppercut",
        "..age:39",
        "..secretIdentity:Jane Wilson",
        "..powers:::3",
        "...:Million tonne punch",
        "...:Damage resistance",
        "...:Superhuman reflexes",
        ".::9",
        "..name:Eternal Flame",
        "..age:1000000",
        "..secretIdentity:Unknown",
        "..powers:::5",
        "...:Immortality",
        "...:Heat Immunity",
        "...:Inferno",
        "...:Teleportation",
        "...:Interdimensional travel",
        "",
      ].join('\n');
      expect(SmallReadConverter.encode(map), equals(sr));
      expect(SmallReadConverter.decode(sr), equals(mapStr));
    });
  });
}
