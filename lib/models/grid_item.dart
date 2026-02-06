import 'package:flutter/material.dart';

class GridItem {
  String title;
  String image;
  Widget page;

  GridItem({
    required this.title,
    required this.image,
    required this.page,
  });

  // Convert to Map for SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "image": image,
    };
  }
}
