import 'package:flutter/material.dart';
import 'appz_input_field_theme.dart'; // Importing enums

/// A versatile and themeable input field widget.
///
/// `AppzInputField` provides a customizable text input experience, supporting
/// various appearances, states, label positions, validation types, and input modes.
/// Its visual properties can be configured via a JSON file.
class AppzInputField extends StatefulWidget {
  /// The controller for editing the text.
  final TextEditingController? controller;

  /// The text to display as the label for the input field.
  final String label;

  /// Optional hint text to display inside the input field when it's empty.
  final String? hintText;

  /// The visual appearance style of the input field.
  /// Defaults to [AppzInputFieldAppearance.primary].
  final AppzInputFieldAppearance appearance;

  /// The current interactive or validation state of the field.
  /// This can be set externally or managed internally based on validation.
  /// Defaults to [AppzInputFieldState.defaultState].
  final AppzInputFieldState fieldState;

  /// The positioning of the label relative to the input field.
  /// Defaults to [AppzInputLabelPosition.top].
  final AppzInputLabelPosition labelPosition;

  /// The type of validation to be applied.
  /// Defaults to [AppzInputValidationType.none].
  final AppzInputValidationType validationType;

  /// The type of input, influencing keyboard and basic formatting.
  /// Defaults to [AppzInputType.text].
  final AppzInputType inputType;

  /// The focus node for managing the field's focus.
  final FocusNode? focusNode;

  /// Callback when the text in the field changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits the field (e.g., presses "done" on the keyboard).
  final ValueChanged<String>? onSubmitted;

  /// Callback when the input field is tapped.
  final VoidCallback? onTap;

  /// Whether to obscure the text being entered (e.g., for passwords).
  /// Defaults to `false`.
  final bool obscureText;

  /// An optional error message to display below the field.
  /// This can be used to show errors from external validation sources.
  /// If provided, it may override internal validation messages depending on implementation.
  final String? errorMessage;

  /// An optional widget to display before the input area.
  final Widget? prefixIcon;

  /// An optional widget to display after the input area.
  final Widget? suffixIcon;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// An optional custom validator function.
  /// If provided, this can work in conjunction with or override internal validation.
  final FormFieldValidator<String>? validator;

  /// Creates an AppzInputField.
  const AppzInputField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.appearance = AppzInputFieldAppearance.primary,
    this.fieldState = AppzInputFieldState.defaultState, // TODO: Revisit how this interacts with internal state
    this.labelPosition = AppzInputLabelPosition.top,
    this.validationType = AppzInputValidationType.none,
    this.inputType = AppzInputType.text,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.errorMessage,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.validator,
  });

  @override
  State<AppzInputField> createState() => _AppzInputFieldState();
}

class _AppzInputFieldState extends State<AppzInputField> {
  late final TextEditingController _internalController;
  late final FocusNode _internalFocusNode;

  String? _internalErrorMessage;

  bool get _hasError => _internalErrorMessage != null || widget.errorMessage != null;
  String? get _effectiveErrorMessage => widget.errorMessage ?? _internalErrorMessage;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    // TODO: Add listener to focus node to update internal state if needed (e.g. for focused style)
    // _internalFocusNode.addListener(_onFocusChange);
  }

  // void _onFocusChange() {
  //   setState(() {
  //     // This can be used to trigger style changes based on focus
  //     // For now, fieldState.focused will primarily drive this
  //   });
  // }

  @override
  void dispose() {
    // Only dispose if they were created internally
    if (widget.controller == null) {
      _internalController.dispose();
    }
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    // _internalFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  TextInputType _mapInputTypeToKeyboardType(AppzInputType inputType) {
    switch (inputType) {
      case AppzInputType.text:
        return TextInputType.text;
      case AppzInputType.multiline:
        return TextInputType.multiline;
      case AppzInputType.number:
        return TextInputType.number;
      case AppzInputType.phone:
        return TextInputType.phone;
      case AppzInputType.emailAddress:
        return TextInputType.emailAddress;
      case AppzInputType.url:
        return TextInputType.url;
      case AppzInputType.password:
        return TextInputType.visiblePassword; // TextFormField handles obscuring
      case AppzInputType.date:
        return TextInputType.datetime;
      case AppzInputType.dateTime:
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    // These are temporary hardcoded styles, to be replaced by JSON config
    // These are temporary hardcoded styles, to be replaced by JSON config
    // Base Colors
    const defaultBorderColor = Color(0xFFD7DBE0);
    const focusedBorderColor = Color(0xFF6192F9); // Blue
    const errorBorderColor = Color(0xFFE03333); // Red
    const successBorderColor = Color(0xFF4CAF50); // Green (example)
    const defaultBackgroundColor = Color(0xFFF3F4F6);

    // Text Colors
    const inputTextColor = Color(0xFF24272D); // Active input text
    const labelTextColor = Color(0xFFB3BBC6); // Default label
    const hintTextColor = Color(0xFFB3BBC6); // Default placeholder
    const disabledTextColor = Color(0xFFB3BBC6); // Disabled text (same as hint/label)

    // Disabled Styles
    const disabledBackgroundColor = Color(0xFFF3F4F6); // Same as default, but border might differ or be less prominent
    const disabledBorderColor = Color(0xFFE5E7EB); // Lighter grey for disabled border

    bool isEnabled = widget.fieldState != AppzInputFieldState.disabled;

    Color currentFillColor = defaultBackgroundColor;
    Color currentHintColor = hintTextColor;
    Color currentInputBorderColor = defaultBorderColor; // For enabledBorder
    Color currentFocusedBorderColor = focusedBorderColor;
    TextStyle currentInputTextStyle = const TextStyle(color: inputTextColor, fontSize: 14, fontWeight: FontWeight.w500);

    if (!isEnabled) {
      currentFillColor = disabledBackgroundColor;
      currentHintColor = disabledTextColor;
      currentInputBorderColor = disabledBorderColor;
      currentFocusedBorderColor = disabledBorderColor; // Focused border same as normal when disabled
      currentInputTextStyle = const TextStyle(color: disabledTextColor, fontSize: 14, fontWeight: FontWeight.w500);
    }

    // Determine border color based on state precedence: error > success > focused > default
    // This applies to the general 'enabled' state. Disabled state has its own border color.
    if (isEnabled) {
      if (_hasError) {
        currentInputBorderColor = errorBorderColor;
        currentFocusedBorderColor = errorBorderColor; // Error border persists on focus
      } else if (widget.fieldState == AppzInputFieldState.success) {
        currentInputBorderColor = successBorderColor;
        currentFocusedBorderColor = successBorderColor; // Success border persists on focus
      } else if (widget.fieldState == AppzInputFieldState.focused) {
        // This is for the 'focusedBorder' property, not the general 'currentInputBorderColor'
        // currentInputBorderColor remains defaultBorderColor unless error/success
      }
    }

    // Specific border for the 'border' property (when not focused, not error, not success)
    final BorderSide defaultEnabledOutlineBorderSide = BorderSide(color: currentInputBorderColor, width: 1);

    final inputDecoration = InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(color: currentHintColor, fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: currentFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder( // Default border when nothing else applies (usually not visible due to enabledBorder/focusedBorder)
        borderRadius: BorderRadius.circular(12),
        borderSide: defaultEnabledOutlineBorderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: defaultEnabledOutlineBorderSide, // Uses currentInputBorderColor determined above
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isEnabled ? currentFocusedBorderColor : disabledBorderColor, // Use specific focused color or disabled color
          width: 1.5
        ),
      ),
      errorBorder: OutlineInputBorder( // Used when `validator` returns an error OR `errorText` is not null
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorBorderColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder( // Used when `validator` returns an error AND field is focused
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorBorderColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder( // Used when `enabled` is false
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: disabledBorderColor, width: 1),
      ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      // errorText: _effectiveErrorMessage, // Let TextFormField handle displaying this via its validator or errorText from decoration
    );

    final textFormField = TextFormField(
      controller: _internalController,
      focusNode: _internalFocusNode,
      keyboardType: _mapInputTypeToKeyboardType(widget.inputType),
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText || widget.inputType == AppzInputType.password,
      maxLines: widget.inputType == AppzInputType.multiline ? null : 1,
      minLines: widget.inputType == AppzInputType.multiline ? 3 : 1,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onFieldSubmitted: widget.onSubmitted,
      enabled: isEnabled,
      // validator: _validate,
      style: currentInputTextStyle,
      decoration: inputDecoration,
    );

    // Label style might also change based on disabled state, but for now, keep it consistent.
    final labelWidget = Text(
      widget.label,
      style: const TextStyle(
        color: labelTextColor, // Potentially: isEnabled ? labelTextColor : disabledTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );

    Widget fieldLayout;
    if (widget.labelPosition == AppzInputLabelPosition.top) {
      fieldLayout = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelWidget,
          const SizedBox(height: 4), // Space between label and field
          textFormField,
        ],
      );
    } else { // AppzInputLabelPosition.left
      fieldLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align label with top of the field
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 12.0), // Adjust padding for alignment
            child: labelWidget,
          ),
          Expanded(child: textFormField),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLayout,
        if (_effectiveErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 12.0), // Consistent with input padding
            child: Text(
              _effectiveErrorMessage!,
              style: const TextStyle(color: errorBorderColor, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String? _validate(String? value) {
    // Priority to external validator if provided
    if (widget.validator != null) {
      final externalValidationError = widget.validator!(value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _internalErrorMessage = externalValidationError;
          });
        }
      });
      return externalValidationError;
    }

    String? validationError;
    final trimmedValue = value?.trim() ?? '';

    switch (widget.validationType) {
      case AppzInputValidationType.mandatory:
        if (trimmedValue.isEmpty) {
          validationError = 'This field is required.'; // TODO: Localize
        }
        break;
      case AppzInputValidationType.email:
        if (trimmedValue.isEmpty && widget.validationType == AppzInputValidationType.mandatory) { // Should chain with mandatory if also set
             validationError = 'This field is required.'; // TODO: Localize
        } else if (trimmedValue.isNotEmpty) {
          // Basic email regex - for more robust validation, consider a library
          final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
          if (!emailRegex.hasMatch(trimmedValue)) {
            validationError = 'Enter a valid email address.'; // TODO: Localize
          }
        }
        break;
      // TODO: Implement other validation types (numeric, amount, password)
      case AppzInputValidationType.numeric:
      case AppzInputValidationType.amount:
      case AppzInputValidationType.password:
      case AppzInputValidationType.none:
      default:
        break;
    }

    // Update internal error message state after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _internalErrorMessage = validationError;
        });
      }
    });

    return validationError; // This is what TextFormField uses directly
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing build method code) ...

    // Connect the validator
    final textFormField = TextFormField(
      // ... (other properties) ...
      validator: _validate,
      autovalidateMode: AutovalidateMode.onUserInteraction, // Or .disabled and validate manually
      // ... (other properties) ...
    );

    // Label style might also change based on disabled state, but for now, keep it consistent.
    final labelText = widget.validationType == AppzInputValidationType.mandatory
        ? '${widget.label}*'
        : widget.label;
    final labelWidget = Text(
      labelText,
      style: const TextStyle(
        color: labelTextColor, // Potentially: isEnabled ? labelTextColor : disabledTextColor,
    // ... (rest of the build method) ...
  }
}
