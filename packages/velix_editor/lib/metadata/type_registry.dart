
import 'package:velix/i18n/translator.dart';
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

  Map<String, WidgetDescriptor> descriptor = {};
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
          var label = field.name;
          if (property.i18n != null) {
            label = Translator.tr("${property.i18n}.label");
          }

          var group = property.group;
          if (property.groupI18N != null) {
            label = Translator.tr("${property.groupI18N}.label");
          }

          properties.add(Property(name: field.name, label: label, group: group, field: field, hide: property.hide, editor: property.editor));
        }
      }

      var widgetDescriptor = WidgetDescriptor(
        name: declareWidget.name,
        icon: declareWidget.icon,
        group: declareWidget.group,
        type: widgetType,
        properties: properties,
      );

      register(widgetDescriptor);
    }
  }

  // public

  T parse<T>(Map<String, dynamic> data) {
    var type = data["type"]!;

    return descriptor[type]!.parse<T>(data);
  }

  TypeRegistry register(WidgetDescriptor descriptor) {
    this.descriptor[descriptor.name] = descriptor;
    byType[descriptor.type.type] = descriptor;

    return this;
  }

  WidgetDescriptor getDescriptor(WidgetData data) {
    return byType[data.runtimeType]!;
  }

  WidgetDescriptor operator [](String type) {
    return descriptor[type]!;
  }
}