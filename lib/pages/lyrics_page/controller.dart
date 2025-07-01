import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/models/lyrics_item.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/bili_service.dart';


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
      const itemHeight = 90.0;
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