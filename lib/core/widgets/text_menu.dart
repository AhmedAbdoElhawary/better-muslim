import 'package:material_ui/material_ui.dart';

/// the fields' copy and paste menu, flutter's default but the ios one a frame late
class TextMenu extends StatefulWidget {
  const TextMenu(this.field, {super.key});

  final EditableTextState field;

  @override
  State<TextMenu> createState() => _TextMenuState();
}

class _TextMenuState extends State<TextMenu> {
  /// a parent scroll hides and shows the menu in one frame, the old ios menu is still up then
  /// and flutter asserts
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!SystemContextMenu.isSupportedByField(widget.field)) {
      return AdaptiveTextSelectionToolbar.editableText(editableTextState: widget.field);
    }
    return _ready
        ? SystemContextMenu.editableText(editableTextState: widget.field)
        : const SizedBox.shrink();
  }
}
