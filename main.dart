import 'package:flutter/material.dart';
import 'example/appz_input_field_example_page.dart'; // Adjust path if your structure is different

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppzInputField Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // You might want to define some base text styles or color schemes
        // that your AppzInputField might inherit or use as fallbacks later.
      ),
      home: const AppzInputFieldExamplePage(),
    );
  }
}
