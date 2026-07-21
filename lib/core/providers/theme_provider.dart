import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Manages the global theme state. Defaults to the system preference.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);