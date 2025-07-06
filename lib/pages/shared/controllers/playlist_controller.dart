import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/models/song_model.dart';


class PlayListController extends GetxController {
  final playListService = Get.find<PlayListService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playerId = 'playlistPage';


  Future<void> updateSong(Song song) async => playListService.addSong(song);

  Future<void> updateSongs(List<Song> songs) async {
    await playListService.addSongs(songs);
    audioPlayService.updateIndex(playerId);
  }

  Future<void> removeSong(Song song) async {
    await playListService.removeSong(song);
    audioPlayService.updateIndex(playerId);
  }

  Future<void> addSong(Song song) async {
    await playListService.addSong(song);
    audioPlayService.updateIndex(playerId);
  }

  Box<Song> get songBox => playListService.getBox();
}