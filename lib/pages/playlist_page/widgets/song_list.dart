import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/pages/shared/index.dart';
import '../controller.dart';


class SongList extends StatelessWidget {
  const SongList({super.key});
  AudioPlayerController get audioPlayerController => Get.find();
  PlayListController get playListController => Get.find();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: playListController.songBox.listenable(),
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
              for (int i = newIndex; i < oldIndex; i++) {
                needUpdateSongs.add(songs[i].copyWith(timestamp: songs[i+1].timestamp));
              }
            }
            needUpdateSongs.add(songs[oldIndex].copyWith(timestamp: songs[newIndex].timestamp));
            playListController.updateSongs(needUpdateSongs);
          },
          children: [
            for (int i = 0; i < songs.length; i++)
              SongListItem(
                key: ValueKey("${songs[i].id}-${songs[i].cid}"),
                index: i,
                songItem: songs[i],
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
  AudioPlayerController get audioPlayerController => Get.find();

  const SongListItem({super.key, required this.index, required this.songItem});

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
            _showEditDialog(songItem);
          },
        ),
      ),
      onTap: () async {
        await audioPlayerController.play(index);
      },
    );
  }
}

void _showEditDialog(Song song) {
  final playListController = Get.find<PlayListController>();

  Get.dialog(SongFormDialog(
    title: 'Edit Song',
    song: song,
    isBilibili: song.platform == 'bilibili',
    onDelete: () => playListController.removeSong(song),
    onSubmit: (updated) => playListController.updateSong(updated),
  ));
}
