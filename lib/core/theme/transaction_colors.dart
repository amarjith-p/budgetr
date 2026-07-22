import 'package:flutter/material.dart';

class TransactionColors {
  static Color expense(ThemeData theme) => Colors.red.shade600; // Red
  static Color income(ThemeData theme) => Colors.green.shade600;    // Green
  static Color transfer(ThemeData theme) => const Color.fromARGB(255, 193, 155, 1); // Yellow/Orange

  static Color getTypeColor(String type, ThemeData theme) {
    if (type == 'Expense') return expense(theme);
    if (type == 'Income') return income(theme);
    if (type == 'Transfer') return transfer(theme);
    return theme.colorScheme.primary;
  }
}