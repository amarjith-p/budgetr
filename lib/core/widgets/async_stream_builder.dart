import 'package:flutter/material.dart';
import 'modern_loader.dart';

class AsyncStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget? loadingWidget;

  const AsyncStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: loadingWidget ?? const ModernLoader());
        }

        if (snapshot.hasError) {
          return Center(
            child: errorBuilder != null
                ? errorBuilder!(context, snapshot.error!)
                : Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
          );
        }

        final isEmpty =
            !snapshot.hasData ||
            (snapshot.data is List && (snapshot.data as List).isEmpty);

        if (isEmpty) {
          return Center(
            child: emptyBuilder != null
                ? emptyBuilder!(context)
                : const Text(
                    "No Data Available",
                    style: TextStyle(color: Colors.white54),
                  ),
          );
        }

        return builder(context, snapshot.data!);
      },
    );
  }
}
