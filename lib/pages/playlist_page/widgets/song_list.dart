import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bili_music/models/song_model.dart';
import '../controller.dart';


class SongList extends StatelessWidget {
  final PlayListPageController controller;
  const SongList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.playListService.getBox().listenable(),
      builder: (context, Box<Song> box, _) {
        List<Song> songs = box.values.toList();
        songs.sort((a, b) => -a.timestamp.compareTo(b.timestamp));

        return ReorderableListView(
          buildDefaultDragHandles: true,
          onReorder: (oldIndex, newIndex) async {
            List<Song> needUpdateSongs = [];
            if (newIndex > oldIndex) {
              newIndex -= 1;
              for (int i = oldIndex+1; i <= newIndex; i++) {
                needUpdateSongs.add(songs[i].copyWith(timestamp: songs[i-1].timestamp));
              }
            } else {
              // needUpdateSongs = [songs[oldIndex].copyWith(timestamp: songs[newIndex].timestamp)];
              for (int i = newIndex; i < oldIndex; i++) {
                needUpdateSongs.add(songs[i].copyWith(timestamp: songs[i+1].timestamp));
              }
            }
            needUpdateSongs.add(songs[oldIndex].copyWith(timestamp: songs[newIndex].timestamp));
            controller.updateSongs(needUpdateSongs);
          },
          children: [
            for (int i = 0; i < songs.length; i++)
              SongListItem(
                key: ValueKey("${songs[i].id}-${songs[i].cid}"),
                index: i,
                songItem: songs[i],
                controller: controller,
              )
          ],
        );
      }
    );
  }
}

class SongListItem extends StatelessWidget {
  final int index;
  final Song songItem;
  final PlayListPageController controller;

  const SongListItem({super.key, required this.index, required this.songItem, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: ListTile(
        leading: const Icon(Icons.music_note_rounded),
        title: Text(songItem.title, style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(songItem.author, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {
            _showEditDialog(index, songItem, controller);
          },
        ),
      ),
      onTap: () async {
        await controller.play(index);
      },
    );
  }
}

void _showEditDialog(int index, Song songItem, PlayListPageController controller) {
  final titleController = TextEditingController(text: songItem.title);
  final authorController = TextEditingController(text: songItem.author);
  final imageUrlController = TextEditingController(text: songItem.imageUrl);
  final lyricIdController = TextEditingController(text: songItem.lyricId);
  final lyricBiasController = TextEditingController(text: songItem.lyricBias.toString());

  final showTitleClearButton = true.obs;
  final showAuthorClearButton = true.obs;
  final showImageUrlClearButton = true.obs;
  titleController.addListener(() {
    showTitleClearButton.value = titleController.text.isNotEmpty;
  });
  authorController.addListener(() {
    showAuthorClearButton.value = authorController.text.isNotEmpty;
  });
  imageUrlController.addListener(() {
    showImageUrlClearButton.value = imageUrlController.text.isNotEmpty;
  });

  final dialogHeight = songItem.platform == 'bilibili' ? 370.0 : 220.0;

  Get.dialog(
    AlertDialog(
      title: const Text('Edit Song', style: TextStyle(fontFamily: 'Consolas')),
      content: SizedBox(
        width: 500,
        height: dialogHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showTitleClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () => titleController.clear(),
                ):
                null,
              ),
            )),
            Obx(() => TextField(
              decoration: InputDecoration(
                labelText: 'Author',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showAuthorClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  onPressed: () => authorController.clear(),
                ):
                null,
              ),
              controller: authorController,
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
            )),
            if (songItem.platform == 'bilibili')
              TextField(
                controller: lyricIdController,
                decoration: InputDecoration(
                  labelText: 'Lyric Id (Netease)',
                  labelStyle: const TextStyle(fontFamily: 'Consolas'),
                  suffixIcon: IconButton(
                    tooltip: 'Auto Fetch',
                    icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.grey),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty && authorController.text.isNotEmpty) {
                        lyricIdController.text = await controller.getIdByTitleAndAuthor(
                          titleController.text,
                          authorController.text,
                        );
                      }
                    }
                  )
                ),
              ),
            if (songItem.platform == 'bilibili')
              TextField(
                controller: lyricBiasController,
                decoration: const InputDecoration(
                  labelText: 'Lyric Bias (ms)',
                  labelStyle: TextStyle(fontFamily: 'Consolas'),
                  helperText: 'Positive: lyrics appear later; Negative: earlier',
                ),
              )
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('DELETE', style: TextStyle(color: Colors.red, fontFamily: 'Consolas')),
          onPressed: () async {
            await controller.removeSong(songItem);
            Get.back();
          },
        ),
        TextButton(
          child: const Text('CANCEL', style: TextStyle(fontFamily: 'Consolas')),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: const Text('SAVE', style: TextStyle(fontFamily: 'Consolas')),
          onPressed: () async {
            await controller.updateSong(
              Song(
                platform: songItem.platform,
                id: songItem.id,
                cid: songItem.cid,
                title: titleController.text,
                author: authorController.text,
                imageUrl: imageUrlController.text,
                lyricId: lyricIdController.text,
                lyricBias: lyricBiasController.text.isEmpty ? 0 : int.parse(lyricBiasController.text),
                timestamp: songItem.timestamp
              )
            );
            Get.back();
          },
        ),
      ],
    )
  );
}