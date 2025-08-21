T? findElement<T>(List<T> list, bool Function(T element) test ) {
  for ( var element in list) {
    if ( test(element)) {
      return element;
    }
  }

  return null;
}

class Keywords {
  // static

  static final empty = Keywords(const {});

  // instance data

  final Map<String, dynamic> _data = {};

  // constructor

  Keywords(Map<String, dynamic> args) {
    _data.addAll(args);
  }

  // public

  /// Add or update a keyword
  void set(String name, dynamic value) {
    _data[name] = value;
  }

  /// Generic getter with type safety
  T? get<T>(String name) {
    final value = _data[name];
    if (value is T) {
      return value;
    }

    return null;
  }

  /// Check if a keyword exists
  bool contains(String name) => _data.containsKey(name);

  /// Access the raw map
  Map<String, dynamic> get raw => Map.unmodifiable(_data);

  /// Optional: index operator for convenience
  dynamic operator [](String name) => _data[name];
  void operator []=(String name, dynamic value) => _data[name] = value;
}