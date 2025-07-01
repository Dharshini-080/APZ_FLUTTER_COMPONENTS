import 'package:flutter/material.dart';
import '../appz_input_field_enums.dart';
import '../appz_style_config.dart';

class MpinInputWidget extends StatefulWidget {
  final AppzStateStyle currentStyle;
  final TextEditingController mainController; // For the combined MPIN
  final bool isEnabled;
  final bool obscureText;
  final int mpinLength;
  final ValueChanged<String>? onChanged; // Called with combined mpin string
  final FormFieldValidator<String>? validator; // Validates combined mpin string
  final AppzInputValidationType validationType;


  const MpinInputWidget({
    super.key,
    required this.currentStyle,
    required this.mainController,
    required this.isEnabled,
    required this.obscureText,
    required this.mpinLength,
    this.onChanged,
    this.validator,
    required this.validationType,
  });

  @override
  State<MpinInputWidget> createState() => _MpinInputWidgetState();
}

class _MpinInputWidgetState extends State<MpinInputWidget> {
  late List<TextEditingController> _segmentControllers;
  late List<FocusNode> _segmentFocusNodes;

  @override
  void initState() {
    super.initState();
    _initializeSegments();
  }

  void _initializeSegments() {
    _segmentControllers = List.generate(
      widget.mpinLength,
      (index) => TextEditingController(),
    );
    _segmentFocusNodes = List.generate(
      widget.mpinLength,
      (index) => FocusNode(),
    );

    for (int i = 0; i < widget.mpinLength; i++) {
      _segmentControllers[i].addListener(() => _onSegmentChanged(i));
      // TODO: Add RawKeyboardListener or similar for better backspace handling if needed
    }
  }

  void _disposeSegments() {
    for (var controller in _segmentControllers) {
      controller.dispose();
    }
    for (var focusNode in _segmentFocusNodes) {
      focusNode.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant MpinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mpinLength != oldWidget.mpinLength) {
      _disposeSegments();
      _initializeSegments();
    }
    // TODO: Handle external changes like isEnabled if needed, though AppzInputField might just rebuild it.
  }


  void _onSegmentChanged(int segmentIndex) {
    final currentValue = _segmentControllers[segmentIndex].text;

    // Update main controller
    String combinedValue = _segmentControllers.map((c) => c.text).join();
    if (widget.mainController.text != combinedValue) {
      widget.mainController.text = combinedValue;
      widget.onChanged?.call(combinedValue);
    }

    if (!widget.isEnabled) return;

    // Auto-focus next field
    if (currentValue.isNotEmpty && segmentIndex < widget.mpinLength - 1) {
      FocusScope.of(context).requestFocus(_segmentFocusNodes[segmentIndex + 1]);
    }
    // Backspace logic will be enhanced in the build method's TextFormField onChanged
  }

  @override
  void dispose() {
    _disposeSegments();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder - actual segment UI will be built here
    // This will be a Row of small TextFormFields
    return Container(
       padding: EdgeInsets.symmetric(
        horizontal: widget.currentStyle.paddingHorizontal,
        vertical: widget.currentStyle.paddingVertical
      ),
      decoration: BoxDecoration(
        // This container might not need its own border if segments are individually bordered
        // Or it could provide an outer unified border
        borderRadius: BorderRadius.circular(widget.currentStyle.borderRadius),
        // border: Border.all(color: Colors.transparent), // Example: transparent outer border
      ),
      child: Center(child: Text('MPIN Input Widget Placeholder (${widget.mpinLength} segments)')),
    );
  }
}
