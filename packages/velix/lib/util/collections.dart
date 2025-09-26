T? findElement<T>(Iterable<T> list, bool Function(T element) test ) {
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


class LruCache<K, V> {
  // instance data

  final int maxSize;
  final _cache = <K, V>{};

  // constructor

  LruCache(this.maxSize) {
    if (maxSize <= 0) {
      throw ArgumentError('maxSize must be > 0');
    }
  }

  // public

  V? get(K key) {
    if (!_cache.containsKey(key))
      return null;

    // Move key to the end to mark it as recently used
    final value = _cache.remove(key)!;
    _cache[key] = value;

    return value;
  }

  void set(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    else if (_cache.length >= maxSize) {
      // Remove the least recently used (first) entry
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void clear() => _cache.clear();

  @override
  String toString() => _cache.toString();
}