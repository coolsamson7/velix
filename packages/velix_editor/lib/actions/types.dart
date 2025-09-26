import 'package:velix/reflectable/reflectable.dart';
import 'package:velix/validation/validation.dart';

/// =======================
/// Type System
/// =======================
///
///
/// // NEW

class TypeInfo {

}

abstract class TypeResolver<T> {
  T resolve(String name, {T? parent});

  T resolveType(Type type);
}

//class ClassDescTypeResolver extends TypeResolver {

//

class AbstractTypeResolver extends TypeResolver<AbstractType> {
  TypeDescriptor root;

  AbstractTypeResolver({required this.root});

  @override
  AbstractType resolve(String name, {AbstractType? parent}) {
    if ( parent == null)
      return root.getField(name).type;
    else
      return (parent as ObjectType).typeDescriptor.getField(name).type;
  }

  @override
  AbstractType resolveType(Type type) {
    return ClassType(type); // TODO -> cache string, etc
  }

}


///
class ClassDesc {
  final String name;
  final Map<String, FieldDesc> fields;
  final Map<String, MethodDesc> methods;

  ClassDesc(
      this.name, {
        Map<String, FieldDesc>? fields,
        Map<String, MethodDesc>? methods,
      })  : fields = fields ?? {},
        methods = methods ?? {};

  FieldDesc? lookupField(String name) => fields[name];
  MethodDesc? lookupMethod(String name) => methods[name];

  @override
  String toString() => name;
}

class FieldDesc {
  final String name;
  final ClassDesc type;
  FieldDesc(this.name, this.type);
}

class MethodDesc {
  final String name;
  final List<ClassDesc> parameterTypes;
  final ClassDesc returnType;

  MethodDesc(this.name, this.parameterTypes, this.returnType);
}
