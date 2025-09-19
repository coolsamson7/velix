
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';

import 'annotations.dart';
import 'metadata.dart';
import 'widget_data.dart';

@Injectable()
class TypeRegistry {
  // static data

  static List<TypeDescriptor> types = [];

  // static methods

  static void declare(TypeDescriptor type) {
    types.add(type);
  }

  // instance data

  Map<String, WidgetDescriptor> metaData = {};
  Map<Type, WidgetDescriptor> byType = {};

  // constructor

  // lifecycle

  @OnInit()
  void setup() {
    for (var widgetType in types) {
      var declareWidget = widgetType.getAnnotation<DeclareWidget>()!;

      List<Property> properties = [];

      for (var field in widgetType.getFields()) {
        var property = field.findAnnotation<DeclareProperty>();

        if (property != null) {
          properties.add(Property(name: field.name, group: property.group, field: field, hide: property.hide));
        }
      }

      var widgetMetaData = WidgetDescriptor(
        name: declareWidget.name,
        icon: declareWidget.icon,
        group: declareWidget.group,
        type: widgetType,
        properties: properties,
      );

      register(widgetMetaData);
    }
  }

  // public

  T parse<T>(Map<String, dynamic> data) {
    var type = data["type"]!;

    return metaData[type]!.parse<T>(data);
  }

  TypeRegistry register(WidgetDescriptor metaData) {
    this.metaData[metaData.name] = metaData;
    this.byType[metaData.type.type] = metaData;

    return this;
  }

  WidgetDescriptor getMetaData(WidgetData data) {
    return byType[data.runtimeType]!;
  }

  WidgetDescriptor operator [](String type) {
    return metaData[type]!;
  }
}