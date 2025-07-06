import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ClearableTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? tooltip;
  final VoidCallback? onAutoFill;

  const ClearableTextField({
    super.key,
    required this.controller,
    required this.label,
    this.tooltip,
    this.onAutoFill,
  });

  @override
  Widget build(BuildContext context) {
    final showClear = ValueNotifier(controller.text.isNotEmpty);
    controller.addListener(() => showClear.value = controller.text.isNotEmpty);

    Widget textField = ValueListenableBuilder<bool>(
      valueListenable: showClear,
      builder: (_, value, __) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontFamily: 'Consolas'),
            suffixIcon: value
                ? IconButton(
              icon: const Icon(Icons.clear_rounded, color: Colors.grey),
              onPressed: () => controller.clear(),
            )
                : (onAutoFill != null
                ? IconButton(
              tooltip: tooltip ?? 'Auto Fetch',
              icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.grey),
              onPressed: onAutoFill,
            )
                : null),
          ),
        );
      },
    );

    return textField;
  }
}
