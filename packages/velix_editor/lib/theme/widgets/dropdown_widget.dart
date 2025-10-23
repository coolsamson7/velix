import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix/util/collections.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/actions/infer_types.dart';
import 'package:velix_ui/databinding/form_mapper.dart';
import 'package:velix_ui/databinding/valued_widget.dart';
import 'package:velix_ui/databinding/widgets/material/dropdown.dart';

import '../../actions/action_parser.dart';
import '../../actions/eval.dart';
import '../../commands/command_stack.dart';
import '../../commands/reparent_command.dart';
import '../../dynamic_widget.dart';
import '../../edit_widget.dart';
import '../../event/events.dart';
import '../../metadata/type_registry.dart';
import '../../metadata/widget_data.dart';
import '../../metadata/widgets/dropdown.dart';
import '../../metadata/widgets/for.dart';

import '../../util/message_bus.dart';
import '../../widget_container.dart';
import '../abstract_widget.dart';
import '../widget_builder.dart';
import 'for_widget.dart';

@Injectable()
class DropDownWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownWidgetBuilder({required this.typeRegistry}) : super(name: "dropdown");

  @override
  Widget create(DropDownWidgetData data, Environment environment, BuildContext context) {
    return _DropDownWidget(
      key: ValueKey(data.id),
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
    super.key,
    required this.data,
    required this.typeRegistry,
    required this.environment,
  });

  @override
  State<_DropDownWidget> createState() => _DropDownWidgetState();
}

typedef SelectCallback = void Function(dynamic selection);

@WidgetAdapter(platforms: [TargetPlatform.android])
@Injectable()
class DropDownStateAdapter extends AbstractValuedWidgetAdapter<_DropDownWidgetState> {
  // constructor

  DropDownStateAdapter() : super('dropdownx', [TargetPlatform.android]);

  // override

  @override
  Widget build({required BuildContext context, required FormMapper mapper, required TypeProperty property, required Keywords args}) {
    throw Exception("ocuh");
  }

  @override
  dynamic getValue(_DropDownWidgetState widget) {
    return widget._selectedValue;
  }

  @override
  void setValue(_DropDownWidgetState widget, dynamic value, ValuedWidgetContext context) {
    // noop
  }
}
//

class _DropDownWidgetState extends AbstractEditorWidgetState<_DropDownWidget> {
  dynamic _selectedValue;
  SelectCallback? _onSelect;

  // Form binding support
  late FormMapper _mapper;
  TypeProperty? _property;

  _DropDownWidgetState();

  // internal

  List<DropdownMenuItem<dynamic>> _buildItems(BuildContext context) {
    final items = <DropdownMenuItem<dynamic>>[];

    for (var childData in widget.data.children) {
      if (childData is ForWidgetData) {
        for (var (instance, item) in childData.expand(context, widget.typeRegistry, widget.environment)) {
          items.add(DropdownMenuItem(
            value: instance,
            child: item,
          ));
        }
      } else {
        items.add(DropdownMenuItem(
          value: childData,
          child: DynamicWidget(
            model: childData,
            meta: widget.typeRegistry[childData.type],
          ),
        ));
      }
    }

    return items;
  }

  RuntimeTypeInfo? getItemType() {
    var widgetContext = WidgetContextScope.of(context);
    var dropDown = widget.data;

    ForWidgetData forWidget = dropDown.children[0] as ForWidgetData;

    var binding = forWidget.context;
    if (binding.isNotEmpty) {
      var typeChecker = TypeChecker(RuntimeTypeTypeResolver(root: widgetContext.typeDescriptor));
      var parseResult = ActionParser.instance.parseStrict(binding, typeChecker: typeChecker);
      if (parseResult.success && parseResult.complete) {
        var type = parseResult.value!.type as RuntimeTypeInfo;
        return type;
      }
    }
    return null;
  }

  @override
  String extractId(Object widget) {
    return (this.widget.key as ValueKey<String>).value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final widgetContext = WidgetContextScope.of(context);
    _mapper = widgetContext.formMapper;

    Type type = dynamic;
    // ✅ databinding setup
    if (widget.data.databinding != null && widget.data.databinding!.isNotEmpty) {
      _property = _mapper.computeProperty(widgetContext.typeDescriptor, widget.data.databinding!);

      type = _property!.getType();
      _selectedValue = _mapper.getValue(_property!);
      _mapper.map(property: _property!, widget: this, adapter: widget.environment.get<DropDownStateAdapter>());
    }

    // ✅ dynamic onSelect handling
    if (widget.data.onSelect != null &&
        widget.data.onSelect!.isNotEmpty &&
        _onSelect == null) {
      var typeChecker = TypeChecker(RuntimeTypeTypeResolver(root: widgetContext.typeDescriptor, variables: {
        "value": type
      }));

      var result = ActionParser.instance.parseStrict(widget.data.onSelect!, typeChecker: typeChecker);
      var visitor = EvalVisitor(widgetContext.typeDescriptor);
      var call = result.value!.accept(visitor, CallVisitorContext(instance: null, contextVars: {
        "value": (name) => EvalContextVar(variable: name)
      }));

      _onSelect = (item) => call.eval(
        widgetContext.instance,
        EvalContext(instance: widgetContext.instance, variables: {"value": item}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<dynamic>(
      //key: ValueKey(data.id),
      value: _selectedValue,
      hint: const Text('Select'),
      items: _buildItems(context),
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
        });

        // ✅ Notify form mapper
        if (_property != null) {
          _mapper.notifyChange(property: _property!, value: value);
        }

        // ✅ Trigger onSelect callback
        if (_onSelect != null) {
          _onSelect!(value);
        }
      },
    );
  }
}

@Injectable()
class DropDownEditWidgetBuilder extends WidgetBuilder<DropDownWidgetData> {
  final TypeRegistry typeRegistry;

  DropDownEditWidgetBuilder({required this.typeRegistry})
      : super(name: "dropdown", edit: true);

  @override
  Widget create(
      DropDownWidgetData data, Environment environment, BuildContext context) {
    return DragTarget<WidgetData>(
      onWillAccept: (widget) => data.acceptsChild(widget!),
      onAccept: (widget) {
        environment.get<CommandStack>().execute(
          ReparentCommand(
            bus: environment.get<MessageBus>(),
            widget: widget,
            newParent: data,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) =>
            environment.get<MessageBus>().publish(
              "selection",
              SelectionEvent(selection: widget, source: this),
            ));
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        final hasChildren = data.children.isNotEmpty;

        final fakeSelectedChild =
        hasChildren ? EditWidget(model: data.children.first) : null;

        return Container(
          constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey.shade400,
              width: isActive ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isActive
                ? Colors.blue.shade50
                : Colors.grey.shade100.withOpacity(0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: fakeSelectedChild ??
                    Text(
                      isActive ? 'Drop option here' : 'Select an item',
                      style: TextStyle(
                        color: isActive
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        fontStyle: hasChildren
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}

