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
    assert(!key.contains(':') && !key.contains('.'), "Keys may not contain '.' or ':'");
    assert(value is! String || !value.startsWith(':'), "Values may not start with ':'");

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
    if (value is Set) {
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

      buffer.writeln("${'.' * depth}$key::::$_lines");
      buffer.write(_childBuffer.toString());
      return 1 + _lines;
    }
    throw "Unexpected State";
  }

  static Map<String, Object> decode(String sr) => _decodeChild(
        lineScope: sr.split('\n'),
        depth: 0,
        enableComments: (sr.startsWith("**")),
        parentType: _IterType.map,
      ).map!;

  // TODO currently simply assumes well formed file for optimization
  static _MapOrListOrSet _decodeChild({
    required List<String> lineScope,
    required int depth,
    required bool enableComments,
    required _IterType parentType,
  }) {
    final _MapOrListOrSet ret = parentType.init();

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
        // "n::s"   => map
        case 3:
        // "n:::s"  => list
        case 4:
          // "n::::s" => set
          final skip = int.parse(value);
          ret.add(
            components.first,
            _decodeChild(
              lineScope: lineScope.sublist(l + 1, l + 1 + skip),
              depth: depth + 1,
              enableComments: enableComments,
              parentType: _IterTypeX.fromColons(colons),
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
  // TODO this can be simplified by generalizing
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

        if (element.codeUnitAt(first + 3) != _colonRune) {
          // list:::size
          last = first + 2;
        } else {
          assert(element.length > first + 4, "Invalid Element; nothing after name: $element");
          // set::::size
          last = first + 3;

          assert(element.codeUnitAt(first + 4) != _colonRune, "Invalid Element; five colons: $element");
        }
      }
    }
    return [element.substring(0, first), 1 + last - first, element.substring(1 + last)];
  }
}

class _MapOrListOrSet {
  final List? list;
  final Map<String, Object>? map;
  final Set? set;

  _MapOrListOrSet.map(this.map)
      : list = null,
        set = null;
  _MapOrListOrSet.list(this.list)
      : map = null,
        set = null;
  _MapOrListOrSet.set(this.set)
      : map = null,
        list = null;

  Object extract() => list ?? map ?? set!;

  void add(String name, Object value) {
    if (map != null) {
      map![name] = value;
    } else if (list != null) {
      list!.add(value);
    } else {
      set!.add(value);
    }
  }
}

enum _IterType {
  map,
  list,
  set,
}

extension _IterTypeX on _IterType {
  _MapOrListOrSet init() {
    switch (this) {
      case _IterType.map:
        return _MapOrListOrSet.map({});
      case _IterType.list:
        return _MapOrListOrSet.list([]);
      case _IterType.set:
        return _MapOrListOrSet.set({});
    }
  }

  static _IterType fromColons(int colons) {
    switch (colons) {
      case 2:
        return _IterType.map;
      case 3:
        return _IterType.list;
      case 4:
        return _IterType.set;
      default:
        throw "Unexpected State";
    }
  }
}
