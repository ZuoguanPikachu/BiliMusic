import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bili_music/models/search_result.dart';
import 'package:bili_music/pages/shared/index.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/models/detail_info.dart';
import '../controller.dart';


class SearchResultItemWidget extends StatelessWidget {
  final BiliSearchResult searchResult;
  final searchPageController =  Get.find<SearchPageController>();

  SearchResultItemWidget({super.key, required this.searchResult});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => await searchPageController.play(searchResult),
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
                          onPressed: () async => await _showAddSongDialog(searchResult),
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

Future<void> _showAddSongDialog(BiliSearchResult item) async {
  final searchPageController = Get.find<SearchPageController>();
  final playListController = Get.find<PlayListController>();

  Get.dialog(
    FutureBuilder<DetailInfo>(
      future: searchPageController.getDetailInfo(item),
      builder: (context, snapshot) {

        // === 1. 加载中状态 ===
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // === 2. 错误状态 ===
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error', style: TextStyle(fontFamily: 'Consolas')),
            content: Text('Failed to fetch detail: ${snapshot.error}'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK', style: TextStyle(fontFamily: 'Consolas')),
              )
            ],
          );
        }

        // === 3. 加载成功 ===
        final detail = snapshot.data!;
        final newSong = Song(
          platform: 'bilibili',
          id: item.id,
          cid: detail.cid,
          title: detail.title,
          author: detail.author,
          imageUrl: detail.imageUrl,
          lyricId: detail.lyricId,
          lyricBias: 0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        return SongFormDialog(
          title: 'Add Song',
          song: newSong,
          isBilibili: true,
          onSubmit: (createdSong) async {
            await playListController.addSong(newSong);
            Get.back(); // 关闭 dialog
            Get.snackbar('Tips', 'Song Added Successfully!');
          },
        );
      },
    ),
    barrierDismissible: false,
  );
}
