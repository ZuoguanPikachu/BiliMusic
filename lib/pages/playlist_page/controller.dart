import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/models/play_mode.dart';
import 'package:bili_music/services/netease_service.dart';


class PlayListPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final neteaseService = Get.find<NeteaseService>();
  final playListService = Get.find<PlayListService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playerId = 'playlistPage';
  bool isInitialized = false;

  Rx<Duration> duration = Duration.zero.obs;
  Rx<Duration> position = Duration.zero.obs;
  RxBool isPlaying = false.obs;
  RxInt currentIndex = (-1).obs;
  Rxn<Song> currentSong = Rxn<Song>();
  Rx<PlayMode> playMode = PlayMode.values[Hive.box('play_settings').get('play_mode', defaultValue: 0)].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await audioPlayService.init();
    isInitialized = true;
    audioPlayService.setPlayMode(playerId, playMode.value);
    ever(audioPlayService.currentSong(playerId), (song) => currentSong.value = song);
    ever(audioPlayService.currentIndex(playerId), (index) => currentIndex.value = index);

    audioPlayService.position(playerId).listen((p) => position.value = p);
    audioPlayService.duration(playerId).listen((d) => duration.value = d ?? Duration.zero);
    audioPlayService.playerState(playerId).listen((state) async {
      isPlaying.value = state.playing;

      if (state.processingState == ProcessingState.completed && isPlaying.value){
        if (playMode.value == PlayMode.single){
          await audioPlayService.play(playerId, index: currentIndex.value);
        }
        else{
          await audioPlayService.playNext(playerId);
        }
      }
    });
  }

  Future<void> play(int index) async {
    await audioPlayService.play(playerId, index: index);
  }

  Future<void> playPrevious() async {
    await audioPlayService.playPrevious(playerId);
  }

  Future<void> playNext() async {
    await audioPlayService.playNext(playerId);
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

  Future<void> updateSongs(List<Song> songs) async {
    await playListService.addSongs(songs);
    audioPlayService.updateIndex(playerId);
  }

  Future<void> removeSong(Song song) async {
    await playListService.removeSong(song);
    audioPlayService.updateIndex(playerId);
  }

  void switchPlayMode() async {
    playMode.value = PlayMode.values[(playMode.value.index + 1) % PlayMode.values.length];
    Hive.box('play_settings').put('play_mode', playMode.value.index);
    audioPlayService.setPlayMode(playerId, playMode.value);
  }

  Future<String> getImageUrlByTitleAndAuthor(String title, String author) async {
    return await neteaseService.getImageUrlByTitleAndAuthor(title, author);
  }

  Future<String> getIdByTitleAndAuthor(String title, String author) async {
    return await neteaseService.getIdByTitleAndAuthor(title, author);
  }
}