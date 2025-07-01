import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../appz_input_field_enums.dart';
import '../appz_style_config.dart';

class MobileInputWidget extends StatefulWidget {
  final AppzStateStyle currentStyle;
  final TextEditingController mainController; // For the 10-digit number part
  final FocusNode? mainFocusNode;
  final bool isEnabled;
  final String? hintText; // Hint for the number part
  final String countryCode; // e.g., "+91"
  final bool countryCodeEditable; // If true, country code is also an input
  final ValueChanged<String>? onChanged; // Called with full number "+91XXXXXXXXXX"
  final FormFieldValidator<String>? validator; // Validates the 10-digit number part primarily
  final AppzInputValidationType validationType;


  const MobileInputWidget({
    super.key,
    required this.currentStyle,
    required this.mainController,
    this.mainFocusNode,
    required this.isEnabled,
    this.hintText,
    this.countryCode = "+91",
    this.countryCodeEditable = false, // Default to fixed country code
    this.onChanged,
    this.validator,
    required this.validationType,
  });

  @override
  State<MobileInputWidget> createState() => _MobileInputWidgetState();
}

class _MobileInputWidgetState extends State<MobileInputWidget> {
  // If countryCodeEditable is true, we'd need a controller for it too.
  // For now, assuming fixed country code.

  @override
  Widget build(BuildContext context) {
    // Placeholder UI for Mobile input (Country Code + Number)
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.currentStyle.paddingHorizontal,
        vertical: widget.currentStyle.paddingVertical / 2, // Adjust padding for Row
      ),
      decoration: BoxDecoration(
        color: widget.currentStyle.backgroundColor,
        borderRadius: BorderRadius.circular(widget.currentStyle.borderRadius),
        border: Border.all(
          color: widget.currentStyle.borderColor,
          width: widget.currentStyle.borderWidth,
        ),
      ),
      child: Row(
        children: [
          // Country Code
          Padding(
            padding: EdgeInsets.only(right: widget.currentStyle.paddingHorizontal / 2),
            child: Text(
              widget.countryCode,
              style: TextStyle(
                color: widget.isEnabled ? widget.currentStyle.textColor : widget.currentStyle.textColor.withOpacity(0.5),
                fontFamily: widget.currentStyle.fontFamily,
                fontSize: widget.currentStyle.fontSize,
              ),
            ),
          ),
          // Number Input
          Expanded(
            child: Text(
              'Mobile Number Field Placeholder (10 digits)',
               style: TextStyle(color: widget.currentStyle.textColor.withOpacity(0.5))
            ), // Actual TextFormField will go here
          ),
        ],
      ),
    );
  }
}
