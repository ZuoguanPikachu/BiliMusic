import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bili_music/models/search_result.dart';
import 'package:bili_music/models/detail_info.dart';
import '../controller.dart';


class SearchResultItemWidget extends StatelessWidget {
  final BiliSearchResult searchResult;
  final SearchPageController controller;

  const SearchResultItemWidget({super.key, required this.searchResult, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await controller.play(searchResult),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: searchResult.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    width: 170,
                    height: 95,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black45.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(searchResult.duration, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Container(
                padding: const EdgeInsets.only(left: 2, right: 8.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(searchResult.title,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(searchResult.author, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          iconSize: 20,
                          onPressed: () async => await _showAddSongDialog(searchResult, controller),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddSongDialog(BiliSearchResult item, SearchPageController controller) async {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final imageUrlController = TextEditingController();

  final showTitleClearButton = false.obs;
  final showAuthorClearButton = false.obs;
  final showImageUrlClearButton = false.obs;

  titleController.addListener(() {
    showTitleClearButton.value = titleController.text.isNotEmpty;
  });
  authorController.addListener(() {
    showAuthorClearButton.value = authorController.text.isNotEmpty;
  });
  imageUrlController.addListener(() {
    showImageUrlClearButton.value = imageUrlController.text.isNotEmpty;
  });

  Get.dialog(
    FutureBuilder(
      future: controller.getDetailInfo(item),
      builder: (context, snapshot) {
        List<Widget> contentChildren;
        List<Widget>? actions;

        if (snapshot.hasData) {
          final DetailInfo detailInfo = snapshot.data!;
          titleController.text = detailInfo.title;
          authorController.text = detailInfo.author;
          imageUrlController.text = detailInfo.imageUrl;

          contentChildren = [
            Obx(() => TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showTitleClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () => titleController.clear(),
                ) :
                null,
              ),
            )),
            Obx(() => TextField(
              controller: authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showAuthorClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () => authorController.clear(),
                ) :
                null,
              ),
            )),
            Obx(() => TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image Url',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showImageUrlClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () => imageUrlController.clear(),
                ) :
                IconButton(
                  tooltip: 'Auto Fetch',
                  icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.grey),
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && authorController.text.isNotEmpty) {
                      imageUrlController.text = await controller.getImageUrlByTitleAndAuthor(
                        titleController.text,
                        authorController.text,
                      );
                    }
                  },
                )
              ),
            ))
          ];
          actions = [
            TextButton(onPressed: () => Get.back(), child: const Text('CANCEL', style: TextStyle(fontFamily: 'Consolas'))),
            TextButton(
              onPressed: () async {
                await controller.addToPlaylist(item.id, detailInfo.cid, titleController.text, authorController.text, imageUrlController.text);
                Get.back();
                Get.snackbar('Tips', 'Song Added Successfully!');
              },
              child: const Text('ADD', style: TextStyle(fontFamily: 'Consolas')),
            )
          ];
        } else if (snapshot.hasError) {
          contentChildren = [
            Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontFamily: 'Consolas')))
          ];
          actions = [
            TextButton(onPressed: () => Get.back(), child: const Text('OK', style: TextStyle(fontFamily: 'Consolas'))),
          ];
        } else {
          contentChildren = [
            const Center(child: CircularProgressIndicator())
          ];
          actions = [
            TextButton(onPressed: () => Get.back(), child: const Text('CANCEL', style: TextStyle(fontFamily: 'Consolas'))),
          ];
        }

        return AlertDialog(
          title: const Text('Add Song', style: TextStyle(fontFamily: 'Consolas')),
          content: SizedBox(
            width: 500,
            height: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: contentChildren,
            ),
          ),
          actions: actions,
        );
      }
    )
  );
}