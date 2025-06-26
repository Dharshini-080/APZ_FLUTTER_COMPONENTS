import 'package:flutter/material.dart';
import '../lib/components/appz_input_field/appz_input_field.dart';
import '../lib/components/appz_input_field/appz_input_field_theme.dart';

class AppzInputFieldExamplePage extends StatefulWidget {
  const AppzInputFieldExamplePage({super.key});

  @override
  State<AppzInputFieldExamplePage> createState() => _AppzInputFieldExamplePageState();
}

class _AppzInputFieldExamplePageState extends State<AppzInputFieldExamplePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _disabledController = TextEditingController(text: "Disabled Text");
  final TextEditingController _leftLabelController = TextEditingController();
   final TextEditingController _amountController = TextEditingController();


  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppzInputField Examples'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text("Basic Input (Label Top):", style: TextStyle(fontWeight: FontWeight.bold)),
              AppzInputField(
                label: 'Name',
                hintText: 'Enter your name',
                controller: _nameController,
                validationType: AppzInputValidationType.mandatory,
              ),
              const SizedBox(height: 20),

              const Text("Email Input (Mandatory):", style: TextStyle(fontWeight: FontWeight.bold)),
              AppzInputField(
                label: 'Email Address',
                hintText: 'you@example.com',
                controller: _emailController,
                inputType: AppzInputType.emailAddress,
                validationType: AppzInputValidationType.email, // Also implies mandatory via current logic if empty
                 // Forcing mandatory check as well
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email field cannot be empty.';
                  }
                  // Basic email regex check is inside AppzInputField for AppzInputValidationType.email
                  // This custom validator just adds the mandatory check on top.
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text("Password Input:", style: TextStyle(fontWeight: FontWeight.bold)),
              AppzInputField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                inputType: AppzInputType.password, // or obscureText: true
                validationType: AppzInputValidationType.mandatory, // Example: password is mandatory
                suffixIcon: Icon(Icons.visibility_off), // Example suffix
              ),
              const SizedBox(height: 20),

              const Text("Input with Prefix Icon & Label Left:", style: TextStyle(fontWeight: FontWeight.bold)),
              AppzInputField(
                label: 'Amount',
                hintText: '0.00',
                controller: _amountController,
                inputType: AppzInputType.number, // Or .amount when fully implemented
                labelPosition: AppzInputLabelPosition.left,
                prefixIcon: Icon(Icons.attach_money),
                validationType: AppzInputValidationType.amount,
                 validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount is required.';
                  final number = double.tryParse(value);
                  if (number == null) return 'Invalid number.';
                  if (number < 0) return 'Amount cannot be negative.';
                  return null;
                }
              ),
              const SizedBox(height: 20),

              const Text("Disabled Input:", style: TextStyle(fontWeight: FontWeight.bold)),
              AppzInputField(
                label: 'Disabled Field',
                controller: _disabledController,
                fieldState: AppzInputFieldState.disabled,
              ),
              const SizedBox(height: 20),

              const Text("Error State Input (External Error):", style: TextStyle(fontWeight: FontWeight.bold)),
              AppzInputField(
                label: 'Field with Error',
                hintText: 'Try submitting without value',
                // fieldState: AppzInputFieldState.error, // Can be set externally
                errorMessage: "This is an external error message.", // Or trigger via validator
                 validationType: AppzInputValidationType.mandatory,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Process data
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Form is valid!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Form has errors.')),
                    );
                  }
                },
                child: const Text('Submit Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _disabledController.dispose();
    _leftLabelController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
