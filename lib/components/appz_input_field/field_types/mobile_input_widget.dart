import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../appz_input_field_enums.dart';
import '../appz_style_config.dart';

class MobileInputWidget extends StatefulWidget {
  final AppzStateStyle currentStyle;
  final TextEditingController mainController; // Will store the full "+91XXXXXXXXXX"
  final FocusNode? mainFocusNode; // Focus for the number input part
  final bool isEnabled;
  final String? hintText; // Hint for the number part
  final String countryCode;
  final bool countryCodeEditable; // Future: for editable country code
  final ValueChanged<String>? onChanged; // Called with full number "+91XXXXXXXXXX"
  final FormFieldValidator<String>? validator; // Validates the 10-digit number part
  final AppzInputValidationType validationType;

  const MobileInputWidget({
    super.key,
    required this.currentStyle,
    required this.mainController, // This controller is now for the full number
    this.mainFocusNode,
    required this.isEnabled,
    this.hintText,
    this.countryCode = "+91",
    this.countryCodeEditable = false,
    this.onChanged,
    this.validator,
    required this.validationType,
  });

  @override
  State<MobileInputWidget> createState() => _MobileInputWidgetState();
}

class _MobileInputWidgetState extends State<MobileInputWidget> {
  late TextEditingController _numberController;
  String _currentCountryCode = "";

  @override
  void initState() {
    super.initState();
    _currentCountryCode = widget.countryCode;
    _numberController = TextEditingController();
    _initializeNumberFromMainController();
    _numberController.addListener(_onNumberChanged);

    // Listen to main controller for external programmatic changes
    widget.mainController.addListener(_onMainControllerChanged);
  }

  void _initializeNumberFromMainController() {
    final fullText = widget.mainController.text;
    if (fullText.startsWith(_currentCountryCode)) {
      final numberPart = fullText.substring(_currentCountryCode.length);
      if (_numberController.text != numberPart) {
        _numberController.value = TextEditingValue(
          text: numberPart,
          selection: TextSelection.collapsed(offset: numberPart.length),
        );
      }
    } else if (fullText.isNotEmpty && _currentCountryCode.isNotEmpty && !fullText.startsWith(_currentCountryCode)) {
      // If main controller has text that doesn't start with current country code,
      // assume it's just the number part (e.g. initialValue was just number)
       if (_numberController.text != fullText) {
        _numberController.value = TextEditingValue(
          text: fullText, // Assume it's the number part
          selection: TextSelection.collapsed(offset: fullText.length),
        );
         // Immediately update main controller to include country code
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateMainController();
        });
      }
    } else {
        if (_numberController.text.isNotEmpty) _numberController.clear();
    }
  }

  void _onMainControllerChanged() {
    // If main controller changes externally, reflect it in the number part
    // This prevents an infinite loop with _onNumberChanged
    final fullText = widget.mainController.text;
    String numberPart = "";
    if (fullText.startsWith(_currentCountryCode)) {
      numberPart = fullText.substring(_currentCountryCode.length);
    } else if (fullText.isNotEmpty && _currentCountryCode.isNotEmpty && !fullText.startsWith(_currentCountryCode)){
      // If it was set externally without country code, assume it's the number part
      numberPart = fullText;
      // It's tricky to auto-prefix here without knowing user intent / cursor.
      // For now, this listener primarily updates number part if main controller has valid full number.
    }

    if (_numberController.text != numberPart) {
      // Temporarily remove listener to prevent loop when setting text
      _numberController.removeListener(_onNumberChanged);
      _numberController.value = TextEditingValue(
        text: numberPart,
        selection: TextSelection.collapsed(offset: numberPart.length),
      );
      _numberController.addListener(_onNumberChanged);
    }
  }


  void _onNumberChanged() {
    _updateMainController();
  }

  void _updateMainController() {
    final String fullMobileNumber = _currentCountryCode + _numberController.text;
    if (widget.mainController.text != fullMobileNumber) {
      widget.mainController.value = TextEditingValue(
        text: fullMobileNumber,
        selection: TextSelection.collapsed(offset: fullMobileNumber.length),
      );
      // The AppzInputField's own listener on _internalController (widget.mainController here)
      // will call widget.onChanged from AppzInputField.
      // So, no need to call widget.onChanged directly from here if AppzInputField handles it.
      // However, the plan was for AppzInputField.onChanged to provide the full number.
      // Let's ensure AppzInputField's onChanged is correctly called.
      // The parent AppzInputField's _handleTextChange is already wired to its _internalController.
      // So, updating widget.mainController.text here WILL trigger the parent's onChanged.
    }
  }

  @override
  void didUpdateWidget(covariant MobileInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mainController != oldWidget.mainController) {
      oldWidget.mainController.removeListener(_onMainControllerChanged);
      widget.mainController.addListener(_onMainControllerChanged);
      _initializeNumberFromMainController(); // Update with new main controller value
    }
    if (widget.countryCode != oldWidget.countryCode) {
        _currentCountryCode = widget.countryCode;
        _updateMainController(); // Re-construct full number with new country code
    }
    // isEnabled and currentStyle changes are handled by parent rebuild
  }

  @override
  void dispose() {
    widget.mainController.removeListener(_onMainControllerChanged);
    _numberController.removeListener(_onNumberChanged);
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppzStateStyle style = widget.currentStyle;

    // This is the decoration for the number input part, should be borderless
    final numberInputDecoration = InputDecoration(
      hintText: widget.hintText ?? '00000 00000',
      hintStyle: TextStyle(
        color: style.textColor.withOpacity(0.5),
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
      ),
      border: InputBorder.none, // No border for the inner field
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero, // No extra padding inside the number field part
      isDense: true, // Make it compact
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: style.paddingHorizontal,
        vertical: style.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: widget.isEnabled ? style.backgroundColor : style.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically in the Row
        children: [
          // Country Code
          // TODO: Make country code part focusable/tappable if editable
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // Spacing after country code
            child: Text(
              _currentCountryCode,
              style: TextStyle(
                color: widget.isEnabled ? style.textColor : style.textColor.withOpacity(0.5),
                fontFamily: style.fontFamily,
                fontSize: style.fontSize,
              ),
            ),
          ),
          // Number Input
          Expanded(
            child: TextFormField(
              controller: _numberController,
              focusNode: widget.mainFocusNode,
              enabled: widget.isEnabled,
              style: TextStyle(
                color: widget.isEnabled ? style.textColor : style.textColor.withOpacity(0.5),
                fontFamily: style.fontFamily,
                fontSize: style.fontSize,
              ),
              decoration: numberInputDecoration,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: widget.validator, // This validator is for the 10-digit number part
              // onChanged is handled by the controller listener (_onNumberChanged)
              // onFieldSubmitted can be passed from parent if needed
            ),
          ),
        ],
      ),
    );
  }
}
