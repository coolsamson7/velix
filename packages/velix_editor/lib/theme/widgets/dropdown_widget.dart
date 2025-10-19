import 'package:flutter/material.dart' hide WidgetBuilder;
import 'package:velix/validation/validation.dart';
import 'package:velix_di/di/di.dart';
import 'package:velix_editor/actions/infer_types.dart';

import '../../actions/action_evaluator.dart';
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
import '../widget_builder.dart';
import 'for_widget.dart';

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

typedef SelectCallback = void Function(dynamic selection);

class _DropDownWidgetState extends State<_DropDownWidget> {
  // instance data

  dynamic _selectedValue;
  SelectCallback? _onSelect;

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
        // Static widget
        items.add(DropdownMenuItem(
          value: childData,
          child: DynamicWidget(
            model: childData,
            meta: widget.typeRegistry[childData.type],
          ),
        ));
      }
    } // for

    return items;
  }

  RuntimeTypeInfo? getItemType() {
    var widgetContext = WidgetContextScope.of(context);

    var dropDown = widget.data;

    ForWidgetData forWidget = dropDown.children[0] as ForWidgetData;

    var binding = forWidget.context;

    if ( binding.isNotEmpty) {
      var typeChecker = TypeChecker(RuntimeTypeTypeResolver(root: widgetContext.typeDescriptor));
      var parseResult = ActionParser.instance.parseStrict(binding, typeChecker: typeChecker);

      if ( parseResult.success && parseResult.complete) {
        var type = parseResult.value!.type as RuntimeTypeInfo;

        return type; // TODO missing elementTyoe parameter. fuck it
      }
    } // if


    return null;
  }

 /* void _prepareVariables() {
    var widgetContext = WidgetContextScope.of(context);

    var dropDown = widget.data;

    var itemType = getItemType();

    var typeChecker = TypeChecker(RuntimeTypeTypeResolver(root: widgetContext.typeDescriptor, variables: variables);
    var parseResult = ActionParser.instance.parseStrict(dropDown.onSelect, typeChecker: typeChecker);

    if ( parseResult.success && parseResult.complete) {
      var type = parseResult.value!.getType<RuntimeTypeInfo>();
    }
  }*/

  // override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only compile once per lifecycle if onClick is set
    if (widget.data.onSelect != null && widget.data.onSelect!.isNotEmpty && _onSelect == null) {
      var widgetContext = WidgetContextScope.of(context);

      var itemType = getItemType(); // do we actually need it? we are sure that the validation was ok, so maybe dynamic is sufficient?

      print(itemType);


      var typeChecker = TypeChecker(RuntimeTypeTypeResolver(root: widgetContext.typeDescriptor, variables: {
        "value": dynamic // HMMM???
      }));


      var result = ActionParser.instance.parseStrict(widget.data.onSelect!, typeChecker: typeChecker);

      var visitor = EvalVisitor(widgetContext.typeDescriptor);

      var call = result.value!.accept(visitor, CallVisitorContext(instance: null, contextVars: {
        "value": (name) => EvalContextVar(variable: name)
      }));

      //final call = ActionCompiler.instance.compile(widget.data.onSelect!, context: widgetContext.typeDescriptor);
      _onSelect = (item) => call.eval(widgetContext.instance, EvalContext(instance: widgetContext.instance, variables: {
        "value": item
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<dynamic>(
      value: _selectedValue,
      hint: const Text('Select'),
      items: _buildItems(context),
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
          if (_onSelect != null)
            _onSelect!(value);
        });
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

