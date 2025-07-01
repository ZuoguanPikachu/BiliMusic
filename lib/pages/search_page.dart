import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/llm_service.dart';
import 'package:bili_music/models/search_result_item.dart';
import 'package:bili_music/models/detail_info.dart';



class SearchPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final llmService = Get.find<LLMService>();
  final playerId = 'searchPage';

  RxList<SearchResultItem> searchResults = <SearchResultItem>[].obs;
  RxBool isLoading = false.obs;

  Future<void> search(String keyword) async{
    try {
      isLoading.value = true;
      final results = await biliService.search(keyword);
      searchResults.value = results;
    } catch (e) {
      Get.snackbar('Error', '$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> play(SearchResultItem item) async {
    await audioPlayService.play(playerId, searchResultItem: item);
  }

  Future<void> addToPlaylist(Song song) async {
    await playListService.addSong(song);
  }

  Future<DetailInfo> getDetailInfo(SearchResultItem info) async {
    final results = await Future.wait([
      llmService.extractInfo(info.title),
      biliService.getCid(info.id),
    ]);

    final detailInfo = results[0] as DetailInfo;
    final cid = results[1] as num;

    detailInfo.title ??= info.title;
    detailInfo.cid = cid;

    return detailInfo;
  }

  void updatePlaylistPlayerIndex() {
    audioPlayService.updateIndex('playlistPage');
  }
}

class SearchPage extends StatelessWidget {
  final SearchPageController controller = Get.put(SearchPageController());
  SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(controller: controller),
        Expanded(
          child: Obx(() => controller.isLoading.value ?
            const Center(child: CircularProgressIndicator()) :
            ListView.builder(
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) => SearchResultItemWidget(item: controller.searchResults[index], controller: controller),
            ),
          ),
        ),
      ]
    );
  }
}

class SearchBar extends StatelessWidget {
  SearchBar({super.key, required this.controller});

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

class SearchResultItemWidget extends StatelessWidget {
  final SearchResultItem item;
  final SearchPageController controller;

  const SearchResultItemWidget({super.key, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await controller.play(item),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
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
                    child: Text(item.duration, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
                    Text(item.title,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.author, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          iconSize: 20,
                          onPressed: () async => await _showAddSongDialog(item, controller),
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

Future<void> _showAddSongDialog(SearchResultItem item, SearchPageController controller) async {
  final titleController = TextEditingController();
  final authorController = TextEditingController();

  final showTitleClearButton = false.obs;
  final showAuthorClearButton = false.obs;
  titleController.addListener(() {
    showTitleClearButton.value = titleController.text.isNotEmpty;
  });
  authorController.addListener(() {
    showAuthorClearButton.value = authorController.text.isNotEmpty;
  });

  Get.dialog(
    FutureBuilder(
      future: controller.getDetailInfo(item),
      builder: (context, snapshot) {
        List<Widget> contentChildren;
        List<Widget>? actions;

        if (snapshot.hasData) {
          final DetailInfo detailInfo = snapshot.data!;
          titleController.text = detailInfo.title!;
          if (detailInfo.author != null) {
            authorController.text = detailInfo.author!;
          }

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
          ];
          actions = [
            TextButton(onPressed: () => Get.back(), child: const Text('CANCEL', style: TextStyle(fontFamily: 'Consolas'))),
            TextButton(
              onPressed: () async {
                final song = Song(item.id, detailInfo.cid, titleController.text, authorController.text);
                await controller.addToPlaylist(song);
                controller.updatePlaylistPlayerIndex();
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
            height: 150,
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