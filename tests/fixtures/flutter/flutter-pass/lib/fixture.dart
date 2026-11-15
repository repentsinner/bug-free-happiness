import 'package:flutter/widgets.dart';

/// Shows a greeting.
class Greeting extends StatelessWidget {
  /// Creates a greeting for [name].
  const Greeting({super.key, required this.name});

  /// Who the greeting addresses.
  final String name;

  @override
  Widget build(BuildContext context) =>
      Text('Hello, $name', textDirection: TextDirection.ltr);
}
