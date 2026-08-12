// lib/features/smart_trackers/utils/tracker_field_ui_helper.dart
import 'package:flutter/material.dart';
import '../models/tracker_field_model.dart';

class TrackerFieldUIHelper {
  static Color getTypeColor(TrackerFieldType type) {
    switch (type) {
      case TrackerFieldType.text:
        return Colors.blueAccent.shade400;
      case TrackerFieldType.number:
        return Colors.greenAccent.shade700;
      case TrackerFieldType.currency:
        return Colors.amberAccent.shade700;
      case TrackerFieldType.date:
        return Colors.orangeAccent.shade400;
      case TrackerFieldType.dropdown:
        return Colors.deepPurpleAccent.shade200;
      case TrackerFieldType.toggle:
        return Colors.tealAccent.shade700;
      case TrackerFieldType.radio:
        return Colors.pinkAccent.shade200;
      case TrackerFieldType.checkbox:
        return Colors.indigoAccent.shade200;
      case TrackerFieldType.serialNo:
        return Colors.redAccent.shade400;
      case TrackerFieldType.formula:
        return Colors.cyanAccent.shade700; // <-- ADDED
    }
  }

  static IconData getTypeIcon(TrackerFieldType type) {
    switch (type) {
      case TrackerFieldType.text:
        return Icons.text_fields_rounded;
      case TrackerFieldType.number:
        return Icons.numbers_rounded;
      case TrackerFieldType.currency:
        return Icons.payments_rounded;
      case TrackerFieldType.date:
        return Icons.calendar_month_rounded;
      case TrackerFieldType.dropdown:
        return Icons.arrow_drop_down_circle_rounded;
      case TrackerFieldType.toggle:
        return Icons.toggle_on_rounded;
      case TrackerFieldType.radio:
        return Icons.radio_button_checked_rounded;
      case TrackerFieldType.checkbox:
        return Icons.check_box_rounded;
      case TrackerFieldType.serialNo:
        return Icons.pin_rounded;
      case TrackerFieldType.formula:
        return Icons.functions_rounded; // <-- ADDED
    }
  }

  static String formatEnumName(String name) {
    return name[0].toUpperCase() + name.substring(1);
  }
}
