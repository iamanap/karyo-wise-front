import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/material.dart';

class ClassOverlayWidget extends StatefulWidget {
  final ValueChanged<int> onDeletePressed;
  final ValueChanged<int> onSavePressed;
  final int classIndex;
  const ClassOverlayWidget(
      {super.key,
      required this.onDeletePressed,
      required this.onSavePressed,
      required this.classIndex});

  @override
  ClassOverlayWidgetState createState() => ClassOverlayWidgetState();
}

class ClassOverlayWidgetState extends State<ClassOverlayWidget> {
  int _classIndex = 1;
  late List<fluent_ui.MenuFlyoutItem> items;

  @override
  void initState() {
    super.initState();

    items = List.generate(24, (index) {
      var text =
          switch (index) { 22 => 'X', 23 => 'Y', _ => (index + 1).toString() };
      return fluent_ui.MenuFlyoutItem(
        text: Text(text),
        onPressed: () => _onDropdownItemPressed(index),
      );
    });
    _classIndex = widget.classIndex;
  }

  void _onDropdownItemPressed(index) {
    setState(() {
      _classIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
              color: fluent_ui.FluentTheme.of(context).micaBackgroundColor,
              margin: const EdgeInsets.only(top: 20, right: 20, bottom: 10),
              child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: fluent_ui.DropDownButton(
                            placement:
                                fluent_ui.FlyoutPlacementMode.bottomCenter,
                            title: Text(switch (_classIndex) {
                              22 => 'X',
                              23 => 'Y',
                              _ => (_classIndex + 1).toString()
                            }),
                            items: items,
                          )),
                      Row(
                        children: [
                          fluent_ui.FilledButton(
                            onPressed: () =>
                                widget.onDeletePressed(_classIndex),
                            style: fluent_ui.ButtonStyle(
                                backgroundColor: fluent_ui.ButtonState.all(
                                    fluent_ui.Colors.red.lightest)),
                            child: const Text('Delete'),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: fluent_ui.FilledButton(
                                child: const Text('Save'),
                                onPressed: () =>
                                    widget.onSavePressed(_classIndex),
                              ))
                        ],
                      )
                    ],
                  )))
        ]);
  }
}
