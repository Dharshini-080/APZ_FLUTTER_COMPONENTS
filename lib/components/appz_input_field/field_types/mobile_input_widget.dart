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

import '../utils/country_model.dart';
import '../utils/country_codes_helper.dart';

class _MobileInputWidgetState extends State<MobileInputWidget> {
  late TextEditingController _numberController;
  late CountryModel _selectedCountry;
  List<CountryModel> _countryList = [];

  @override
  void initState() {
    super.initState();
    _countryList = CountryCodesHelper.getCountries();
    _numberController = TextEditingController();
    _initializeState(); // Handles initial country and number from mainController
    _numberController.addListener(_onNumberOrCountryChanged);
    widget.mainController.addListener(_onMainControllerChanged);
  }

  void _initializeState() {
    final initialFullNumber = widget.mainController.text;
    CountryModel? foundCountry;
    String initialNumberPart = "";

    if (initialFullNumber.isNotEmpty && initialFullNumber.startsWith("+")) {
      for (var country in _countryList) {
        // Use displayDialCode which includes '+'
        if (initialFullNumber.startsWith(country.displayDialCode)) {
          foundCountry = country;
          initialNumberPart = initialFullNumber.substring(country.displayDialCode.length);
          break;
        }
      }
    }

    // Determine initial selected country
    if (foundCountry != null) {
      _selectedCountry = foundCountry;
    } else {
      // Try to find by widget.countryCode (which is like "+91")
      _selectedCountry = CountryCodesHelper.getCountryByDialCode(widget.countryCode) ?? CountryCodesHelper.getDefaultCountry();
      // If main controller had text but didn't match any known prefix, assume it's the number part.
      if (initialFullNumber.isNotEmpty && foundCountry == null && !initialFullNumber.startsWith("+")) {
          initialNumberPart = initialFullNumber;
      }
    }

    // Set number part
    if (_numberController.text != initialNumberPart) {
      _numberController.value = TextEditingValue(
        text: initialNumberPart,
        selection: TextSelection.collapsed(offset: initialNumberPart.length),
      );
    }

    // Ensure main controller reflects the initial state correctly (with country code)
    // especially if initialFullNumber was just the number part.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateMainController();
    });
  }

  void _onMainControllerChanged() {
    final fullText = widget.mainController.text;
    final currentCombinedFromState = _selectedCountry.displayDialCode + _numberController.text;

    if (fullText == currentCombinedFromState) return; // Already in sync

    CountryModel? newSelectedCountry = _selectedCountry;
    String newNumberPart = "";

    if (fullText.isNotEmpty && fullText.startsWith("+")) {
       for (var country in _countryList) {
        if (fullText.startsWith(country.displayDialCode)) {
          newSelectedCountry = country;
          newNumberPart = fullText.substring(country.displayDialCode.length);
          break;
        }
      }
       // If no country code prefix matched, but it starts with +, it's ambiguous.
       // Keep current selected country and assume rest is number.
       if(newSelectedCountry == _selectedCountry && !fullText.startsWith(_selectedCountry.displayDialCode)){
         newNumberPart = fullText; // Or parse out a potential number part
       }

    } else if (fullText.isNotEmpty) {
      // No "+" prefix, assume it's a number part for the current country
      newNumberPart = fullText;
    }

    _numberController.removeListener(_onNumberOrCountryChanged);
    bool needsSetState = false;
    if (_selectedCountry.isoCode != newSelectedCountry.isoCode) {
      _selectedCountry = newSelectedCountry;
      needsSetState = true;
    }
    if (_numberController.text != newNumberPart) {
      _numberController.value = TextEditingValue(
        text: newNumberPart,
        selection: TextSelection.collapsed(offset: newNumberPart.length),
      );
    }
    _numberController.addListener(_onNumberOrCountryChanged);
    if(needsSetState && mounted) setState(() {});
  }

  void _onNumberOrCountryChanged() { // Called by _numberController listener OR dropdown onChanged
    _updateMainController();
  }

  void _updateMainController() {
    final String fullMobileNumber = _selectedCountry.displayDialCode + _numberController.text;
    if (widget.mainController.text != fullMobileNumber) {
      widget.mainController.value = TextEditingValue(
        text: fullMobileNumber,
        selection: TextSelection.fromPosition(TextPosition(offset: fullMobileNumber.length)),
      );
      // AppzInputField's listener on mainController will trigger its onChanged
    }
  }

  @override
  void didUpdateWidget(covariant MobileInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mainController != oldWidget.mainController) {
      oldWidget.mainController.removeListener(_onMainControllerChanged);
      widget.mainController.addListener(_onMainControllerChanged);
      _initializeState();
    }
    // If countryCode prop changes AND dropdown is not editable, update _selectedCountry
    if (widget.countryCode != oldWidget.countryCode && !widget.countryCodeEditable) {
        final newCountry = CountryCodesHelper.getCountryByDialCode(widget.countryCode);
        if (newCountry != null && newCountry.isoCode != _selectedCountry.isoCode) {
           if (mounted) {
            setState(() {
              _selectedCountry = newCountry;
            });
          }
          _updateMainController();
        }
    }
     if (widget.countryCodeEditable != oldWidget.countryCodeEditable) {
        if(mounted) setState(() {}); // Trigger rebuild to show/hide dropdown
    }
  }

  @override
  void dispose() {
    widget.mainController.removeListener(_onMainControllerChanged);
    _numberController.removeListener(_onNumberOrCountryChanged);
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppzStateStyle style = widget.currentStyle;

    final numberInputDecoration = InputDecoration(
      hintText: widget.hintText ?? '00000 00000',
      hintStyle: TextStyle(
        color: style.textColor.withOpacity(0.5),
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
      ),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      // Using contentPadding from the TextFormField itself now for better control
      contentPadding: EdgeInsets.symmetric(vertical: style.paddingVertical), // Ensure vertical alignment
      isDense: true,
    );

    Widget countryCodeWidget;
    if (widget.countryCodeEditable) {
      countryCodeWidget = DropdownButtonHideUnderline(
        child: DropdownButtonFormField<CountryModel>(
          isDense: true,
          value: _selectedCountry,
          items: _countryList.map((CountryModel country) {
            return DropdownMenuItem<CountryModel>(
              value: country,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(country.flagEmoji, style: TextStyle(fontSize: style.fontSize * 1.2)),
                  const SizedBox(width: 6.0),
                  Text(country.displayDialCode, style: TextStyle(fontSize: style.fontSize, fontFamily: style.fontFamily, color: style.textColor)),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.isEnabled ? (CountryModel? newValue) {
            if (newValue != null) {
              if(mounted) {
                setState(() { _selectedCountry = newValue; });
              }
              _onNumberOrCountryChanged();
            }
          } : null,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: style.paddingVertical, horizontal: 4.0), // Adjusted
            isDense: true,
          ),
          selectedItemBuilder: (BuildContext context) {
              return _countryList.map<Widget>((CountryModel item) {
                  return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                            Text(item.flagEmoji, style: TextStyle(fontSize: style.fontSize * 1.2)),
                            const SizedBox(width: 4),
                            Text(item.displayDialCode, style: TextStyle(fontSize: style.fontSize, fontFamily: style.fontFamily, color: widget.isEnabled ? style.textColor : style.textColor.withOpacity(0.5))),
                        ],
                    );
              }).toList();
          },
          icon: Icon(Icons.arrow_drop_down, color: widget.isEnabled ? style.labelColor : style.labelColor.withOpacity(0.5)),
          iconSize: style.fontSize * 1.5,
          isExpanded: false,
        ),
      );
    } else {
      countryCodeWidget = Padding(
         padding: EdgeInsets.symmetric(vertical: style.paddingVertical), // Match TextFormField's effective padding
        child: Text(
          _selectedCountry.displayDialCode,
          style: TextStyle(
            color: widget.isEnabled ? style.textColor : style.textColor.withOpacity(0.5),
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: style.paddingHorizontal),
      decoration: BoxDecoration(
        color: widget.isEnabled ? style.backgroundColor : style.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
      ),
      child: IntrinsicHeight( // Ensures Row children try to conform to a common height
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            countryCodeWidget,
            // SizedBox(width: style.paddingHorizontal / 2), // Original spacing - might be too much with divider
            Container(
              height: style.fontSize * 1.5, // Make divider height relative to font
              width: 1,
              color: style.borderColor.withOpacity(0.5),
              margin: EdgeInsets.symmetric(horizontal: style.paddingHorizontal / 2), // Adjusted spacing
            ),
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
                validator: widget.validator,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
