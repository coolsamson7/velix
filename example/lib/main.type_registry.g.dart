// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_import
import 'package:velix/velix.dart';
import 'package:sample/models/todo.dart';
import 'package:velix/reflectable/reflectable.dart';

void registerAllDescriptors() {
  type<Details>(
    location: 'package:sample/models/todo.dart.Details',
    params: [
      param<String>('author', isNamed: true, isRequired: true), 
      param<int>('priority', isNamed: true, isRequired: true), 
      param<DateTime>('date', isNamed: true, isRequired: true)
    ],
    constructor: ({String author = '', int priority = 0, required DateTime date}) => Details(author: author, priority: priority, date: date),
    fromMapConstructor: (Map<String,dynamic> args) => Details(author: args['author'] as String? ?? '', priority: args['priority'] as int? ?? 0, date: args['date'] as DateTime),
    fromArrayConstructor: (List<dynamic> args) => Details(author: args[0] as String? ?? '', priority: args[1] as int? ?? 0, date: args[2] as DateTime),
    fields: [
      field<Details,String>('author',
        type: StringType().maxLength(7),
        getter: (obj) => obj.author,
      ), 
      field<Details,int>('priority',
        type: IntType().greaterThan(0),
        getter: (obj) => obj.priority,
      ), 
      field<Details,DateTime>('date',
        getter: (obj) => obj.date,
      )
    ]
  );

  type<Todo>(
      location: 'package:sample/models/todo.dart.Todo',
    params: [
      param<String>('id', isNamed: true, isRequired: true), 
      param<String>('title', isNamed: true, isRequired: true), 
      param<Details>('details', isNamed: true, isNullable: true, defaultValue: null), 
      param<bool>('completed', isNamed: true, isNullable: true, defaultValue: false)
    ],
    constructor: ({String id = '', String title = '', required Details details, bool completed = false}) => Todo(id: id, title: title, details: details, completed: completed),
    fromMapConstructor: (Map<String,dynamic> args) => Todo(id: args['id'] as String? ?? '', title: args['title'] as String? ?? '', details: args['details'] as Details, completed: args['completed'] as bool? ?? false),
    fromArrayConstructor: (List<dynamic> args) => Todo(id: args[0] as String? ?? '', title: args[1] as String? ?? '', details: args[2] as Details, completed: args[3] as bool? ?? false),
    fields: [
      field<Todo,String>('id',
        type: StringType().maxLength(7),
        getter: (obj) => obj.id,
        setter: (obj, value) => (obj as Todo).id = value,
      ), 
      field<Todo,String>('title',
        type: StringType().maxLength(10),
        getter: (obj) => obj.title,
        setter: (obj, value) => (obj as Todo).title = value,
      ), 
      field<Todo,bool>('completed',
        getter: (obj) => obj.completed,
        setter: (obj, value) => (obj as Todo).completed = value,
      ), 
      field<Todo,Details>('details',
        getter: (obj) => obj.details,
        setter: (obj, value) => (obj as Todo).details = value,
        isNullable: true
      )
    ]
  );

  type<TestData>(
      location: 'package:sample/models/todo.dart.TestData',
    params: [
      param<String>('string_data', isNamed: true, isRequired: true), 
      param<int>('int_data', isNamed: true, isRequired: true), 
      param<int>('slider_int_data', isNamed: true, isRequired: true), 
      param<bool>('bool_data', isNamed: true, isRequired: true), 
      param<DateTime>('datetime_data', isNamed: true, isRequired: true)
    ],
    constructor: ({String string_data = '', int int_data = 0, int slider_int_data = 0, bool bool_data = false, required DateTime datetime_data}) => TestData(string_data: string_data, int_data: int_data, slider_int_data: slider_int_data, bool_data: bool_data, datetime_data: datetime_data),
    fromMapConstructor: (Map<String,dynamic> args) => TestData(string_data: args['string_data'] as String? ?? '', int_data: args['int_data'] as int? ?? 0, slider_int_data: args['slider_int_data'] as int? ?? 0, bool_data: args['bool_data'] as bool? ?? false, datetime_data: args['datetime_data'] as DateTime),
    fromArrayConstructor: (List<dynamic> args) => TestData(string_data: args[0] as String? ?? '', int_data: args[1] as int? ?? 0, slider_int_data: args[2] as int? ?? 0, bool_data: args[3] as bool? ?? false, datetime_data: args[4] as DateTime),
    fields: [
      field<TestData,String>('string_data',
        type: StringType().maxLength(7),
        getter: (obj) => obj.string_data,
        setter: (obj, value) => (obj as TestData).string_data = value,
      ), 
      field<TestData,int>('int_data',
        type: IntType().greaterThan(0),
        getter: (obj) => obj.int_data,
        setter: (obj, value) => (obj as TestData).int_data = value,
      ), 
      field<TestData,int>('slider_int_data',
        type: IntType().greaterThan(0),
        getter: (obj) => obj.slider_int_data,
        setter: (obj, value) => (obj as TestData).slider_int_data = value,
      ), 
      field<TestData,bool>('bool_data',
        getter: (obj) => obj.bool_data,
        setter: (obj, value) => (obj as TestData).bool_data = value,
      ), 
      field<TestData,DateTime>('datetime_data',
        getter: (obj) => obj.datetime_data,
      )
    ]
  );
}
