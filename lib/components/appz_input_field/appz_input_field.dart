import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'appz_input_field_enums.dart';
import 'appz_style_config.dart';
import 'formatters/aadhaar_input_formatter.dart';
// Import sub-widgets
import 'field_types/aadhaar_input_widget.dart';
import 'field_types/mpin_input_widget.dart';
import 'field_types/mobile_input_widget.dart';

/// A versatile and themeable input field widget driven by JSON configuration.
class AppzInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final AppzFieldType fieldType;
  final AppzFieldState initialFieldState; // Can be used to force a state externally
  final String? initialValue; // Used if controller is not provided
  final AppzInputValidationType validationType; // Re-adding this parameter

  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  final bool obscureText;
  final TextInputAction? textInputAction;
  final int? maxLength; // Used by defaultType
  final int mpinLength; // Specific to mpinFieldType
  final String mobileCountryCode; // Specific to mobileFieldType
  final bool mobileCountryCodeEditable; // Specific to mobileFieldType

  // Add other common TextFormField properties as needed:
  // final bool readOnly;
  // final InputDecoration? decoration; // We build this internally mostly

  const AppzInputField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.fieldType = AppzFieldType.defaultType,
    this.initialFieldState = AppzFieldState.defaultState,
    this.initialValue,
    this.validationType = AppzInputValidationType.none, // Initialize in constructor
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.maxLength,
    this.mpinLength = 4, // Default mpinLength to 4
    this.mobileCountryCode = "+91", // Default country code
    this.mobileCountryCodeEditable = false, // Default to not editable
    // this.readOnly = false,
  });

  @override
  State<AppzInputField> createState() => _AppzInputFieldState();
}

class _AppzInputFieldState extends State<AppzInputField> {
  late final TextEditingController _internalController;
  late final FocusNode _internalFocusNode;

  AppzFieldState _currentFieldState = AppzFieldState.defaultState;
  String? _validationErrorMessage; // From internal or external validator

  // MPIN specific state
  late List<TextEditingController> _mpinSegmentControllers;
  late List<FocusNode> _mpinSegmentFocusNodes;

  bool get _isEffectivelyDisabled => _currentFieldState == AppzFieldState.disabled;
  bool get _hasError => _currentFieldState == AppzFieldState.error;
  bool get _isFocused => _currentFieldState == AppzFieldState.focused;
  bool get _isFilled => _currentFieldState == AppzFieldState.filled || _internalController.text.isNotEmpty;


  @override
  void initState() {
    super.initState();

    _internalController = widget.controller ?? TextEditingController(text: widget.initialValue);
    _internalFocusNode = widget.focusNode ?? FocusNode();

    _currentFieldState = widget.initialFieldState;

    // Add listeners to update state
    _internalFocusNode.addListener(_handleFocusChange);
    _internalController.addListener(_handleTextChange);

    // Initial check for filled state if there's initial text or state
    _updateFilledState();
    if (widget.initialFieldState == AppzFieldState.disabled) {
        _currentFieldState = AppzFieldState.disabled;
    }

    _initializeMpinFields();
  }

  void _initializeMpinFields() {
    if (widget.fieldType == AppzFieldType.mpin) {
      _mpinSegmentControllers = List.generate(
        widget.mpinLength,
        (index) => TextEditingController(),
      );
      _mpinSegmentFocusNodes = List.generate(
        widget.mpinLength,
        (index) => FocusNode(),
      );
      // Add listeners to MPIN segment controllers for focus and value aggregation
      for (int i = 0; i < widget.mpinLength; i++) {
        _mpinSegmentControllers[i].addListener(() => _onMpinSegmentChanged(i));
        // We might need to add focus listeners to segments too for backspace logic
      }
    } else {
      // Ensure lists are empty or null if not MPIN type to avoid issues.
      // Or handle this by only accessing them if fieldType is mpin.
      _mpinSegmentControllers = [];
      _mpinSegmentFocusNodes = [];
    }
  }

  void _disposeMpinFields() {
    if (widget.fieldType == AppzFieldType.mpin || _mpinSegmentControllers.isNotEmpty) { // check _mpinSegmentControllers for safety during hot reload if type changes
      for (var controller in _mpinSegmentControllers) {
        controller.dispose();
      }
      for (var focusNode in _mpinSegmentFocusNodes) {
        focusNode.dispose();
      }
    }
  }

  // This will be called by individual mpin segment listeners
  void _onMpinSegmentChanged(int segmentIndex) {
    // Logic to handle focus change and aggregate value
    // This will be fleshed out more later.

    // Update the main controller
    final mpinValue = _mpinSegmentControllers.map((c) => c.text).join();
    if (_internalController.text != mpinValue) {
      _internalController.text = mpinValue; // This will trigger its own listeners (like _handleTextChange)
    }

    // Auto-focus next field
    if (segmentIndex < widget.mpinLength - 1 && _mpinSegmentControllers[segmentIndex].text.isNotEmpty) {
      FocusScope.of(context).requestFocus(_mpinSegmentFocusNodes[segmentIndex + 1]);
    }
  }


  @override
  void didUpdateWidget(covariant AppzInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _internalController.removeListener(_handleTextChange);
      _internalController = widget.controller ?? TextEditingController(text: widget.initialValue ?? _internalController.text);
      _internalController.addListener(_handleTextChange);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _internalFocusNode.removeListener(_handleFocusChange);
      _internalFocusNode = widget.focusNode ?? FocusNode();
      _internalFocusNode.addListener(_handleFocusChange);
    }
    if (widget.initialFieldState != oldWidget.initialFieldState && widget.initialFieldState != _currentFieldState) {
        if(widget.initialFieldState == AppzFieldState.disabled || widget.initialFieldState == AppzFieldState.error) {
            _updateState(widget.initialFieldState);
        }
    }
    if (widget.initialValue != oldWidget.initialValue && widget.controller == null) {
      _internalController.text = widget.initialValue ?? '';
    }

    // Re-initialize MPIN fields if fieldType or mpinLength changes
    if (widget.fieldType == AppzFieldType.mpin &&
        (oldWidget.fieldType != AppzFieldType.mpin || widget.mpinLength != oldWidget.mpinLength)) {
      _disposeMpinFields(); // Dispose old ones first
      _initializeMpinFields();
    } else if (widget.fieldType != AppzFieldType.mpin && oldWidget.fieldType == AppzFieldType.mpin) {
      _disposeMpinFields(); // Clean up if switched away from MPIN
       // Ensure lists are empty if not MPIN type
      _mpinSegmentControllers = [];
      _mpinSegmentFocusNodes = [];
    }
  }


  void _handleFocusChange() {
    if (_isEffectivelyDisabled) return; // Don't change focus state if disabled

    if (_internalFocusNode.hasFocus) {
      _updateState(AppzFieldState.focused);
    } else {
      // When losing focus, if not error, determine if it's filled or default
      if (!_hasError) {
        _updateState(_internalController.text.isNotEmpty ? AppzFieldState.filled : AppzFieldState.defaultState);
      }
      // If it has an error, it should remain in error state on blur
    }
  }

  void _handleTextChange() {
    if (_isEffectivelyDisabled) return;

    // Call external onChanged if provided
    widget.onChanged?.call(_internalController.text);

    _updateFilledState();
  }

  void _updateFilledState() {
    if (_isEffectivelyDisabled || _isFocused || _hasError) {
        // Don't change to 'filled' if it's focused, has an error, or is disabled.
        // These states take precedence.
        // However, if it becomes empty while focused/error, it might revert to that state's "empty" look.
        // The 'filled' state is more about the look when it's NOT focused and NOT error.
        // We also need to ensure that if it was 'filled' and text is deleted, it goes back to 'default' (if not focused/error).
         if (!_isFocused && !_hasError && _internalController.text.isEmpty && _currentFieldState == AppzFieldState.filled) {
            _updateState(AppzFieldState.defaultState);
        }
        return;
    }

    final bool hasText = _internalController.text.isNotEmpty;
    if (hasText && _currentFieldState != AppzFieldState.filled) {
      _updateState(AppzFieldState.filled);
    } else if (!hasText && _currentFieldState == AppzFieldState.filled) {
      _updateState(AppzFieldState.defaultState);
    }
  }

  // Public method to update state if needed (e.g., after validation)
  void _updateState(AppzFieldState newState, {String? errorMessage}) {
    if (_currentFieldState != newState || _validationErrorMessage != errorMessage) {
      if (mounted) {
        setState(() {
          _currentFieldState = newState;
          if (errorMessage != null || newState != AppzFieldState.error) {
            // Clear error if new state is not error, or set new error message
            _validationErrorMessage = (newState == AppzFieldState.error) ? errorMessage : null;
          }
        });
      }
    }
  }

  String? _performValidation(String? value) { // value is _internalController.text
    _validationErrorMessage = null;
  String? _performValidation(String? value) { // value is _internalController.text
    _validationErrorMessage = null;
    String? valueToPassToExternalValidator = value; // For default, aadhaar, mpin (validator expects full value)
    String? valueForBuiltInChecks = value;         // For default, aadhaar, mpin

    // 1. Prepare values for mobile type
    if (widget.fieldType == AppzFieldType.mobile) {
      String currentCountryDialCode = widget.mobileCountryCode; // Default
      String numberPart = "";

      if (value != null && value.startsWith("+")) {
        // Attempt to find the dynamic prefix from the full value
        bool foundPrefix = false;
        for (var country in CountryCodesHelper.getCountries()) { // Assumes CountryCodesHelper is accessible
          if (value.startsWith(country.displayDialCode)) {
            currentCountryDialCode = country.displayDialCode;
            numberPart = value.substring(currentCountryDialCode.length);
            foundPrefix = true;
            break;
          }
        }
        if (!foundPrefix) {
          // If no known prefix matches, but it starts with "+", it's ambiguous.
          // For validation, we might assume the number part is after the first non-digit, or treat as invalid.
          // Or, more simply, pass the full value to user's validator and let them parse.
          // For now, if prefix not in known list, treat numberPart as potentially empty or invalid for built-in checks.
          // And pass the original 'value' to user's validator.
          numberPart = value; // Or try to extract digits after '+'
        }
      } else if (value != null) { // No "+" prefix, assume it's all number part
        numberPart = value;
      }

      valueToPassToExternalValidator = numberPart; // User's validator for mobile gets only the number part
      valueForBuiltInChecks = numberPart;
    }

    // 2. Call the user-provided validator (if any)
    // For mobile, it gets the number part. For others, it gets the full value from _internalController.
    // For Aadhaar/MPIN, this `widget.validator` is the one composed in the build method.
    if (widget.validator != null) {
      _validationErrorMessage = widget.validator!(valueToPassToExternalValidator);
    }

    // 3. If no error from widget.validator (or if it was null),
    //    apply built-in AppzInputValidationType checks.
    if (_validationErrorMessage == null) {
      final String currentValForBuiltIn = valueForBuiltInChecks ?? "";

      if (widget.validationType == AppzInputValidationType.mandatory && currentValForBuiltIn.isEmpty) {
        // For mobile, this checks if the number part is empty.
        // For others, it checks if the full value is empty.
        _validationErrorMessage = 'This field is required.'; // TODO: Localize
      }

      if (_validationErrorMessage == null) { // Check again after mandatory
        switch (widget.fieldType) {
          case AppzFieldType.defaultType:
            if (widget.validationType == AppzInputValidationType.email && currentValForBuiltIn.isNotEmpty) {
              final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(currentValForBuiltIn)) {
                _validationErrorMessage = 'Enter a valid email address.'; // TODO: Localize
              }
            } else if (widget.validationType == AppzInputValidationType.numeric && currentValForBuiltIn.isNotEmpty) {
              if (double.tryParse(currentValForBuiltIn) == null) {
                _validationErrorMessage = 'Enter a valid number.'; // TODO: Localize
              }
            }
            break;
          case AppzFieldType.mobile:
            if (currentValForBuiltIn.isNotEmpty && currentValForBuiltIn.length != 10) {
              _validationErrorMessage = 'Mobile number must be 10 digits.'; // TODO: Localize
            }
            break;
          case AppzFieldType.aadhaar:
             final unformattedAadhaar = currentValForBuiltIn.replaceAll(' ', ''); // valueForBuiltInChecks is full aadhaar
            if (unformattedAadhaar.isNotEmpty && unformattedAadhaar.length != 12) {
               _validationErrorMessage = 'Aadhaar number must be 12 digits.'; // TODO: Localize
            }
            break;
          case AppzFieldType.mpin:
            if (currentValForBuiltIn.isNotEmpty && currentValForBuiltIn.length != widget.mpinLength) {
              _validationErrorMessage = 'MPIN must be ${widget.mpinLength} digits.'; // TODO: Localize
            }
            break;
          default:
            break;
        }
      }
    }

    // Update state based on validation result
    if (_validationErrorMessage != null) {
      _updateState(AppzFieldState.error, errorMessage: _validationErrorMessage);
    } else if (!_isFocused) {
      _updateState(_internalController.text.isNotEmpty ? AppzFieldState.filled : AppzFieldState.defaultState);
    } else if (_isFocused) {
      _updateState(AppzFieldState.focused);
    }
    return _validationErrorMessage;
  }


  @override
  void dispose() {
    _internalFocusNode.removeListener(_handleFocusChange);
    _internalController.removeListener(_handleTextChange);

    // Only dispose if they were created internally
    if (widget.controller == null) {
      _internalController.dispose();
    }
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    _disposeMpinFields(); // Dispose MPIN fields
    super.dispose();
  }

  @override
  InputDecoration _createBaseInputDecoration(AppzStateStyle style) {
    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(
        color: style.textColor.withOpacity(0.5),
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
      ),
      filled: true,
      fillColor: style.backgroundColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: style.paddingHorizontal,
        vertical: style.paddingVertical,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        borderSide: BorderSide(color: style.borderColor, width: style.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        borderSide: BorderSide(color: style.borderColor, width: style.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        borderSide: BorderSide(
          color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.focused, isFilled: _isFilled).borderColor,
          width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.focused, isFilled: _isFilled).borderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        borderSide: BorderSide(
          color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).borderColor,
          width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).borderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        borderSide: BorderSide(
          color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).borderColor,
          width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).borderWidth + 0.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        borderSide: BorderSide(
          color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.disabled, isFilled: _isFilled).borderColor,
          width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.disabled, isFilled: _isFilled).borderWidth,
        ),
      ),
      // prefixIcon and suffixIcon can be added via .copyWith() if needed by specific types
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is where the UI rendering based on widget.fieldType will happen.
    // Styling will be fetched from AppzStyleConfig.instance using _currentFieldState and _isFilled.

    if (!AppzStyleConfig.instance.isInitialized) {
      // Styles not loaded, show a basic placeholder or loading state
      return const Center(child: Text("Styles loading or failed..."));
    }

    // Determine the actual state to pass for styling, considering focus separately for border

    // DEBUG PRINT:
    print("DEBUG AppzInputField build: currentFieldState = $_currentFieldState, isEffectivelyDisabled = $_isEffectivelyDisabled, initialFieldState = ${widget.initialFieldState}, isFocused = $_isFocused, hasError = $_hasError, isFilled = $_isFilled, controllerText = '${_internalController.text}'");

    AppzFieldState stateForStyle = _currentFieldState;
    if (_isFocused && !_hasError && !_isEffectivelyDisabled) {
        // If focused without error/disabled, use 'focused' for style lookup
        // but 'filled' status is still relevant for other aspects like background.
        stateForStyle = AppzFieldState.focused;
    } else if (_hasError && !_isEffectivelyDisabled) {
        stateForStyle = AppzFieldState.error;
    } else if (_isEffectivelyDisabled) {
        stateForStyle = AppzFieldState.disabled;
    } // 'filled' and 'default' are handled by getStyleForState via _isFilled

    final AppzStateStyle style = AppzStyleConfig.instance.getStyleForState(stateForStyle, isFilled: _isFilled);
    final InputDecoration baseInputDecoration = _createBaseInputDecoration(style);

    Widget fieldWidget;

    if (widget.fieldType == AppzFieldType.defaultType) {
      final textFormField = TextFormField(
        controller: _internalController,
        focusNode: _internalFocusNode,
        decoration: baseInputDecoration.copyWith(
           // No specific overrides for defaultType, uses baseInputDecoration directly
           // prefixIcon: widget.prefixIcon, // If we add prefix/suffix to AppzInputField params directly
           // suffixIcon: widget.suffixIcon,
        ),
        style: TextStyle(
          color: style.textColor,
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
        ),
        validator: _performValidation,
        onTap: widget.onTap,
        onFieldSubmitted: widget.onSubmitted,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        maxLength: widget.maxLength,
        enabled: !_isEffectivelyDisabled,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
      fieldWidget = textFormField;
    } else if (widget.fieldType == AppzFieldType.mobile) {
      fieldWidget = MobileInputWidget(
        currentStyle: style,
        mainController: _internalController, // This controller is for the number part
        mainFocusNode: _internalFocusNode,
        isEnabled: !_isEffectivelyDisabled,
        hintText: widget.hintText,
        countryCode: widget.mobileCountryCode,
        countryCodeEditable: widget.mobileCountryCodeEditable,
        onChanged: (fullNumber) {
          // _MobileInputWidget updates AppzInputField's _internalController with the full number.
          // The listener on _internalController (_handleTextChange) will call widget.onChanged.
          // So, direct call to widget.onChanged here might be redundant if _internalController
          // is indeed set to the full number by MobileInputWidget.
          // For now, assuming _handleTextChange covers it.
          // If _internalController in AppzInputField was only for the 10-digit part,
          // then this onChanged from MobileInputWidget would be essential for the parent to get the full number.
          // Decision: _internalController holds the full number.
        },
        // The validator for MobileInputWidget's internal TextFormField is handled by _performValidation now.
        // _performValidation extracts the number part and calls widget.validator with it.
        validator: widget.validator, // Pass the original validator, _performValidation will adapt
        validationType: widget.validationType,
      );
    } else if (widget.fieldType == AppzFieldType.aadhaar) {
      fieldWidget = AadhaarInputWidget(
        currentStyle: style,
        mainController: _internalController, // Will hold combined 12 digits
        mainFocusNode: _internalFocusNode, // Main field focus
        isEnabled: !_isEffectivelyDisabled,
        hintText: widget.hintText ?? "XXXX XXXX XXXX",
        onChanged: widget.onChanged, // AppzInputField's onChanged gets the combined 12 digits
        validator: (value) { // Validator for the combined 12-digit string
           if (widget.validator != null) {
            final mainValidationError = widget.validator!(value);
            if (mainValidationError != null) return mainValidationError;
          }
          final unformattedValue = value?.replaceAll(' ', '') ?? '';
          if (unformattedValue.isEmpty) {
             if (widget.validationType == AppzInputValidationType.mandatory) {
                 return 'Aadhaar number is required.'; // TODO: Localize
            }
            return null;
          }
          if (unformattedValue.length != 12) {
            return 'Aadhaar number must be 12 digits.'; // TODO: Localize
          }
          return null;
        },
        validationType: widget.validationType,
      );
    } else if (widget.fieldType == AppzFieldType.mpin) {
      fieldWidget = MpinInputWidget(
        currentStyle: style,
        mainController: _internalController, // Will hold combined MPIN
        isEnabled: !_isEffectivelyDisabled,
        obscureText: widget.obscureText,
        mpinLength: widget.mpinLength,
        onChanged: widget.onChanged, // AppzInputField's onChanged gets the combined MPIN
        validator: (value) { // Validator for the combined MPIN string
          if (widget.validator != null) {
            final mainValidationError = widget.validator!(value);
            if (mainValidationError != null) return mainValidationError;
          }
          if (value == null || value.isEmpty) {
            if (widget.validationType == AppzInputValidationType.mandatory) {
                 return 'MPIN is required.'; // TODO: Localize
            }
            return null;
          }
          if (value.length != widget.mpinLength) {
            return 'MPIN must be ${widget.mpinLength} digits.'; // TODO: Localize
          }
          return null;
        },
        validationType: widget.validationType,
      );
    } else {
        // Fallback for fileUpload, textDescription, or any other types not yet implemented
        fieldWidget = Text('Field type ${widget.fieldType.name} not yet fully implemented.');
    }

    final String labelTextWithIndicator = widget.label;
    final Text labelWidget = Text(
      labelTextWithIndicator,
      style: TextStyle(
        color: style.labelColor,
        fontFamily: style.fontFamily,
        fontSize: style.labelFontSize,
      ),
    );

    // Basic Top Label Layout for now
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          labelWidget,
          const SizedBox(height: 6.0), // Spacing between label and field
        ],
        fieldWidget,
        if (_hasError && _validationErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              _validationErrorMessage!,
              style: TextStyle(
                color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).textColor, // Error text color
                fontSize: style.labelFontSize * 0.9, // Slightly smaller than label
                fontFamily: style.fontFamily,
              ),
            ),
          ),
      ],
    );
  }
}
