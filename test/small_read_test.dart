import 'package:small_read/small_read.dart';
import 'package:test/test.dart';

void main() {
  group('Encode / Decode', () {
    test('Nested Map', () {
      final map = {
        "f1": "v1",
        "f2": "v2",
        "f3": "",
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
        "f3": "",
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
        "f3:",
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

    test("Mozilla Example", () {
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

    test("Complex Example", () {
      // Taken from https://json-generator.com/
      final map = {
        "_id": "61b620a81f422d2f26929493",
        "index": 0,
        "guid": "519a7357-be54-48a3-83cd-d4b26acdc302",
        "isActive": false,
        "balance": "€2,060.16",
        "picture": "http://placehold.it/32x32",
        "age": 22,
        "eyeColor": "green",
        "name": "Tabitha Arnold",
        "gender": "female",
        "company": "DAYCORE",
        "email": "tabithaarnold@daycore.com",
        "phone": "+1 (958) 561-3130",
        "address": "923 Harbor Court, Roderfield, Vermont, 8520",
        "about":
            "Lorem aliqua non ea mollit ad. Incididunt dolor exercitation deserunt eiusmod occaecat id culpa et in dolore ullamco et magna adipisicing. Veniam est ipsum ut officia exercitation id Lorem. Ex mollit deserunt sunt anim voluptate exercitation.",
        "registered": "2016-10-06T10:34:43 -02:00",
        "latitude": 11.873447,
        "longitude": -13.68962,
        "tags": ["est", "minim", "cillum", "veniam", "nulla", "ea", "id"],
        "friends": [
          {"id": 0, "name": "Rosalinda Faulkner"},
          {"id": 1, "name": "Lynn Drake"},
          {"id": 2, "name": "Chambers Collins"}
        ],
        "greeting": "Hello, Tabitha Arnold! You have 7 unread messages.",
        "favoriteFruit": "strawberry"
      };
      final mapStr = {
        "_id": "61b620a81f422d2f26929493",
        "index": "0",
        "guid": "519a7357-be54-48a3-83cd-d4b26acdc302",
        "isActive": "false",
        "balance": "€2,060.16",
        "picture": "http://placehold.it/32x32",
        "age": "22",
        "eyeColor": "green",
        "name": "Tabitha Arnold",
        "gender": "female",
        "company": "DAYCORE",
        "email": "tabithaarnold@daycore.com",
        "phone": "+1 (958) 561-3130",
        "address": "923 Harbor Court, Roderfield, Vermont, 8520",
        "about":
            "Lorem aliqua non ea mollit ad. Incididunt dolor exercitation deserunt eiusmod occaecat id culpa et in dolore ullamco et magna adipisicing. Veniam est ipsum ut officia exercitation id Lorem. Ex mollit deserunt sunt anim voluptate exercitation.",
        "registered": "2016-10-06T10:34:43 -02:00",
        "latitude": "11.873447",
        "longitude": "-13.68962",
        "tags": ["est", "minim", "cillum", "veniam", "nulla", "ea", "id"],
        "friends": [
          {"id": "0", "name": "Rosalinda Faulkner"},
          {"id": "1", "name": "Lynn Drake"},
          {"id": "2", "name": "Chambers Collins"}
        ],
        "greeting": "Hello, Tabitha Arnold! You have 7 unread messages.",
        "favoriteFruit": "strawberry"
      };
      final sr = [
        "_id:61b620a81f422d2f26929493",
        "index:0",
        "guid:519a7357-be54-48a3-83cd-d4b26acdc302",
        "isActive:false",
        "balance:€2,060.16",
        "picture:http://placehold.it/32x32",
        "age:22",
        "eyeColor:green",
        "name:Tabitha Arnold",
        "gender:female",
        "company:DAYCORE",
        "email:tabithaarnold@daycore.com",
        "phone:+1 (958) 561-3130",
        "address:923 Harbor Court, Roderfield, Vermont, 8520",
        "about:Lorem aliqua non ea mollit ad. Incididunt dolor exercitation deserunt eiusmod occaecat id culpa et in dolore ullamco et magna adipisicing. Veniam est ipsum ut officia exercitation id Lorem. Ex mollit deserunt sunt anim voluptate exercitation.",
        "registered:2016-10-06T10:34:43 -02:00",
        "latitude:11.873447",
        "longitude:-13.68962",
        "tags:::7",
        ".:est",
        ".:minim",
        ".:cillum",
        ".:veniam",
        ".:nulla",
        ".:ea",
        ".:id",
        "friends:::9",
        ".::2",
        "..id:0",
        "..name:Rosalinda Faulkner",
        ".::2",
        "..id:1",
        "..name:Lynn Drake",
        ".::2",
        "..id:2",
        "..name:Chambers Collins",
        "greeting:Hello, Tabitha Arnold! You have 7 unread messages.",
        "favoriteFruit:strawberry",
        "",
      ].join('\n');
      expect(SmallReadConverter.encode(map), equals(sr));
      expect(SmallReadConverter.decode(sr), equals(mapStr));
    });

    test('Set', () {
      final map = {
        "f1": "v1",
        "f2": "v2",
        // ignore: equal_elements_in_set
        "set": {1, 2, 3, 3},
      };
      final mapStr = {
        "f1": "v1",
        "f2": "v2",
        "set": {"1", "2", "3"},
      };
      final sr = [
        "f1:v1",
        "f2:v2",
        "set::::3",
        ".:1",
        ".:2",
        ".:3",
        "",
      ].join("\n");
      expect(SmallReadConverter.encode(map), equals(sr));
      expect(SmallReadConverter.decode(sr), equals(mapStr));
    });
  });
}
