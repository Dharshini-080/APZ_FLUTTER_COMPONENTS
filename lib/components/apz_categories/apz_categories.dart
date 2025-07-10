import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum CategoryLayout { horizontal, vertical }

class CategoryItem {
  final String title;
  final String svgAssetPath;

  CategoryItem({
    required this.title,
    required this.svgAssetPath,
  });
}

class CategoryConfig {
  final Color backgroundColor;
  final Color cardShadowColor;
  final Color labelColor;
  final double cardBorderRadius;
  final String fontFamily;
  final double shadowBlur;
  final double shadowOffsetY;
  final double cardWidth;
  final double cardHeight;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final double padding;

  CategoryConfig({
    required this.backgroundColor,
    required this.cardShadowColor,
    required this.labelColor,
    required this.cardBorderRadius,
    required this.fontFamily,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.cardWidth,
    required this.cardHeight,
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.padding,
  });

  factory CategoryConfig.fromResolvedJson(Map<String, dynamic> json) {
    return CategoryConfig(
      backgroundColor: _hexToColor(json['backgroundColor']),
      cardShadowColor: _hexToColor(json['cardShadowColor']),
      labelColor: _hexToColor(json['labelColor']),
      cardBorderRadius: (json['cardBorderRadius'] as num).toDouble(),
      fontFamily: json['fontFamily'],
      shadowBlur: (json['shadowBlur'] as num).toDouble(),
      shadowOffsetY: (json['shadowOffsetY'] as num).toDouble(),
      cardWidth: (json['cardWidth'] as num).toDouble(),
      cardHeight: (json['cardHeight'] as num).toDouble(),
      iconSize: (json['iconSize'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
      spacing: (json['spacing'] as num).toDouble(),
      padding: (json['padding'] as num).toDouble(),
    );
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static Future<CategoryConfig> loadFromAssets() async {
    try {
      final String configData = await rootBundle.loadString('assets/category_config.json');
      final Map<String, dynamic> config = jsonDecode(configData);
      final String parentData = await rootBundle.loadString('assets/category_parent.json');
      final Map<String, dynamic> parent = jsonDecode(parentData);
      final resolved = <String, dynamic>{};
      config.forEach((key, value) {
        if (value is String && value.startsWith(r'$')) {
          final parentKey = value.substring(1);
          resolved[key] = parent[parentKey];
        } else {
          resolved[key] = value;
        }
      });
      return CategoryConfig.fromResolvedJson(resolved);
    } catch (e) {
      throw Exception('Failed to load category config: $e');
    }
  }
}

class ApzCategories extends StatelessWidget {
  final List<CategoryItem> categories;
  final CategoryLayout layout;
  final CategoryConfig? config;
  final double? maxWidth;
  final double? maxHeight;
  final void Function(CategoryItem)? onTap;

  const ApzCategories({
    Key? key,
    required this.categories,
    this.layout = CategoryLayout.horizontal,
    this.config,
    this.maxWidth,
    this.maxHeight,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = config!;
    List<Widget> cardWidgets = categories.map((item) {
      return GestureDetector(
        onTap: onTap != null ? () => onTap!(item) : null,
        child: Container(
          width: effectiveConfig.cardWidth,
          height: effectiveConfig.cardHeight,
          margin: layout == CategoryLayout.horizontal
              ? EdgeInsets.only(right: effectiveConfig.spacing)
              : EdgeInsets.only(bottom: effectiveConfig.spacing),
          padding: EdgeInsets.all(effectiveConfig.padding),
          decoration: BoxDecoration(
            color: effectiveConfig.backgroundColor,
            borderRadius: BorderRadius.circular(effectiveConfig.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: effectiveConfig.cardShadowColor,
                blurRadius: effectiveConfig.shadowBlur,
                offset: Offset(0, effectiveConfig.shadowOffsetY),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: SvgPicture.asset(
                  item.svgAssetPath,
                  width: effectiveConfig.iconSize,
                  height: effectiveConfig.iconSize,
                  fit: BoxFit.contain,
                ),
              ),
              if (item.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: effectiveConfig.labelColor,
                      fontSize: effectiveConfig.fontSize,
                      fontFamily: effectiveConfig.fontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();

    if (cardWidgets.isNotEmpty) {
      cardWidgets[cardWidgets.length - 1] = GestureDetector(
        onTap: onTap != null ? () => onTap!(categories.last) : null,
        child: Container(
          width: effectiveConfig.cardWidth,
          height: effectiveConfig.cardHeight,
          padding: EdgeInsets.all(effectiveConfig.padding),
          decoration: BoxDecoration(
            color: effectiveConfig.backgroundColor,
            borderRadius: BorderRadius.circular(effectiveConfig.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: effectiveConfig.cardShadowColor,
                blurRadius: effectiveConfig.shadowBlur,
                offset: Offset(0, effectiveConfig.shadowOffsetY),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: SvgPicture.asset(
                  categories.last.svgAssetPath,
                  width: effectiveConfig.iconSize,
                  height: effectiveConfig.iconSize,
                  fit: BoxFit.contain,
                ),
              ),
              if (categories.last.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    categories.last.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: effectiveConfig.labelColor,
                      fontSize: effectiveConfig.fontSize,
                      fontFamily: effectiveConfig.fontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget listView = layout == CategoryLayout.horizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cardWidgets,
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cardWidgets,
              ),
            ),
          );

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: listView,
    );
  }
} 