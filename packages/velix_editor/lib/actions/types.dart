
class ClassDesc extends Desc {
  // instance data

  final Map<String, ClassPropertyDesc> properties;

  // constructor

  ClassDesc(
      super.name, {
        Map<String, ClassPropertyDesc>? properties,
      })  : properties = properties ?? {} {
    for ( var prop in this.properties.values)
      prop.classDesc = this;
  }

  // public

  Desc? find(String name) => properties[name];

  // override

  @override
  String toString() => name;
}

class Desc {
  // static

  static final int_type     = Desc("int");
  static final double_type  = Desc("double");
  static final string_type  = Desc("String");
  static final bool_type    = Desc("bool");
  static final dynamic_type = Desc("dynamic");

  // static

  static Desc getType(String name) {
    final literalTypes = {
      "String": string_type,
      "int": int_type,
      "double": double_type,
      "bool": bool_type,
    };

    return literalTypes[name]!; // TODO
  }

  // instance data

  final String name;

  // constructor

  Desc(this.name);
}

abstract class ClassPropertyDesc extends Desc {
  late ClassDesc classDesc;
  final Desc type;

  ClassPropertyDesc(String name, {required this.type}): super(name);

  bool isField() => false;
  bool isMethod() => false;
}

class FieldDesc extends ClassPropertyDesc {
  // constructor

  FieldDesc(String name, {required super.type}) : super(name);

  @override
  bool isField() => true;
}

class MethodDesc extends ClassPropertyDesc {
  // instance data

  final List<Desc> parameterTypes;

  // constructor

  MethodDesc(String name, this.parameterTypes, {required super.type}): super(name);

  @override
  bool isMethod() => true;
}
