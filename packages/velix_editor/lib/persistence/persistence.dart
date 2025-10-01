import 'package:velix_di/di/di.dart';

import '../metadata/type_registry.dart';
import '../metadata/widget_data.dart';

@Injectable()
class WidgetLoader {
  // public

}

@Injectable()
class WidgetExporter {
  // instance data

  TypeRegistry typeRegistry;

  // constructor

  WidgetExporter({required this.typeRegistry});

  void foo() {

  }

  // internal

  void prepare(WidgetData data) {
    var descriptor = typeRegistry[data.type];

    for ( var property in descriptor.properties.values) {
      var defaultValue = property.defaultValue;
    }
  }

  // public

  void export(WidgetData data) {
    prepare(data);

    for (var child in data.children)
      export(child);
  }
}