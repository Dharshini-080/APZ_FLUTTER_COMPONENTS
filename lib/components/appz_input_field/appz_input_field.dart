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
  final AppzInputFieldState fieldState; // TODO: Revisit how this interacts with internal state

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
    this.fieldState = AppzInputFieldState.defaultState,
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
      case AppzInputType.dateTime: // Both map to datetime for keyboard
        return TextInputType.datetime;
      // No default needed as all enum values are covered.
      // Dart analyzer will warn if a new enum value is added and not handled.
    }
  }

  String? _validate(String? value) {
    // Priority to external validator if provided
    if (widget.validator != null) {
      final externalValidationError = widget.validator!(value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _internalErrorMessage != externalValidationError) {
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
        if (trimmedValue.isNotEmpty) {
          final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
          if (!emailRegex.hasMatch(trimmedValue)) {
            validationError = 'Enter a valid email address.'; // TODO: Localize
          }
        }
        break;
      case AppzInputValidationType.numeric:
        if (trimmedValue.isNotEmpty && double.tryParse(trimmedValue) == null) {
            validationError = 'Enter a valid number.'; // TODO: Localize
        }
        break;
      case AppzInputValidationType.amount:
        if (trimmedValue.isNotEmpty) {
            final number = double.tryParse(trimmedValue);
            if (number == null) {
                validationError = 'Enter a valid amount.'; // TODO: Localize
            } else if (number < 0) {
                // validationError = 'Amount cannot be negative.'; // Example specific rule for future
            }
        }
        break;
      case AppzInputValidationType.password: // TODO: Implement password specific rules if any (e.g. length, complexity)
      case AppzInputValidationType.none:
      default: // Covers .none and any future unhandled validation types explicitly
        break;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _internalErrorMessage != validationError) {
        setState(() {
          _internalErrorMessage = validationError;
        });
      }
    });
    return validationError;
  }

  @override
  Widget build(BuildContext context) {
    // These are temporary hardcoded styles, to be replaced by JSON config
    const defaultBorderColor = Color(0xFFD7DBE0);
    const focusedBorderColor = Color(0xFF6192F9); // Blue
    const errorBorderColor = Color(0xFFE03333); // Red
    const successBorderColor = Color(0xFF4CAF50); // Green (example)
    const defaultBackgroundColor = Color(0xFFF3F4F6);

    const inputTextColor = Color(0xFF24272D); // Active input text
    const labelTextColor = Color(0xFFB3BBC6); // Default label
    const hintTextColor = Color(0xFFB3BBC6); // Default placeholder
    const disabledTextColor = Color(0xFFB3BBC6);

    const disabledBackgroundColor = Color(0xFFF3F4F6);
    const disabledBorderColor = Color(0xFFE5E7EB);

    bool isEnabled = widget.fieldState != AppzInputFieldState.disabled;

    Color currentFillColor = defaultBackgroundColor;
    Color currentHintColor = hintTextColor;
    Color currentInputBorderColor = defaultBorderColor;
    Color currentFocusedBorderColor = focusedBorderColor;
    TextStyle currentInputTextStyle = const TextStyle(color: inputTextColor, fontSize: 14, fontWeight: FontWeight.w500);

    if (!isEnabled) {
      currentFillColor = disabledBackgroundColor;
      currentHintColor = disabledTextColor;
      currentInputBorderColor = disabledBorderColor;
      currentFocusedBorderColor = disabledBorderColor;
      currentInputTextStyle = const TextStyle(color: disabledTextColor, fontSize: 14, fontWeight: FontWeight.w500);
    }

    if (isEnabled) {
      if (_hasError) {
        currentInputBorderColor = errorBorderColor;
        currentFocusedBorderColor = errorBorderColor;
      } else if (widget.fieldState == AppzInputFieldState.success) {
        currentInputBorderColor = successBorderColor;
        currentFocusedBorderColor = successBorderColor;
      } else if (widget.fieldState == AppzInputFieldState.focused) {
        // currentInputBorderColor remains defaultBorderColor unless error/success
        // currentFocusedBorderColor is already set to focusedBorderColor
      }
    }

    final BorderSide defaultEnabledOutlineBorderSide = BorderSide(color: currentInputBorderColor, width: 1);

    final inputDecoration = InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(color: currentHintColor, fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: currentFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: defaultEnabledOutlineBorderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: defaultEnabledOutlineBorderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isEnabled ? currentFocusedBorderColor : disabledBorderColor,
          width: 1.5
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorBorderColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorBorderColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: disabledBorderColor, width: 1),
      ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
    );

    final TextFormField textFormField = TextFormField(
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
      validator: _validate,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: currentInputTextStyle,
      decoration: inputDecoration,
    );

    final String labelTextWithIndicator = widget.validationType == AppzInputValidationType.mandatory && widget.label.isNotEmpty
        ? '${widget.label}*'
        : widget.label;
    final Text labelWidget = Text(
      labelTextWithIndicator,
      style: const TextStyle(
        color: labelTextColor,
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
          const SizedBox(height: 4),
          textFormField,
        ],
      );
    } else { // AppzInputLabelPosition.left
      fieldLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 12.0),
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
            padding: const EdgeInsets.only(top: 6.0, left: 12.0),
            child: Text(
              _effectiveErrorMessage!,
              style: const TextStyle(color: errorBorderColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
