import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Manages the global theme state across the app.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);