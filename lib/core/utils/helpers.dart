import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }
}
