abstract class Property<CONTEXT> {
  /// Read a property value given an instance
  ///
  /// [instance] the instance
  /// [context] the context object
  /// Returns the retrieved value
  dynamic get(dynamic instance, CONTEXT context);

  /// Write a property value given an instance
  ///
  /// [instance] the instance
  /// [value] the value to write
  /// [context] the context object
  void set(dynamic instance, dynamic value, CONTEXT context);
}

/// An [Operation] contains a source and a target [Property] that are used
/// to read values from a source and set the result in the target object
///
/// [CONTEXT] any context information that could be needed during a transformation
class Operation<CONTEXT> {
  Property<CONTEXT> source;
  Property<CONTEXT> target;

  Operation(this.source, this.target);

  /// Set a target property by reading the appropriate value from the source
  ///
  /// [from] the source object
  /// [to] the target object
  /// [context] the context
  void setTarget(dynamic from, dynamic to, CONTEXT context) {
    target.set(to, source.get(from, context), context);
  }

  /// Set a source property by reading the appropriate value from the target
  ///
  /// [to] the target object
  /// [from] the source object
  /// [context] the context
  void setSource(dynamic to, dynamic from, CONTEXT context) {
    source.set(from, target.get(to, context), context);
  }
}

/// [Transformer] is a generic class that transforms a source into a target object given a list of [Operation]s.
class Transformer<CONTEXT> {
  final List<Operation<CONTEXT>> operations;

  Transformer(this.operations);

  /// A [Property] is able to read and write property values given an instance
  ///
  /// [CONTEXT] any context information that could be needed during a transformation


  /// Modify a target instance by applying all specified operations.
  ///
  /// [source] the source object
  /// [target] the target object
  /// [context] the context object
  void transformTarget(dynamic source, dynamic target, CONTEXT context) {
    var len  = operations.length;
    for ( int i = 0; i < len; i++) {
      operations[i].setTarget(source, target, context);
    }
  }
}