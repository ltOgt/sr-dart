/// Encode and Decode between SmallRead `.SR` Files and Dart maps.
library small_read;

class SmallReadConverter {
  static String encode(Map<String, Object> map) {
    final result = StringBuffer();
    for (String key in map.keys) {
      final childBuffer = StringBuffer();
      _encodeChildren(key, map[key]!, childBuffer, 0);
      result.write(childBuffer.toString());
    }
    return result.toString();
  }

  /// Recursively writes to buffer and returns number of generated lines
  static int _encodeChildren(
    String key,
    Object value,
    StringBuffer buffer,
    int depth,
  ) {
    if (value is String || value is num) {
      // Leaf
      buffer.writeln("${'.' * depth}$key:$value");
      return 1;
    }
    if (value is List) {
      if (depth == 0) throw "Cant have list in top level";
      throw "Lists not yet implemented";
    }
    if (value is Map) {
      final _childBuffer = StringBuffer();
      int _lines = 0;
      for (String key in value.keys) {
        _lines += _encodeChildren(
          key,
          value[key]!,
          _childBuffer,
          depth + 1,
        );
      }

      buffer.writeln("${'.' * depth}$key::$_lines");
      buffer.write(_childBuffer.toString());
      return 1 + _lines;
    }
    throw "Unexpected State";
  }

  static Map decode(String sr) => _decodeChild(sr.split('\n'), 0);

  // TODO currently simply assumes well formed file for optimization
  // TODO currently cant handle lists
  // TODO currently does not warn on duplicate keys, simply overrireds
  static Map _decodeChild(List<String> lineScope, int depth) {
    final ret = {};
    int l = 0;
    while (l < lineScope.length) {
      // remove leading dots
      final line = lineScope[l].substring(depth).trim();
      if (line.isEmpty) {
        l += 1;
        continue;
      }

      final components = line.split(':');
      if (components.length == 2) {
        // "n:v" => [n,v] ; Field
        ret[components.first] = components.last;
        l += 1;
      } else if (components.length == 3) {
        // "o::s" => [o,,s] ; Object Head
        final skip = int.parse(components.last);
        ret[components.first] = _decodeChild(
          lineScope.sublist(l + 1, l + 1 + skip),
          depth + 1,
        );
        l += 1 + skip;
      } else {
        throw "Unexpected State";
      }
    }
    return ret;
  }

  /// returns {"field": "value"} for single field access
  /// Paths can not go into lists
  static Map decodeWithRootPath(String sr, List<String> path) {
    throw UnimplementedError();
  }
}
