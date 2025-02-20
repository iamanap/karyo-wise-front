import 'package:fluent_ui/fluent_ui.dart' as fluent_ui hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:karyo_wise/data/model/chromosome_model.dart';
import 'package:karyo_wise/data/model/metaphase_model.dart';
import 'package:karyo_wise/utils/custom_command_button.dart';
import 'package:karyo_wise/widgets/karyotype_widget.dart';
import 'package:karyo_wise/widgets/polygon_annotation_widget.dart';
import 'package:karyo_wise/constants.dart';

class AnnotationPage extends StatefulWidget {
  final Metaphase? metaphase;
  const AnnotationPage({super.key, required this.metaphase});

  @override
  State<StatefulWidget> createState() => _AnnotationPageState();
}

class _AnnotationPageState extends State<AnnotationPage> {
  late bool _isRightColumnVisible;
  late Map<String, bool> _buttonStates;
  final ValueNotifier<List<Chromosome>> _finalChromosomes = ValueNotifier([]);

  @override
  void initState() {
    _isRightColumnVisible = true;
    initButtonStates();
    _buttonStates['drag'] = true;
    super.initState();
  }

  void initButtonStates() {
    _buttonStates = {
      'drag': false,
      'polygon': false,
      'undo': false,
      'redo': false,
    };
  }

  void _updateButtonState(String key) {
    setState(() {
      initButtonStates();
      _buttonStates[key] = !_buttonStates[key]!;
    });
  }

  void _setFinalChromosomesList(List<Chromosome>? finalChromosomes) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (finalChromosomes != null) {
        _finalChromosomes.value = finalChromosomes;
      }
    });
  }

//   WidgetsBinding.instance!.addPostFrameCallback((_) {
//   _setFinalChromosomesList(updatedChromosomes);
// });

  @override
  Widget build(BuildContext context) {
    List<fluent_ui.CommandBarItem> startCommandBarItems =
        <fluent_ui.CommandBarItem>[
      fluent_ui.CommandBarBuilderItem(
        builder: (context, mode, w) => Tooltip(
          message: "Pan the image or select / reposition annotations.",
          child: w,
        ),
        wrappedItem: CustomCommandBarButton(
          icon: const Icon(FluentIcons.drag_20_regular, size: 20),
          label: const Text('Drag'),
          isPressed: _buttonStates['drag']!,
          onPressed: () {
            _updateButtonState('drag');
          },
        ),
      ),
      fluent_ui.CommandBarBuilderItem(
        builder: (context, mode, w) => Tooltip(
          message: "Freeform draw annotations for more precise shapes.",
          child: w,
        ),
        wrappedItem: CustomCommandBarButton(
          icon: const Icon(FluentIcons.draw_shape_20_regular, size: 20),
          label: const Text('Polygon'),
          isPressed: _buttonStates['polygon']!,
          onPressed: () {
            _updateButtonState('polygon');
          },
        ),
      ),
      // fluent_ui.CommandBarBuilderItem(
      //   builder: (context, mode, w) => Tooltip(
      //     message:
      //         "Use an intelligent assistant to draw your polygons. Click on the center of your object, then keep clicking to add or subtract areas.",
      //     child: w,
      //   ),
      //   wrappedItem: CustomCommandBarButton(
      //     icon: SvgPicture.asset('assets/images/icons/ai_annotation_icon.svg',
      //         height: 18.0),
      //     label: const Text('Smart Polygon'),
      //     isPressed: _buttonStates['smartPolygon']!,
      //     onPressed: () {
      //       _updateButtonState('smartPolygon');
      //     },
      //   ),
      // ),
      fluent_ui.CommandBarBuilderItem(
        builder: (context, mode, w) => Tooltip(
          message: "Undo the previous action.",
          child: w,
        ),
        wrappedItem: CustomCommandBarButton(
          icon: const Icon(FluentIcons.arrow_undo_20_regular, size: 20),
          label: const Text('Undo'),
          isPressed: false,
          onPressed: () {},
        ),
      ),
      fluent_ui.CommandBarBuilderItem(
        builder: (context, mode, w) => Tooltip(
          message: "Redo the previous action.",
          child: w,
        ),
        wrappedItem: CustomCommandBarButton(
          icon: const Icon(FluentIcons.arrow_redo_20_regular, size: 20),
          label: const Text('Redo'),
          isPressed: false,
          onPressed: () {},
        ),
      ),
      // fluent_ui.CommandBarBuilderItem(
      //   builder: (context, mode, w) => Tooltip(
      //     message: "Hide / show side bar",
      //     child: w,
      //   ),
      //   wrappedItem: fluent_ui.CommandBarButton(
      //     icon: const Icon(FluentIcons.column_triple_20_regular, size: 20),
      //     label: const Text('Hide / show side bar'),
      //     onPressed: () {
      //       _toggleRightColumn();
      //       _updateButtonState('hideShow');
      //     },
      //   ),
      // )
    ];

    Widget mainContent = Row(children: [
      Expanded(
          child: Card(
              margin: EdgeInsets.only(
                  left: 20,
                  top: 20,
                  bottom: 20,
                  right: _isRightColumnVisible ? 5 : 20),
              clipBehavior: Clip.antiAlias,
              child: Container(
                  color: Colors.white,
                  child: Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: PolygonAnnotationWidget(
                            drag: _buttonStates['drag']!,
                            metaphase: widget.metaphase,
                            manualPolygon: _buttonStates['polygon']!,
                            finalChromosomesAction: _setFinalChromosomesList,
                          )))))),
      Visibility(
          visible: _isRightColumnVisible, //Default is true,
          child: Expanded(
              child: Padding(
            padding:
                const EdgeInsets.only(left: 5, top: 20, bottom: 5, right: 20),
            child: KaryotypeWidget(
              finalChromosomesNotifier: _finalChromosomes,
              metaphase: widget.metaphase,
            ),
          )))
    ]);

    return widget.metaphase == null
        ? const SizedBox.shrink()
        : fluent_ui.ScaffoldPage(
            padding: EdgeInsets.zero,
            header: fluent_ui.CommandBarCard(
                child: fluent_ui.CommandBar(
                    overflowBehavior: fluent_ui.CommandBarOverflowBehavior.clip,
                    primaryItems: startCommandBarItems)),
            content: mainContent);
  }
}
