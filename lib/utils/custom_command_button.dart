import 'package:fluent_ui/fluent_ui.dart';

class CustomCommandBarButton extends CommandBarButton {
  final bool isPressed;

  const CustomCommandBarButton(
      {super.key,
      super.icon,
      super.label,
      super.subtitle,
      super.trailing,
      required super.onPressed,
      super.onLongPress,
      super.focusNode,
      super.autofocus = false,
      this.isPressed = false});

  @override
  Widget build(BuildContext context, CommandBarItemDisplayMode displayMode) {
    assert(debugCheckHasFluentTheme(context));
    return IconButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      style: ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          final theme = FluentTheme.of(context);
          if (isPressed) {
            return Colors.grey[30];
          } else {
            return ButtonThemeData.uncheckedInputColor(
              theme,
              states,
              transparentWhenNone: true,
            );
          }
        }),
      ),
      icon: Row(mainAxisSize: MainAxisSize.min, children: [
        IconTheme.merge(
          data: const IconThemeData(size: 16),
          child: icon!,
        ),
        const SizedBox(width: 10),
        label!,
      ]),
    );
  }
}
