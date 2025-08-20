// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'package:sample/models/todo.dart';
import 'package:velix/reflectable/reflectable.dart';

void registerAllDescriptors() {
  type<Details>(
    name: 'package:sample/models/todo.dart.Details',
    params: [
      param<String>('author', isNamed: true, isRequired: true), 
      param<int>('priority', isNamed: true, isRequired: true)
    ],
    constructor: ({String author = '', int priority = 0}) => Details(author: author, priority: priority, date: DateTime.now()),
    fields: [
      field<Details,String>('author',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Details).author,
        isFinal: true,
      ), 
      field<Details,int>('priority',
        type: IntType().greaterThan(0),
        getter: (obj) => (obj as Details).priority,
        isFinal: true,
      ),
      field<Details,DateTime>('date',
        type: DateTimeType(),
        getter: (obj) => (obj as Details).date,
        isFinal: true,
      )
    ]
  );

  type<Todo>(
    name: 'package:sample/models/todo.dart.Todo',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<String>('title', isNamed: true, isRequired: true), 
      param<Details>('details', isNamed: true, isNullable: true, defaultValue: null), 
      param<bool>('completed', isNamed: true, isNullable: true, defaultValue: false)
    ],
    constructor: ({String id = '', String title = '', required Details details, bool completed = false}) => Todo(id: id, title: title, details: details, completed: completed),
    fields: [
      field<Todo,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => (obj as Todo).id,
        setter: (obj, value) => (obj as Todo).id = value,
      ), 
      field<Todo,String>('title',
        type: StringType().maxLength(10),
        getter: (obj) => (obj as Todo).title,
        setter: (obj, value) => (obj as Todo).title = value,
      ), 
      field<Todo,bool>('completed',
        getter: (obj) => (obj as Todo).completed,
        setter: (obj, value) => (obj as Todo).completed = value,
      ), 
      field<Todo,Details>('details',
        getter: (obj) => (obj as Todo).details,
        setter: (obj, value) => (obj as Todo).details = value,
        isNullable: true
      )
    ]
  );
}
