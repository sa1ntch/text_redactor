import 'package:flutter/material.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: child,
          ),
        ),
      ),
    );
  }
}
