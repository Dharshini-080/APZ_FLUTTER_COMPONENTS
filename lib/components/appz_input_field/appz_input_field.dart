import 'package:flutter/material.dart';
import 'appz_input_field_enums.dart';
import 'appz_style_config.dart'; // Will be used in the next step for styling

/// A versatile and themeable input field widget driven by JSON configuration.
class AppzInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final AppzFieldType fieldType;
  final AppzFieldState initialFieldState; // Can be used to force a state externally
  final String? initialValue; // Used if controller is not provided

  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  final bool obscureText;
  final TextInputAction? textInputAction;
  final int? maxLength;
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
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.maxLength,
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
        // Allow external state changes to override, unless it's about focus/filled which are more dynamic
        if(widget.initialFieldState == AppzFieldState.disabled || widget.initialFieldState == AppzFieldState.error) {
            _updateState(widget.initialFieldState);
        }
    }
     if (widget.initialValue != oldWidget.initialValue && widget.controller == null) {
      _internalController.text = widget.initialValue ?? '';
      // _handleTextChange will be called by the listener
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
    super.dispose();
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

    Widget fieldWidget;

    if (widget.fieldType == AppzFieldType.defaultType) {
      final inputDecoration = InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: style.textColor.withOpacity(0.5), // Example: hint is less prominent
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
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.focused, isFilled: _isFilled).borderColor, // Always use focused border color
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
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).borderColor, // Error border color even when focused
            width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.error, isFilled: _isFilled).borderWidth + 0.5, // Slightly thicker
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius),
          borderSide: BorderSide(
            color: AppzStyleConfig.instance.getStyleForState(AppzFieldState.disabled, isFilled: _isFilled).borderColor,
            width: AppzStyleConfig.instance.getStyleForState(AppzFieldState.disabled, isFilled: _isFilled).borderWidth,
          ),
        ),
        // prefixIcon: widget.prefixIcon, // Will add these later if part of defaultType
        // suffixIcon: widget.suffixIcon,
      );

      final textFormField = TextFormField(
        controller: _internalController,
        focusNode: _internalFocusNode,
        decoration: inputDecoration,
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
        // keyboardType: _mapInputTypeToKeyboardType(widget.inputType), // Assuming defaultType uses text keyboard
      );
      fieldWidget = textFormField;
    } else {
      // Placeholder for other field types
      fieldWidget = Text('Unsupported field type: ${widget.fieldType.name}');
    }

    final String labelTextWithIndicator = widget.label; // Mandatory indicator logic can be added here if needed for specific types
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
