/// Encode and Decode between SmallRead `.SR` Files and Dart maps.
library small_read;

class SmallReadConverter {
  SmallReadConverter._();

  static String encode(Map<String, Object> map) {
    final result = StringBuffer();
    for (String key in map.keys) {
      final childBuffer = StringBuffer();
      _encodeChildren(
        key: key,
        value: map[key]!,
        buffer: childBuffer,
        depth: 0,
      );
      result.write(childBuffer.toString());
    }
    return result.toString();
  }

  /// Recursively writes to buffer and returns number of generated lines
  static int _encodeChildren({
    required String key,
    required Object value,
    required StringBuffer buffer,
    required int depth,
  }) {
    if (value is String || value is num) {
      // Leaf
      buffer.writeln("${'.' * depth}$key:$value");
      return 1;
    }
    if (value is Map) {
      final _childBuffer = StringBuffer();
      int _lines = 0;
      for (String key in value.keys) {
        _lines += _encodeChildren(
          key: key,
          value: value[key]!,
          buffer: _childBuffer,
          depth: depth + 1,
        );
      }

      buffer.writeln("${'.' * depth}$key::$_lines");
      buffer.write(_childBuffer.toString());
      return 1 + _lines;
    }
    if (value is List) {
      final _childBuffer = StringBuffer();
      int _lines = 0;
      for (final val in value) {
        _lines += _encodeChildren(
          key: "",
          value: val,
          buffer: _childBuffer,
          depth: depth + 1,
        );
      }

      buffer.writeln("${'.' * depth}$key:::$_lines");
      buffer.write(_childBuffer.toString());
      return 1 + _lines;
    }
    throw "Unexpected State";
  }

  static Map decode(String sr) => _decodeChild(
        lineScope: sr.split('\n'),
        depth: 0,
        enableComments: (sr.startsWith("**")),
        groupScope: true,
      ).map!;

  // TODO currently simply assumes well formed file for optimization
  static _MapOrList _decodeChild({
    required List<String> lineScope,
    required int depth,
    required bool enableComments,
    required bool groupScope,
  }) {
    final _MapOrList ret = groupScope //
        ? _MapOrList.map({})
        : _MapOrList.list([]);

    int l = 0;
    while (l < lineScope.length) {
      // remove leading dots (and comments)
      final line = (enableComments) //
          ? lineScope[l].substring(depth).split('**').first
          : lineScope[l].substring(depth);

      // ignore empty/whitespace lines (whitespace is legal part of name/value)
      if (line.trim().isEmpty) {
        l += 1;
        continue;
      }

      final components = line.split(':');
      switch (components.length) {
        case 2:
          // "n:v" => [n,v] ; Value
          ret.add(components.first, components.last);
          l += 1;
          break;
        case 3:
        // "n::s" => [n,,s] ; Object Head
        case 4:
          // "n:::s" => [n,,,s] ; List Head
          final skip = int.parse(components.last);
          ret.add(
            components.first,
            _decodeChild(
              lineScope: lineScope.sublist(l + 1, l + 1 + skip),
              depth: depth + 1,
              enableComments: enableComments,
              groupScope: (components.length == 3),
            ).extract(),
          );
          l += 1 + skip;
          break;
        default:
          throw "Unexpected State";
      }
    }
    return ret;
  }
}

class _MapOrList {
  final List? list;
  final Map? map;

  const _MapOrList.map(this.map) : list = null;
  const _MapOrList.list(this.list) : map = null;

  Object extract() => list ?? map!;

  void add(String name, Object value) => //
      (name.isNotEmpty) //
          ? map![name] = value
          : list!.add(value);
}
