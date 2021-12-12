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
    if (value is String || value is num || value is bool) {
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

      final List components = _decomposeElement(line);
      final String name = components[0];
      final int colons = components[1];
      final String value = components[2]; // or SIZE for head

      switch (colons) {
        case 1:
          // "n:v"
          ret.add(name, value);
          l += 1;
          break;
        case 2:
        // "n::s"
        case 3:
          // "n:::s"
          final skip = int.parse(value);
          ret.add(
            components.first,
            _decodeChild(
              lineScope: lineScope.sublist(l + 1, l + 1 + skip),
              depth: depth + 1,
              enableComments: enableComments,
              groupScope: (colons == 2),
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

  static const int _colonRune = 58;

  /// Decomposes the element "X:::Y" into ["X",3,"Y"]
  static List _decomposeElement(String element) {
    assert(element.length > 1, "Invalid element, smallest possible element has the form `:x`");

    final int first = element.indexOf(':');
    late final int last;

    assert(first >= 0);
    assert(element.length > first + 1, "Invalid Element; nothing after name: $element");

    // Next char is not another colon
    if (element.codeUnitAt(first + 1) != _colonRune) {
      // name:value
      last = first;
    } else {
      assert(element.length > first + 2, "Invalid Element; nothing after name: $element");

      // Next-Next char is not another colon
      if (element.codeUnitAt(first + 2) != _colonRune) {
        // obj::size
        last = first + 1;
      } else {
        assert(element.length > first + 3, "Invalid Element; nothing after name: $element");

        // list:::size
        last = first + 2;

        assert(element.codeUnitAt(first + 3) != _colonRune, "Invalid Element; four colons: $element");
      }
    }
    return [element.substring(0, first), 1 + last - first, element.substring(1 + last)];
  }
}

class _MapOrList {
  final List? list;
  final Map? map;

  _MapOrList.map(this.map) : list = null;
  _MapOrList.list(this.list) : map = null;

  Object extract() => list ?? map!;

  void add(String name, Object value) => //
      (name.isNotEmpty) //
          ? map![name] = value
          : list!.add(value);
}
