import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';


class PlayListPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final playerId = 'playlistPage';

  Rx<Duration> duration = Duration.zero.obs;
  Rx<Duration> position = Duration.zero.obs;
  Rx<bool> isPlaying = false.obs;
  Rx<int> currentIndex = (-1).obs;
  Rx<String> currentTitle = ''.obs;
  Rx<String> currentAuthor = ''.obs;

  @override
  void onInit() {
    super.onInit();
    audioPlayService.getPlayerPosition(playerId).listen((p) => position.value = p);
    audioPlayService.getPlayerDuration(playerId).listen((d) => duration.value = d ?? Duration.zero);
    audioPlayService.getPlayerState(playerId).listen((state) async {
      isPlaying.value = state.playing;

      if (state.processingState == ProcessingState.completed && isPlaying.value){
        await playNext();
      }
    });
  }

  Future<Box<Song>> getBox() async {
    if (playListService.isInit) {
      return playListService.getBox();
    } else {
      return await playListService.init();
    }
  }

  Future<void> play(int index) async {
    currentIndex.value = index;

    final box = await getBox();
    final song = box.getAt(index)!;
    currentTitle.value = song.title;
    currentAuthor.value = song.author;

    final audioUrl = await biliService.getAudioUrl(song.bvid, cid: song.cid);
    await audioPlayService.play(playerId, url: audioUrl);
  }

  Future<void> playPrevious() async {
    final length = (await getBox()).length;
    final index = (currentIndex.value + length - 1) % length;
    await play(index);
  }

  Future<void> playNext() async {
    final index = (currentIndex.value + 1) % (await getBox()).length;
    await play(index);
  }

  Future<void> pause() async {
    await audioPlayService.pause(playerId);
  }

  Future<void> resume() async {
    await audioPlayService.play(playerId);
  }

  Future<void> seek(Duration position) async {
    await audioPlayService.seek(playerId, position);
  }

  Future<void> updateSong(Song song) async {
    await playListService.addSong(song);
  }

  Future<void> removeSong(int index) async {
    if (index <= currentIndex.value && currentIndex.value != -1){
      currentIndex.value -= 1;
    }
    await playListService.removeSong(index);
  }
}

class PlayListPage extends StatelessWidget {
  PlayListPage({super.key});
  final controller = Get.put(PlayListPageController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SongList(controller: controller),
          ),
          NowPlayingBar(controller: controller)
        ]
      )
    );
  }
}

class SongList extends StatelessWidget {
  final PlayListPageController controller;
  const SongList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box<Song>>(
      future: controller.getBox(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return ValueListenableBuilder(
            valueListenable: snapshot.data!.listenable(),
            builder: (context, Box box, _) {
              return ListView.builder(
                itemCount: box.length,
                itemBuilder: (context, index) {
                  return SongListItem(index: index, songItem: box.getAt(index), controller: controller);
                }
              );
            }
          );
        } else {
          return const Center(child: Text('Unknown error'));
        }
      },
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
        title: Text(songItem.title, style: TextStyle(fontSize: 24.sp),
        ),
        subtitle: Text(songItem.author, style: TextStyle(fontSize: 20.sp, color: Colors.grey)),
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

class NowPlayingBar extends StatelessWidget {
  final PlayListPageController controller;
  const NowPlayingBar({super.key, required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8).r,
      padding: const EdgeInsets.only(left: 16, right: 4, bottom: 8, top: 16).r,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixedDim,
          borderRadius: BorderRadius.circular(16).r
      ),
      child: Row(
        children: [
          Icon(Icons.library_music_rounded, size: 64.sp, color: Colors.black45,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16, right: 16).r,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(controller.currentTitle.value, style: TextStyle(fontSize: 24.sp))),
                          SizedBox(height: 6.sp),
                          Obx(() => Text(controller.currentAuthor.value, style: TextStyle(fontSize: 20.sp, color: Colors.black45))),
                        ],
                      )
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_outlined),
                          iconSize: 48.sp,
                          onPressed: () async {
                            await controller.playPrevious();
                          }
                        ),
                        Obx(() => IconButton(
                          icon: Icon(controller.isPlaying.value? Icons.pause_circle_outline_outlined : Icons.play_circle_outline_outlined),
                          iconSize: 64.sp,
                          onPressed: () async {
                            if (controller.isPlaying.value){
                              await controller.pause();
                            }
                            else if (controller.currentIndex.value == -1){
                              await controller.play(0);
                            }
                            else{
                              await controller.resume();
                            }
                          }
                        )),
                        IconButton(
                          icon: const Icon(Icons.skip_next_outlined),
                          iconSize: 48.sp,
                          onPressed: () async {
                            await controller.playNext();
                          }
                        ),
                      ]
                    )
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 24.r),
                      trackHeight: 2.r
                  ),
                  child: Obx(() => Slider(
                    value: controller.position.value.inSeconds.toDouble(),
                    min: 0,
                    max: controller.duration.value.inSeconds.toDouble(),
                    onChanged: (value) async {
                      await controller.seek(Duration(seconds: value.toInt()));
                    },
                  ))
                )
              ],
            )
          )
        ],
      )
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
        width: 500.w,
        height: 200.h,
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
            await controller.removeSong(index);
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
            await controller.updateSong(Song(songItem.bvid, songItem.cid, titleController.text, authorController.text));
            Get.back();
          },
        ),
      ],
    )
  );
}


