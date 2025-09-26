
class ClassDesc extends Desc {
  // static

  static final  int_type     = ClassDesc("int");
  static final double_type  = ClassDesc("double");
  static final string_type  = ClassDesc("String");
  static final bool_type    = ClassDesc("bool");
  static final dynamic_type = ClassDesc("dynamic");

  // static

  static getType(String name) {
    final literalTypes = {
      "String": string_type,
      "int": int_type,
      "double": double_type,
      "bool": bool_type,
    };

    return literalTypes[name]; // TODO
  }

  // instance data

  final Map<String, Desc> _properties;

  // constructor

  ClassDesc(
      super.name, {
        Map<String, Desc>? properties,
      })  : _properties = properties ?? {};

  // public

  Desc? find(String name) => _properties[name];

  // override

  @override
  String toString() => name;
}

class Desc {
  // instance data

  final String name;

  // constructor

  Desc(this.name);
}

class FieldDesc extends Desc {
  // instance data

  final ClassDesc type;

  // constructor

  FieldDesc(String name, this.type) : super(name);
}

class MethodDesc extends Desc {
  // instance data

  final List<ClassDesc> parameterTypes;
  final ClassDesc returnType;

  // constructor

  MethodDesc(String name, this.parameterTypes, this.returnType): super(name);
}
