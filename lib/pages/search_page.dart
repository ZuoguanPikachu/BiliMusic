import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/services/playlist_service.dart';


class SearchPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();

  final playerId = 'searchPage';

  RxList<Map<String, String>> searchResults = <Map<String, String>>[].obs;
  RxBool isLoading = false.obs;

  Future<void> search(String keyword) async{
    try {
      isLoading.value = true;
      final results = await biliService.search(keyword);
      searchResults.value = results;
    } catch (e) {
      Get.snackbar('错误', '$e');
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

  Future<num> getCid(String bvid) async {
    return await biliService.getCid(bvid);
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
  final SearchPageController controller;
  const SearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16).r,
      child: TextField(
        controller: TextEditingController(),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(fontFamily: 'Consolas'),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(const Radius.circular(42).r)),
          prefixIcon: const Icon(Icons.search),
        ),
        onSubmitted: controller.search,
      ),
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
                          onPressed: () => _showAddSongDialog(context, item, controller),
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

void _showAddSongDialog(BuildContext context, Map<String, dynamic> itemInfo, SearchPageController controller) {
  final titleController = TextEditingController(text: itemInfo['title']);
  final authorController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add Song', style: TextStyle(fontFamily: 'Consolas')),
        content: SizedBox(
          width: 500.w,
          height: 200.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final cid = await controller.getCid(itemInfo['bvid']!);
              final song = Song(itemInfo['bvid']!, cid, titleController.text, authorController.text);
              await controller.addToPlaylist(song);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('ADD'),
          )
        ],
      );
    },
  );
}