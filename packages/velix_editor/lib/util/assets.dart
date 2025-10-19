// assets.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// Base class for nodes in the asset tree (folders or files)
abstract class AssetNode {
  final String path;   // full logical path
  final String name;   // last segment without suffix
  final String type;   // "Folder" for folders, or file extension

  AssetNode(this.path)
      : type = _computeType(path),
        name = _computeName(path);

  static String _computeType(String path) {
    final last = path.split('/').last;
    if (!last.contains('.') || last.endsWith('/')) return 'folder';
    final dotIndex = last.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == last.length - 1) return '';
    return last.substring(dotIndex + 1);
  }

  static String _computeName(String path) {
    final last = path.split('/').last;
    if (!last.contains('.') || last.endsWith('/')) return last; // folder or no extension
    final dotIndex = last.lastIndexOf('.');
    return last.substring(0, dotIndex); // strip suffix
  }

  bool get isFolder => type == 'folder';
  bool get isFile => !isFolder;
}

/// Represents a folder of assets
class AssetFolder extends AssetNode {
  final Map<String, AssetFolder> subfolders = {};
  final Map<String, AssetItem> items = {};

  AssetFolder(super.path);

  /// All children: folders + files
  Iterable<AssetNode> get children => [
    ...subfolders.values,
    ...items.values,
  ];

  /// Get a child folder by name
  AssetFolder? folder(String name) => subfolders[name];

  /// Get a child item by name
  AssetItem? item(String name) => items[name];

  Future<void> preload<T>([String? prefix]) async {
    for (var item in list(prefix))
      await item.load<T>();
  }

  //Future<R> transform<T, R>([R Function(T internal)? transformer]) async {
  Future<void> preloadTransform<T,R>({String? prefix, R Function(T internal)? transform}) async {
    if (transform != null)
      for (var item in list(prefix))
        await item.transform<T,R>(transform);
    else
      for (var item in list(prefix))
        await item.load<T>();
  }

  Iterable<AssetItem> list([String? prefix]) sync* {
    // If a prefix is provided, navigate to that folder first
    if (prefix != null) {
      final parts = prefix.split('/');
      AssetFolder? current = this;

      for (var i = 0; i < parts.length; i++) {
        final folderPath = parts.sublist(0, i + 1).join('/');
        current = current?.subfolders[folderPath];
        if (current == null) return; // prefix not found
      }
      yield* current!.list(); // recursively list from the prefix folder
      return;
    }

    // No prefix: yield items in this folder
    yield* items.values;

    // Recurse into subfolders
    for (final sub in subfolders.values) {
      yield* sub.list();
    }
  }
}

class AssetException implements Exception {
  // instance data

  final String message;
  final Exception? cause;

  // constructor

  /// Create a new [AssetException]
  /// [message] the message
  /// [cause] optional chained exception
  const AssetException(this.message, {this.cause});

  @override
  String toString() => 'AssetException: $message';
}

class AssetLoaderException extends AssetException {
  // instance data

  final String path;

  // constructor

  /// Create a new [AssetLoaderException]
  /// [message] the message
  /// [cause] optional chained exception
  const AssetLoaderException(super.message, {
    super.cause,
    required this.path
  });

  @override
  String toString() => 'AssetLoaderException: $message';
}

/// Represents a single asset file
class AssetItem extends AssetNode {
  final Map<Type, dynamic> _data = {};

  AssetItem(super.path);

  Map<String,dynamic> json() {
    return get<Map<String,dynamic>>();
  }

  String string() {
    return get<String>();
  }

  T get<T>() {
    return _data[T]!;
  }

  Future<R> transform<T, R>([R Function(T internal)? transformer]) async {
    await load<T>();

    if (transformer == null) {
      // Identity transform: just return the cached value as R
      if (_data[T] is! R) {
        throw StateError(
            "Type mismatch: requested $R, cached value is ${_data[T].runtimeType}");
      }

      return _data[T] as R;
    }

    // Apply transformer and cache by type R
    if (_data.containsKey(R))
      return _data[R] as R;

    try {
      final result = transformer(_data[T] as T);
      _data[R] = result;

      return result;
    }
    on Exception catch (e) {
      throw AssetException("error transforming asset assets/$path", cause: e);
    }

  }

  /// Load as string
  Future<T> load<T>() async {
    var result = _data[T];

    if ( result == null) {
      try {
        if (T == String)
          result = await rootBundle.loadString("assets/$path");
        else if (T == Uint8List) {
          final bytes = await rootBundle.load("assets/$path");

          result = bytes.buffer.asUint8List();
        }

        else if (T == Map<String, dynamic>) {
          var str = await load<String>();
          result = jsonDecode(str);
        }

        _data[T] = result;
      }
      on AssetLoaderException catch(e) {
        rethrow;
      }
      on Exception catch (e) {
        throw AssetLoaderException("error loading asset", cause: e, path: "assets/$path");
      }
      catch(e) {
        print(e);
      }
    }

    return _data[T];
  }
}

/// Static manager for all assets
class Assets {
  static late AssetFolder _root;
  static bool _initialized = false;

  /// Initialize asset tree from AssetManifest.json
  static Future<void> init() async {
    if (_initialized) return;
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    _root = AssetFolder('assets');

    for (final path in manifestMap.keys) {
      _addPath(path.substring("assets/".length));
    }

    _initialized = true;
  }

  /// Add a path to the tree, creating intermediate folders
  static void _addPath(String path) {
    final parts = path.split('/');
    var current = _root;

    for (var i = 0; i < parts.length - 1; i++) {
      final folderPath = parts.sublist(0, i + 1).join('/');
      current = current.subfolders.putIfAbsent(
        folderPath,
            () => AssetFolder(folderPath),
      );
    }

    final fileName = parts.last;
    current.items[fileName] = AssetItem(path);
  }

  /// Get a node by path (folder or file)
  static AssetFolder assets() {
    if (!_initialized) {
      throw StateError('Assets.init() must be called first.');
    }

    return _root;
   }
  }
