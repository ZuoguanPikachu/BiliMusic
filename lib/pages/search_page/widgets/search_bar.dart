import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller.dart';


class MusicSearchBar extends StatelessWidget {
  MusicSearchBar({super.key});

  final searchPageController = Get.find<SearchPageController>();
  final textController = TextEditingController();
  final showClearButton = false.obs;

  @override
  Widget build(BuildContext context) {
    textController.addListener(() {
      showClearButton.value = textController.text.isNotEmpty;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Obx(() => Expanded(child: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: const TextStyle(fontFamily: 'Consolas'),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: showClearButton.value ?
              IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                onPressed: () => textController.clear(),
              ) :
              null,
            ),
            onSubmitted: searchPageController.search,
          ))),
          const SizedBox(width: 8),
          SearchSourceDropdown(),
        ],
      )
    );
  }
}

class SearchSourceDropdown extends StatelessWidget {
  SearchSourceDropdown({super.key});
  final searchPageController = Get.find<SearchPageController>();


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: Obx(() => DropdownButton(
          items: searchPageController.platforms.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v){
            if (v != null) {
              searchPageController.selectedPlatform.value = v;
            }
          },
          value: searchPageController.selectedPlatform.value,
          style: const TextStyle(fontFamily: 'Consolas', color: Colors.black),
        ))
      )
    );
  }
}