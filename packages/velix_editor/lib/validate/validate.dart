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
  TypeChecker typeChecker;
  final List<ValidationError> errors;

  // constructor

  ValidationContext({required this.typeChecker, required this.environment, List<ValidationError>? errors}) : errors = errors ?? <ValidationError>[];

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

  void validateExpression(String binding, TypeChecker typeChecker) {
    if (binding.isNotEmpty)
      try {
        var result = ActionParser.instance.parseStrict(binding, typeChecker: typeChecker);
        if (!result.success)
          throw Exception(result.message);
      }
      catch(e) {
        rethrow;
      }
  }

  // override

  @override
  void validate(String value, ValidationContext context) {
    validateExpression(value, context.typeChecker);
  }
}

@Injectable()
class ContextPropertyValidator extends ExpressionPropertyValidator {
  // override

  @override
  void validate(String value, ValidationContext context) {
    var pr = ActionParser.instance.parseStrict(value, typeChecker: context.typeChecker);
    if ( pr.success) {
      var type = pr.value!.getType<Desc>();
      if (type.isList()) {
        type = (type as ListDesc).elementType;
        context.typeChecker = TypeChecker(ClassDescTypeResolver(root: type as ClassDesc, variables: {})); // TODO
      }
    }
    else {
      throw Exception(pr.message);
    }
  }
}


@Injectable()
class ValuePropertyValidator extends PropertyValidator<Value> {
  // instance data

  // constructor

  ValuePropertyValidator();

  // internal

  void validateI18N(String key) {}

  void validateBinding(String binding, TypeChecker typeChecker) {
    if ( binding.isNotEmpty)
      try {
        var result = ActionParser.instance.parseStrict(binding, typeChecker: typeChecker);
        if (!result.success)
          throw Exception(result.message);

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
      validateBinding(value.value, context.typeChecker);
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

  ValidationContext _validateProperties(WidgetData widget, ValidationContext context) {
    TypeChecker typeChecker = context.typeChecker;

    for (var property in registry[widget.type].properties.values) {
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

    if (typeChecker != context.typeChecker) {
      var newContext = ValidationContext(typeChecker: context.typeChecker, environment: context.environment, errors: context.errors);

      context.typeChecker = typeChecker; // restore

      // and return new instance for child widgets

      return newContext;
    }
    else return context;
  }

  // public

  void validate(WidgetData widget, {required ClassDesc type, required Environment environment}) {
    // local function

    void validateWidget(WidgetData widget, ValidationContext context) {
      context = _validateProperties(widget, context);
      
      // recursion

      for ( var child in widget.children)
        validateWidget(child, context);
    }

    var context = ValidationContext(environment: environment, typeChecker: TypeChecker(ClassDescTypeResolver(root: type, fail: true, variables: {}))); // TODO

    validateWidget(widget, context);

    if (context.errors.isNotEmpty)
      throw ValidationException(errors: context.errors);
  }
}