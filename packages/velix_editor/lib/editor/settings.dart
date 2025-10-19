import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:velix/util/collections.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_ui/provider/environment_provider.dart';


// {
//     "owner": "editor";
//     "data": {
//        "foo": 1
//      },
//     "children:": [
//       {
//        "owner: "kkk"
//        ...
//       }
//     ];
// }
//
//

mixin StatefulMixin<T extends StatefulWidget> on State<T> {
  // instance data

  StatefulMixin? _parent;
  List<StatefulMixin> _children = [];
  late Map<String,dynamic> state;

  String get stateName;

  //SettingsManager get settings => EnvironmentProvider.of(context).get<SettingsManager>();

  // internal

  StatefulMixin? _getParent() {
    return context.findAncestorStateOfType<StatefulMixin>();
  }

  StatefulMixin? _getRoot() {
    StatefulMixin? result = this;
    while ( result!._parent != null)
      result = result._parent;

    return result;
  }

  // public

  void flushSettings() {
    EnvironmentProvider.of(context).get<SettingsManager>().flush(_getRoot()!.state);
  }

  void applySettings() {
    apply(state["data"]);
  }

  void writeSettings() {
    write(state["data"]);
  }

  Future<void> apply(Map<String,dynamic> data) async {

  }

  Future<void> write(Map<String,dynamic> data) async {

  }

  // override

  @override
  void initState() {
    super.initState();

    // look for a parent state

    if (_getParent() != null) {
      _parent = _getParent();
      _parent!._children.add(this);

      var persistentState = findElement<Map<String,dynamic>>(_getParent()!.state["children"], (state) => state["owner"] == stateName);

      if ( persistentState != null)
        apply((state = persistentState)["data"]);
      else {
        write(state = {
          'owner': stateName,
          'data': Map<String,dynamic>(),
          'children': <Map<String,dynamic>>[]
        });

        // and link

        _getParent()!.state["children"].add(state);
      }
    }
    else {
      apply(state["data"]);
    }
  }

  @override
  void dispose() {
    write(state);

    // done

    super.dispose(); // Must call super last
  }
}

@Injectable()
class SettingsManager {
  // instance data

  late Directory dir;
  late File file;
  Map<String, dynamic> settings = {};
  bool initialized = false;

  // constructor

  SettingsManager() {
    init();
  }

  // public

  Map<String, dynamic> getSettings(String owner) {
    if (settings["owner"] == null) {
      settings["owner"] = owner;
      settings["data"] = Map<String, dynamic>();
      settings["children"] = <Map<String, dynamic>>[];
    }

    return settings;
  }

  Future<void> init() async {
    if (!initialized) {
      dir = await getApplicationSupportDirectory();

      file = File('${dir.path}/settings.json');
      if (await file.exists()) {
        var settings = await file.readAsString();
        this.settings = settings.isNotEmpty ? jsonDecode(settings) : {};
      }
      else {
        await file.writeAsString(jsonEncode(settings));
      }

      initialized = true;
    }
  }

  Future<void> flush(Map<String, dynamic>? settings) async {
    await init();
    await file.writeAsString(jsonEncode(this.settings = settings ?? this.settings));
  }

  // public

  T set<T>(String key, T value) {
    settings[key] = value;

    return value;
  }

  T get<T>(String key, {T? defaultValue}) {
    var result = settings[key];
    if ( result != null)
      return result as T;
    else  {
      return set<T>(key, defaultValue!);
    }
  }
}