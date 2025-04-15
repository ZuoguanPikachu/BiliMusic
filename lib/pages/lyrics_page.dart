import 'package:bili_music/models/lyrics_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/bili_service.dart';

import '../models/song_model.dart';


class LyricsPageController extends GetxController {
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final biliService = Get.find<BiliService>();

  RxList<LyricsItem> lyrics = <LyricsItem>[].obs;
  RxInt currentLyricsIndex = (-1).obs;

  bool isUserScrolling = false;
  final ScrollController scrollController = ScrollController();
  final playerId = 'playlistPage';

  @override
  void onInit() {
    super.onInit();
    if (audioPlayService.currentIndex(playerId).value != -1) {
      loadLyrics(audioPlayService.currentSong(playerId).value!);
    }
    ever(audioPlayService.currentSong(playerId), (song) => loadLyrics(song!));

    audioPlayService.position(playerId).listen((position) {
      if (lyrics.isNotEmpty) {
        final newIndex = lyrics.lastIndexWhere((lyric) => position >= lyric.time);
        if (newIndex != currentLyricsIndex.value && newIndex >= -1) {
          currentLyricsIndex.value = newIndex;
          if (!isUserScrolling) {
            scrollToCurrentLine();
          }
        }
      }
    });

  }

  void scrollToCurrentLine() {
    if (scrollController.hasClients) {
      final itemHeight = 90.h;
      final targetOffset = currentLyricsIndex.value * itemHeight;
      scrollController.animateTo(
        targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadLyrics(Song song) async {
    final lyrics = await biliService.getLyricsFromSubtitle(song.id, cid: song.cid);
    this.lyrics.value = lyrics;
    currentLyricsIndex.value = -1;
    scrollToCurrentLine();
  }

  void seekToLyric(int index) {
    if (index >= 0 && index < lyrics.length) {
      audioPlayService.seek(playerId, lyrics[index].time);
    }
  }

  void handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      isUserScrolling = true;
    } else if (notification is ScrollEndNotification) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!scrollController.position.isScrollingNotifier.value) {
          isUserScrolling = false;
          scrollToCurrentLine();
        }
      });
    }
  }

  void scrollOnPageLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentLine();
    });
  }
}

class LyricsPage extends StatelessWidget {
  final LyricsPageController lyricsController = Get.put(LyricsPageController(), permanent: true);

  LyricsPage({super.key}) {
    lyricsController.scrollOnPageLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Bili Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42.sp, fontFamily: 'Consolas')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(() => lyricsController.lyrics.isEmpty ?
        const Center(child: Text('No lyrics found.')) :
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            lyricsController.handleScrollNotification(notification);
            return true;
          },
          child: ListView.builder(
            controller: lyricsController.scrollController,
            itemCount: lyricsController.lyrics.length + 14,
            itemBuilder: (context, index) {
              if (index < 7 || index >= lyricsController.lyrics.length + 7) {
                return SizedBox(
                  height: 90.h,
                );
              } else {
                return Obx(() {
                  final isCurrent = index - 7 == lyricsController.currentLyricsIndex.value;
                  final item = lyricsController.lyrics[index - 7];
                  return InkWell(
                    onTap: () => lyricsController.seekToLyric(index - 7),
                    child: SizedBox(
                      height: 90.h,
                      child: Center(
                        child: Text(item.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCurrent? 30.sp : 24.sp,
                            color: isCurrent? Theme.of(context).colorScheme.primary : Colors.black,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        )
                      ),
                    ),
                  );
                });
              }
            },
          )
        )
      )
    );
  }
}