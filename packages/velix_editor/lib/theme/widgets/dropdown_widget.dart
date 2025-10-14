import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:provider/provider.dart';
import 'package:velix/reflectable/reflectable.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/metadata/properties/properties.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../../actions/action_evaluator.dart';
import '../../actions/eval.dart';
import '../../dynamic_widget.dart';
import '../../editor/editor.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widgets/dropdown.dart';
import '../../metadata/widgets/label.dart';
import '../../widget_container.dart';
import '../widget_builder.dart';

@Injectable()
class DropDownWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownWidgetBuilder({required this.typeRegistry}) : super(name: "dropdown");

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    return _DropDownWidget(
      data: data,
      typeRegistry: typeRegistry,
      environment: environment,
    );
  }
}

class _DropDownWidget extends StatefulWidget {
  final DropDownWidgetData data;
  final TypeRegistry typeRegistry;
  final Environment environment;

  const _DropDownWidget({
    required this.data,
    required this.typeRegistry,
    required this.environment,
  });

  @override
  State<_DropDownWidget> createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<_DropDownWidget> {
  Call? _cachedCall;
  String? _cachedBinding;
  List<dynamic>? _cachedList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final widgetContext = WidgetContextScope.of(context);
    final instance = widgetContext.instance;
    final binding = widget.data.databinding;

    // Only (re)compile if the binding expression changed
    if (binding != _cachedBinding) {
      _cachedBinding = binding;
      final type = TypeDescriptor.forType(instance.runtimeType);
      _cachedCall = ActionCompiler.instance.compile(binding!, context: type);
    }

    // Evaluate list if necessary
    if (_cachedCall != null) {
      _cachedList = _cachedCall!.eval(instance);
    }
  }

  DropdownMenuItem<dynamic> _createChild(dynamic item) {
    return DropdownMenuItem<dynamic>(
      value: item,
      child: WidgetContextScope(
        contextValue: WidgetContext(instance: item),
        child: DynamicWidget(
          model: widget.data.template,
          meta: widget.typeRegistry[widget.data.template.type],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _cachedList ?? const [];

    return SizedBox(
      width: double.infinity,
      child: DropdownButton<dynamic>(
        value: null, // TODO: connect to selection binding
        hint: const Text('Select'),
        items: list.map(_createChild).toList(growable: false),
        onChanged: (dynamic value) {
          // TODO: handle selection binding update
        },
      ),
    );
  }
}

@Injectable()
class DropDownEditWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  // constructor

  DropDownEditWidgetBuilder() : super(name: "dropdown", edit: true);

  // override

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
          width: double.infinity,
          child: DropdownButton<String>(
          value: "item",
          hint: const Text('Select an item'),
          items: <String>["item"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(), onChanged: (String? value) {  },
      )
      )
    );
  }
}