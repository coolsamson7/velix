
import 'dart:ui';

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
          properties.add(Property(name: field.name, i18n: property.i18n, group: property.group, field: field, hide: property.hide, editor: property.editor, groupI18n: property.groupI18N));
        }
      }

      var widgetDescriptor = WidgetDescriptor(
        name: declareWidget.name,
        i18n: declareWidget.i18n,
        icon: declareWidget.icon,
        group: declareWidget.group,
        type: widgetType,
        properties: properties,
      );

      register(widgetDescriptor);
    }
  }

  // internal

  void changedLocale(Locale locale) {
   for ( var descriptor in this.descriptor.values)
     descriptor.updateI18n();
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