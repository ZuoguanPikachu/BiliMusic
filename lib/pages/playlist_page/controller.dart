import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/models/play_mode.dart';
import 'package:bili_music/services/netease_service.dart';


class AudioPlayerController extends GetxController {
  final audioPlayService = Get.find<AudioPlayService>();
  final playerId = 'playlistPage';

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
    audioPlayService.setPlayMode(playerId, playMode.value);

    ever(audioPlayService.currentSong(playerId), (song) => currentSong.value = song);
    ever(audioPlayService.currentIndex(playerId), (index) => currentIndex.value = index);
    audioPlayService.position(playerId).listen((p) => position.value = p);
    audioPlayService.duration(playerId).listen((d) => duration.value = d ?? Duration.zero);
    audioPlayService.playerState(playerId).listen((state) => _onPlayerState(state));
  }

  void _onPlayerState(PlayerState state) async {
    isPlaying.value = state.playing;
    if (state.processingState == ProcessingState.completed && isPlaying.value) {
      if (playMode.value == PlayMode.single) {
        await audioPlayService.play(playerId, index: currentIndex.value);
      } else {
        await audioPlayService.playNext(playerId);
      }
    }
  }

  Future<void> play(int index) async => audioPlayService.play(playerId, index: index);
  Future<void> pause() async => audioPlayService.pause(playerId);
  Future<void> resume() async => audioPlayService.play(playerId);
  Future<void> seek(Duration pos) async => audioPlayService.seek(playerId, pos);
  Future<void> playPrevious() async => audioPlayService.playPrevious(playerId);
  Future<void> playNext() async => audioPlayService.playNext(playerId);

  void switchPlayMode() {
    playMode.value = PlayMode.values[(playMode.value.index + 1) % PlayMode.values.length];
    Hive.box('play_settings').put('play_mode', playMode.value.index);
    audioPlayService.setPlayMode(playerId, playMode.value);
  }
}

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

  Box<Song> get songBox => playListService.getBox();
}
