import 'package:bili_music/pages/search_page/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/pages/search_page/widgets/search_result_item_widget.dart';
import 'controller.dart';


class SearchPage extends StatelessWidget {
  final SearchPageController controller = Get.put(SearchPageController());
  SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MusicSearchBar(controller: controller),
        Expanded(
          child: Obx(() => controller.isLoading.value ?
            const Center(child: CircularProgressIndicator()) :
            ListView.builder(
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) => SearchResultItemWidget(searchResult: controller.searchResults[index]),
            ),
          ),
        ),
      ]
    );
  }
}
