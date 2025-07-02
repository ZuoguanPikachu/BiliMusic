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
            List<Song> needUpdateSongs;
            if (newIndex > oldIndex) {
              newIndex -= 1;
              needUpdateSongs = [Song(songs[oldIndex].id, songs[oldIndex].cid, songs[oldIndex].title, songs[oldIndex].author, songs[newIndex].timestamp)];
              for (int i = oldIndex+1; i <= newIndex; i++) {
                needUpdateSongs.add(Song(songs[i].id, songs[i].cid, songs[i].title, songs[i].author, songs[i-1].timestamp));
              }
            } else {
              needUpdateSongs = [Song(songs[oldIndex].id, songs[oldIndex].cid, songs[oldIndex].title, songs[oldIndex].author, songs[newIndex].timestamp)];
              for (int i = newIndex; i < oldIndex; i++) {
                needUpdateSongs.add(Song(songs[i].id, songs[i].cid, songs[i].title, songs[i].author, songs[i+1].timestamp));
              }
            }
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

  final showTitleClearButton = true.obs;
  final showAuthorClearButton = true.obs;
  titleController.addListener(() {
    showTitleClearButton.value = titleController.text.isNotEmpty;
  });
  authorController.addListener(() {
    showAuthorClearButton.value = authorController.text.isNotEmpty;
  });

  Get.dialog(
    AlertDialog(
      title: const Text('Edit Song', style: TextStyle(fontFamily: 'Consolas')),
      content: SizedBox(
        width: 500,
        height: 120,
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
            await controller.updateSong(Song(songItem.id, songItem.cid, titleController.text, authorController.text, songItem.timestamp));
            Get.back();
          },
        ),
      ],
    )
  );
}