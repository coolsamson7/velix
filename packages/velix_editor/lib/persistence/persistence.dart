import 'dart:convert';

import 'package:velix_di/di/di.dart';
import 'package:velix_mapper/mapper/json.dart';

import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';

@Injectable()
class WidgetLoader {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  WidgetLoader({required this.typeRegistry});

  // internal

  void _prepare(WidgetData data) {
    void traverse(WidgetData data, WidgetData? parent) {
      data.parent = parent;

      // anything to check? TODO

      // recursion

      for ( var child in data.children)
        traverse(child, data);
    }

    traverse(data, null);
  }

  // public

  WidgetData load(String json) {
    var map = jsonDecode(json);
    var data = JSON.deserialize<WidgetData>(map);

    _prepare(map);

    return data;
  }
}

@Injectable()
class WidgetExporter {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  WidgetExporter({required this.typeRegistry});

  // internal

  void prepare(Map<String,dynamic> data) {
    var descriptor = typeRegistry[data["type"]];

    for ( var property in descriptor.properties.values)
    if ( property.name != "children" && property.name != "parent" ){
      var defaultValue = property.defaultValue;

      if (data[property.name] == defaultValue)
        data.remove(property.name);
    }

    for (var child in data["children"])
      prepare(child);
  }

  // public

  String export(WidgetData data) {
    var map = JSON.serialize(data);

    prepare(map);

    return jsonEncode(data);
  }
}