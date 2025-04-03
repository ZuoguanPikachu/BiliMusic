import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/llm_service.dart';


class SearchPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final llmService = Get.find<LLMService>();

  final playerId = 'searchPage';

  RxList<Map<String, String>> searchResults = <Map<String, String>>[].obs;
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

  Future<void> play(String id) async {
    final audioUrl = await biliService.getAudioUrl(id);
    await audioPlayService.play(playerId, url: audioUrl);
  }

  Future<void> addToPlaylist(Song song) async {
    await playListService.addSong(song);
  }

  Future<Map<String, dynamic>> getDetailInfo(Map<String, String> info) async {
    final cid = await biliService.getCid(info['bvid']!);
    final Map<String, dynamic> detailInfo = await llmService.extractInfo(info['title']!);

    if (detailInfo['title'].isEmpty){
      detailInfo['title'] = info['title'];
    }
    detailInfo['cid'] = cid;

    return detailInfo;
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
              itemBuilder: (context, index) => SearchResultItem(item: controller.searchResults[index], controller: controller),
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
      padding: const EdgeInsets.all(16).r,
      child: Obx(() => TextField(
        controller: textController,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(fontFamily: 'Consolas'),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(const Radius.circular(42).r)),
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

class SearchResultItem extends StatelessWidget {
  final Map<String, String> item;
  final SearchPageController controller;

  const SearchResultItem({super.key, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await controller.play(item['bvid']!),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0).r,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18).r,
                  child: CachedNetworkImage(
                    imageUrl: item['pic']!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    width: 270.w,
                    height: 150.h,
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  right: 16.w,
                  child: Container(
                    padding: const EdgeInsets.all(6).r,
                    decoration: BoxDecoration(
                      color: Colors.black45.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8).r,
                    ),
                    child: Text(item['duration']!, style: TextStyle(color: Colors.white, fontSize: 20.sp)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 150.h,
              child: Container(
                padding: const EdgeInsets.only(left: 8.0, right: 16.0, top: 8.0).r,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['title']!,
                      style: TextStyle(fontSize: 24.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['author']!, style: TextStyle(fontSize: 20.sp, color: Colors.grey)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          iconSize: 32.r,
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

Future<void> _showAddSongDialog(Map<String, String> itemInfo, SearchPageController controller) async {
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
      future: controller.getDetailInfo(itemInfo),
      builder: (context, snapshot) {
        List<Widget> contentChildren;
        List<Widget>? actions;

        if (snapshot.hasData) {
          final Map<String, dynamic> detailInfo = snapshot.data!;
          titleController.text = detailInfo['title'];
          authorController.text = detailInfo['author'];

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
                final song = Song(itemInfo['bvid']!, detailInfo['cid'] as num, titleController.text, authorController.text);
                await controller.addToPlaylist(song);
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
            width: 500.w,
            height: 200.h,
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