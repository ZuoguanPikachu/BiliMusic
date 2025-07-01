import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller.dart';


class MusicSearchBar extends StatelessWidget {
  MusicSearchBar({super.key, required this.controller});

  final SearchPageController controller;
  final textController = TextEditingController();
  final showClearButton = false.obs;

  @override
  Widget build(BuildContext context) {
    textController.addListener(() {
      showClearButton.value = textController.text.isNotEmpty;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() => TextField(
        controller: textController,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(fontFamily: 'Consolas'),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(26))),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: showClearButton.value ?
          IconButton(
            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
            onPressed: () => textController.clear(),
          ) :
          null,
        ),
        onSubmitted: controller.search,
      )),
    );
  }
}