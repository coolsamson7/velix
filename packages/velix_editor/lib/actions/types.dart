


class ClassRegistry {
  // instance data

  Map<String,ClassDesc> classes = {};
  Map<String,Desc> types = {
    "String": Desc("String"),
    "int": Desc("int"),
    "double": Desc("double"),
    "bool": Desc("bool"),
    "dynamic": Desc("dynamic"),
    "void": Desc("void"),
  };

  // constructor

  ClassRegistry();

  // public

  ClassDesc getClass(String name) {
    return classes[name]!;
  }

  Desc getType(String name) {
    var result = types[name];
    if ( result == null) {
      if (name.startsWith("List<")) {
        var innerType = name.substring("List<".length, name.lastIndexOf(">"));

        result = ListDesc(name, elementType: getType(innerType));

        types[name] = result;
      }
      else {
        result = Desc(name);
        types[name] = result;
      }
    }

    return result;
  }

  // constructor

  // public

  void read(List<dynamic> items) {
    // fill registry

    for (var item in items) {
      var name = item["name"];

      var desc = ClassDesc(name);

      desc.registry = this;

      classes[name] = desc;
      types[name] = desc;
    }

    // parse

    for (var item in items) {
      var name = item["name"];
      var clazz = getClass(name);

      if ( item["superClass"] != null)
        clazz.superClass = getClass(item["superClass"]);

      // properties

      for (var property in item["properties"]) {
        var name = property["name"];

        clazz.properties[name] = FieldDesc(property["name"], type: getType(property["type"]));
      }

      // properties

      for (var method in item["methods"]) {
        var name = method["name"];

        List<dynamic> params = method["parameters"] as List<dynamic>;

        List<ParameterDesc> parameters = params.map((p) =>
          ParameterDesc(p["name"], type: getType(p["type"]))
        ).toList();

        clazz.properties[name] = MethodDesc(name, parameters, type: getType(method["returnType"]));
      }
    }
  }

}

class Desc {
  // static

  static final int_type     = Desc("int");
  static final double_type  = Desc("double");
  static final string_type  = Desc("String");
  static final bool_type    = Desc("bool");
  static final dynamic_type = Desc("dynamic");

  static Map<String,Desc> types = {
    "String": string_type,
    "int": int_type,
    "double": double_type,
    "bool": bool_type,
    "dynamic": dynamic_type,
  };

  // static

  static Desc getType(String name) {
    var result = types[name];
    if ( result == null) {
      result = Desc(name);
      types[name] = result;
    }

    return result;
  }

  // constructor

  // instance data

  final String name;
  ClassRegistry? registry;

  // public

  bool isList() {
    return this is ListDesc;
  }

  // constructor

  Desc(this.name);
}

class ListDesc extends Desc {
  final Desc elementType;

  ListDesc(super.name, {required this.elementType});
}

class ParameterDesc extends Desc {
  Desc type;

  ParameterDesc(super.name, {required this.type});
}

class ClassDesc extends Desc {
  // instance data

  ClassDesc? superClass;
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

  ClassPropertyDesc? find(String name) => properties[name];

  // override

  @override
  String toString() => name;
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

  final List<ParameterDesc> parameters;

  // constructor

  MethodDesc(String name, this.parameters, {required super.type}): super(name);

  // public

  dynamic getElementType() {
    return null;
  }

  // override

  @override
  bool isMethod() => true;
}
