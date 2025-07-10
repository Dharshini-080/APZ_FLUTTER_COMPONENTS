import 'package:flutter/material.dart';
import 'apz_categories.dart';

class ApzCategoriesTestExample extends StatefulWidget {
  const ApzCategoriesTestExample({super.key});

  @override
  State<ApzCategoriesTestExample> createState() => _ApzCategoriesTestExampleState();
}

class _ApzCategoriesTestExampleState extends State<ApzCategoriesTestExample> {
  CategoryLayout _layout = CategoryLayout.horizontal;

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryItem(title: "Alarm", svgAssetPath: "assets/icons/alarm.svg"),
      CategoryItem(title: "Car", svgAssetPath: "assets/icons/car.svg"),
      CategoryItem(title: "Clouds", svgAssetPath: "assets/icons/clouds.svg"),
      CategoryItem(title: "Cart", svgAssetPath: "assets/icons/cart.svg"),
      CategoryItem(title: "Dial", svgAssetPath: "assets/icons/dial.svg"),
      CategoryItem(title: "Female", svgAssetPath: "assets/icons/female.svg"),
      CategoryItem(title: "Male", svgAssetPath: "assets/icons/male.svg"),
      CategoryItem(title: "Settings", svgAssetPath: "assets/icons/settings.svg"),
      CategoryItem(title: "User", svgAssetPath: "assets/icons/user.svg"),
      CategoryItem(title: "Error", svgAssetPath: "assets/icons/error.svg"),
      CategoryItem(title: "Calendar", svgAssetPath: "assets/icons/calendar.svg"),
      CategoryItem(title: "Bank", svgAssetPath: "assets/icons/password-management.svg"),
    ];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categories Test Example (config from JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Layout:'),
              const SizedBox(width: 8),
              DropdownButton<CategoryLayout>(
                value: _layout,
                items: const [
                  DropdownMenuItem(
                    value: CategoryLayout.horizontal,
                    child: Text('Horizontal'),
                  ),
                  DropdownMenuItem(
                    value: CategoryLayout.vertical,
                    child: Text('Vertical'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _layout = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 400,
            child: FutureBuilder<CategoryConfig>(
              future: CategoryConfig.loadFromAssets(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final config = snapshot.data!;
                return ApzCategories(
                  layout: _layout,
                  categories: categories,
                  config: config,
                  onTap: (category) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped: ${category.title}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 