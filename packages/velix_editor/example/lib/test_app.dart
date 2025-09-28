import 'package:flutter/material.dart' hide Autocomplete;
import 'package:velix_editor/actions/types.dart';
import 'package:velix_editor/actions/autocomplete.dart';
import 'package:velix_editor/property_panel/editor/code_editor.dart';

final pageClass = ClassDesc('Page',
    properties: {
      'user': FieldDesc('user', type: userClass),
    }
);

final userClass = ClassDesc('User',
  properties: {
    'name': FieldDesc('value', type: Desc.string_type),
    'address': FieldDesc('address',  type: addressClass),
    'hello': MethodDesc('hello', [ParameterDesc("message", type: Desc.string_type)], type: Desc.string_type)
  },
);

final addressClass = ClassDesc('Address',
  properties: {
    'city': FieldDesc('city', type: Desc.string_type),
    'street': FieldDesc('street', type: Desc.string_type)
  },
);

var autocomplete = Autocomplete(pageClass);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    void onChanged(dynamic v) {
      print(v);
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dot-Access Expression Editor')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CodeEditor(value: "user.", onChanged: onChanged ),
        ),
      ),
    );
  }
}