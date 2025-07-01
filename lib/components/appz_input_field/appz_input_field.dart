import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'appz_input_field_enums.dart';
import 'appz_style_config.dart';
import 'formatters/aadhaar_input_formatter.dart'; // Import the formatter

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
  final int? maxLength; // Used by defaultType, Aadhaar (for formatted length)
  final int mpinLength; // Specific to mpinFieldType

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

  String? _performValidation(String? value) {
    _validationErrorMessage = null; // Clear previous internal error
    if (widget.validator != null) {
      _validationErrorMessage = widget.validator!(value);
    }
    // Update state based on validation result
    if (_validationErrorMessage != null) {
      _updateState(AppzFieldState.error, errorMessage: _validationErrorMessage);
    } else if (!_isFocused) {
      // If valid and not focused, set to filled or default
      _updateState(_internalController.text.isNotEmpty ? AppzFieldState.filled : AppzFieldState.defaultState);
    } else if (_isFocused) {
      // If valid and focused, remain in focused state.
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
      const String countryCodePrefix = "+91";

      final prefixWidget = Padding(
        padding: EdgeInsets.only(
          left: style.paddingHorizontal,
          right: style.paddingHorizontal / 2, // Some spacing between prefix and input
          top: style.paddingVertical,
          bottom: style.paddingVertical
        ),
        child: Text(
          countryCodePrefix,
          style: TextStyle(
            color: style.textColor, // Or a specific prefix color from config
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
          ),
        ),
      );

      // Adjust contentPadding for the TextFormField as prefix is now separate
      final mobileInputDecoration = baseInputDecoration.copyWith( // Changed here
        contentPadding: EdgeInsets.symmetric(
          horizontal: style.paddingHorizontal / 2, // Reduced left padding
          vertical: style.paddingVertical
        ),
        prefixIcon: prefixWidget, // Using prefixIcon to place the text
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0), // To make prefix text compact
      );

      // For mobile, we effectively use a subset of the full decoration for the inner TextFormField
      // The outer container (if we add one) would have the main border.
      // For now, let's make the TextFormField itself have the border.

      final mobileTextFormField = TextFormField(
        controller: _internalController,
        focusNode: _internalFocusNode,
        decoration: mobileInputDecoration,
        style: TextStyle(
          color: style.textColor,
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
        ),
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10), // 10 digits for the number part
        ],
        validator: (value) {
          // Chain with general validator if present
          String? externalValidationError;
          if (widget.validator != null) {
            externalValidationError = widget.validator!(value);
            if (externalValidationError != null) return externalValidationError;
          }
          // Mobile specific validation
          if (value == null || value.isEmpty) {
            if (widget.validationType == AppzInputValidationType.mandatory) { // Check if mandatory is set
                 return 'Mobile number is required.'; // TODO: Localize
            }
            return null; // Not mandatory and empty is fine
          }
          if (value.length != 10) {
            return 'Mobile number must be 10 digits.'; // TODO: Localize
          }
          return null;
        },
        onTap: widget.onTap,
        onFieldSubmitted: widget.onSubmitted,
        obscureText: widget.obscureText, // Unlikely for mobile, but respect it
        textInputAction: widget.textInputAction,
        enabled: !_isEffectivelyDisabled,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
      fieldWidget = mobileTextFormField; // For now, just the TextFormField itself
      // Later, this might be wrapped in a custom container to draw a shared border if prefix is truly outside
    } else if (widget.fieldType == AppzFieldType.aadhaar) {
       final baseInputDecoration = InputDecoration( // Re-define or pass baseInputDecoration
        hintText: widget.hintText ?? "XXXX XXXX XXXX", // Aadhaar specific hint
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
      );
      final aadhaarTextFormField = TextFormField(
        controller: _internalController,
        focusNode: _internalFocusNode,
        decoration: baseInputDecoration, // Use the defined base for Aadhaar
        style: TextStyle(
          color: style.textColor,
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          AadhaarInputFormatter(), // Custom formatter for XXXX XXXX XXXX
          LengthLimitingTextInputFormatter(14), // 12 digits + 2 spaces
        ],
        validator: (value) {
          String? externalValidationError;
          if (widget.validator != null) {
            externalValidationError = widget.validator!(value);
            if (externalValidationError != null) return externalValidationError;
          }
          // Aadhaar specific validation
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
          // Potentially add checksum validation here in the future
          return null;
        },
        onTap: widget.onTap,
        onFieldSubmitted: widget.onSubmitted,
        textInputAction: widget.textInputAction,
        enabled: !_isEffectivelyDisabled,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
      fieldWidget = aadhaarTextFormField;
    } else if (widget.fieldType == AppzFieldType.mpin) {
      final mpinSegmentBaseDecoration = _createBaseInputDecoration(style).copyWith(
        counterText: "",
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius / 1.5),
          borderSide: BorderSide(color: style.borderColor, width: style.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius / 1.5),
          borderSide: BorderSide(color: style.borderColor, width: style.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius / 1.5),
          borderSide: BorderSide(
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.focused, isFilled: _isFilled).borderColor,
            width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.focused, isFilled: _isFilled).borderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius / 1.5),
          borderSide: BorderSide(
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.disabled).borderColor,
            width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.disabled).borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius / 1.5),
          borderSide: BorderSide(
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error).borderColor,
            width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error).borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius / 1.5),
          borderSide: BorderSide(
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error).borderColor,
            width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error).borderWidth + 0.5,
          ),
        ),
      );

      fieldWidget = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.mpinLength, (index) {
          return SizedBox(
            width: 48,
            height: 52,
            child: TextFormField(
              controller: _mpinSegmentControllers[index],
              focusNode: _mpinSegmentFocusNodes[index],
              enabled: !_isEffectivelyDisabled,
              textAlign: TextAlign.center,
              maxLength: 1,
              obscureText: widget.obscureText,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: style.textColor,
                fontFamily: style.fontFamily,
                fontSize: style.fontSize + 4,
                fontWeight: FontWeight.bold,
              ),
              decoration: mpinSegmentBaseDecoration,
              onChanged: (value) {
                if (value.isEmpty && index > 0) {
                  FocusScope.of(context).requestFocus(_mpinSegmentFocusNodes[index - 1]);
                } else if (value.isNotEmpty && index < widget.mpinLength - 1) {
                  // _onMpinSegmentChanged handles forward focus, but this ensures it happens on first char
                   FocusScope.of(context).requestFocus(_mpinSegmentFocusNodes[index + 1]);
                }
                 _onMpinSegmentChanged(index); // Ensure value aggregation happens
              },
            ),
          );
        }),
      );
    } else {
        // Fallback for any other types not yet implemented
        fieldWidget = Text('Unsupported field type: ${widget.fieldType.name}');
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
