import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/models/song_model.dart';


class PlayListPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final playListService = Get.find<PlayListService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playerId = 'playlistPage';
  bool isInitialized = false;

  Rx<Duration> duration = Duration.zero.obs;
  Rx<Duration> position = Duration.zero.obs;
  RxBool isPlaying = false.obs;
  RxInt currentIndex = (-1).obs;
  Rxn<Song> currentSong = Rxn<Song>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await audioPlayService.init();
    isInitialized = true;
    ever(audioPlayService.currentSong(playerId), (song) => currentSong.value = song);
    ever(audioPlayService.currentIndex(playerId), (index) => currentIndex.value = index);

    audioPlayService.position(playerId).listen((p) => position.value = p);
    audioPlayService.duration(playerId).listen((d) => duration.value = d ?? Duration.zero);
    audioPlayService.playerState(playerId).listen((state) async {
      isPlaying.value = state.playing;

      if (state.processingState == ProcessingState.completed && isPlaying.value){
        await audioPlayService.playNext(playerId);
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

  Future<void> removeSong(Song song) async {
    await playListService.removeSong(song);
    audioPlayService.updateIndex(playerId);
  }
}