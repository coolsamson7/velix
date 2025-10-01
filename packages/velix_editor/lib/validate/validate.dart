import 'package:velix_di/di/di.dart';
import 'package:velix_editor/actions/action_parser.dart';
import 'package:velix_editor/actions/infer_types.dart';
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/metadata/metadata.dart';
import 'package:velix_editor/metadata/type_registry.dart';

import '../metadata/properties/properties.dart';
import '../metadata/widget_data.dart';

class ValidationError {
  WidgetData widget;
  String property;
  Exception exception;

  ValidationError({required this.widget, required this.property, required this.exception});
}

class ValidationContext {
  // instance data

  Environment environment;
  ClassDesc type;
  List<ValidationError> errors = [];

  // constructor

  ValidationContext({required this.type, required this.environment});

  // public

  T get<T>(Type type) => environment.get(type: type) as T;
}

class ValidationException implements Exception {
  List<ValidationError> errors;

  ValidationException({required this.errors});
}

@Injectable(factory: false)
abstract class PropertyValidator<T> {
  // instance data

  bool register = true;

  // constructor

  PropertyValidator();

  // lifecycle

  @Inject()
  void set(WidgetValidator validator) {
    if (register)
      validator.register(this);
  }

  // public

  Type getType() => T;

  // abstract

  void validate(T value, ValidationContext context);
}

@Injectable()
class ExpressionPropertyValidator extends PropertyValidator<String> {
  // instance data

  // constructor

  ExpressionPropertyValidator() {
    register = false;
  }

  // internal

  void validateExpression(String binding, ClassDesc type) {
    try {
      var expression = ActionParser.instance.parse(binding);

      final checker = TypeChecker(ClassDescTypeResolver(root: type));

      expression.accept(checker);


      print(1);
    }
    catch(e) {
      rethrow;
    }
  }

  // implement

  @override
  void validate(String value, ValidationContext context) {
    validateExpression(value, context.type);
  }
}


@Injectable()
class ValuePropertyValidator extends PropertyValidator<Value> {
  // instance data

  // constructor

  ValuePropertyValidator();

  // internal

  void validateI18N(String key) {}

  void validateBinding(String binding, ClassDesc type) {
    try {
      var expression = ActionParser.instance.parse(binding);

      final checker = TypeChecker(ClassDescTypeResolver(root: type));

      expression.accept(checker);

      print(1);
    }
    catch(e) {
      rethrow;
    }
  }

  // implement

  @override
  void validate(Value value, ValidationContext context) {
    if (value.type == ValueType.i18n)
      validateI18N(value.value);
    else if (value.type == ValueType.binding)
      validateBinding(value.value, context.type);
  }
}


@Injectable()
class WidgetValidator {
  // instance data

  TypeRegistry registry;
  Map<Type,PropertyValidator> propertyValidators = {};

  // constructor

  WidgetValidator({required this.registry});

  //

  void register(PropertyValidator propertyValidator) {
    propertyValidators[propertyValidator.getType()] = propertyValidator;
  }

  PropertyValidator? getValidator(PropertyDescriptor property, ValidationContext context) {
    if (property.validator != null)
      return context.get<PropertyValidator>(property.validator!);
    else
      return propertyValidators[property.type];
  }
  
  // internal
  
  void _validate(WidgetData widget, ValidationContext context) {
    var descriptor = registry[widget.type];

    for (var property in descriptor.properties) {
      var validator = getValidator(property, context);
      if (validator != null) {
        try {
          var value = property.field.get(widget);
          if (value != null)
            validator.validate(value, context);
        }
        on Exception catch (e) {
          context.errors.add(ValidationError(
              widget: widget,
              property: property.name,
              exception: e
          ));
        }
      }
    }
  }

  // public

  void validate(WidgetData widget, {required ClassDesc type, required Environment environment}) {
    // local function

    void validateWidget(WidgetData widget, ValidationContext context) {
      _validate(widget, context);
      
      // recursion

      for ( var child in widget.children)
        validateWidget(child, context);
    }

    var context = ValidationContext(environment: environment, type: type);

    validateWidget(widget, context);

    if (context.errors.isNotEmpty)
      throw ValidationException(errors: context.errors);
  }
}