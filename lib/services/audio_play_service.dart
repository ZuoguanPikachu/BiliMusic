import 'dart:math';
import 'package:bili_music/models/search_result_item.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/models/play_mode.dart';
import 'bili_service.dart';
import 'package:get/get.dart';


class AudioPlayService {
  late PlaylistAudioPlayer playlistAudioPlayer;
  late AudioPlayer searchResultAudioPlayer;

  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
    'Referer': 'https://www.bilibili.com/'
  };

  Future<void> init() async {
    playlistAudioPlayer = await initPlaylistAudioPlayer();
    searchResultAudioPlayer = AudioPlayer();
  }

  void setPlayMode(String id, PlayMode playMode){
    if (id == 'playlistPage'){
      playlistAudioPlayer.setPlayMode(playMode);
    }else{
      throw Exception('Invalid id');
    }
  }

  Future<void> play(String id, {int? index, SearchResultItem? searchResultItem}) async {
    await stop('searchPage');
    await pause('playlistPage');

    if (id == 'playlistPage' && index != null){
      playlistAudioPlayer.playByIndex(index);
      await playlistAudioPlayer.play();
    } else if (id == 'playlistPage' && index == null){
      await playlistAudioPlayer.play();
    } else if (id =='searchPage' && searchResultItem!= null){
      final url = await getAudioUrl(searchResultItem.id);
      await searchResultAudioPlayer.setUrl(url, headers: headers);
      await searchResultAudioPlayer.play();
    }
  }

  Future<void> playPrevious(String id) async {
    if (id == 'playlistPage') {
      await playlistAudioPlayer.skipToPrevious();
    }
  }

  Future<void> playNext(String id) async {
    if (id == 'playlistPage') {
      await playlistAudioPlayer.skipToNext();
    }
  }

  Future<void> stop(String id) async {
    if (id == 'playlistPage') {
      await playlistAudioPlayer.stop();
    } else if (id =='searchPage') {
      await searchResultAudioPlayer.stop();
    }
  }

  Future<void> pause(String id) async {
    if (id == 'playlistPage') {
      await playlistAudioPlayer.pause();
    } else if (id =='searchPage') {
      await searchResultAudioPlayer.pause();
    }
  }

  Future<void> seek(String id, Duration position) async {
    if (id == 'playlistPage') {
      await playlistAudioPlayer.audioPlayer.seek(position);
    } else if (id =='searchPage') {
      await searchResultAudioPlayer.seek(position);
    }
  }

  Stream<Duration> position(String id) {
    if (id == 'playlistPage') {
      return playlistAudioPlayer.audioPlayer.positionStream;
    } else if (id =='searchPage') {
      return searchResultAudioPlayer.positionStream;
    }

    throw Exception('Invalid id');
  }

  Stream<Duration?> duration(String id) {
    if (id == 'playlistPage') {
      return playlistAudioPlayer.audioPlayer.durationStream;
    } else if (id =='searchPage') {
      return searchResultAudioPlayer.durationStream;
    }

    throw Exception('Invalid id');
  }

  Stream<PlayerState> playerState(String id) {
    if (id == 'playlistPage') {
      return playlistAudioPlayer.audioPlayer.playerStateStream;
    } else if (id =='searchPage') {
      return searchResultAudioPlayer.playerStateStream;
    }

    throw Exception('Invalid id');
  }

  Rxn<Song> currentSong(String id) {
    if (id == 'playlistPage') {
      return playlistAudioPlayer.currentSong;
    }
    throw Exception('Invalid id');
  }

  RxInt currentIndex(String id){
    if (id == 'playlistPage') {
      return playlistAudioPlayer.currentIndex;
    }
    throw Exception('Invalid id');
  }

  void updateIndex(String id){
    if (id == 'playlistPage') {
      playlistAudioPlayer.updateIndex();
    }
  }
}

class PlaylistAudioPlayer extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer audioPlayer = AudioPlayer();
  final playListService = Get.find<PlayListService>();
  final Rxn<Song> currentSong = Rxn<Song>();
  final RxInt currentIndex = (-1).obs;
  late PlayMode playMode;
  List<Song> shuffledSongs = [];

  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
    'Referer': 'https://www.bilibili.com/'
  };

  PlaylistAudioPlayer() {
    audioPlayer.playbackEventStream.map(_transformEvent).pipe(playbackState);

    audioPlayer.positionStream.listen((_) {
      mediaItem.add(mediaItem.value?.copyWith(duration: audioPlayer.duration));
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: {MediaAction.seek},
      playing: audioPlayer.playing,
      processingState: audioPlayer.processingState == ProcessingState.completed
        ? AudioProcessingState.completed
        : AudioProcessingState.ready,
      updatePosition: audioPlayer.position,
      bufferedPosition: audioPlayer.bufferedPosition,
      speed: audioPlayer.speed,
    );
  }

  void setMediaItem(Song song) {
    currentSong.value = song;
    mediaItem.add(MediaItem(
      id: '${song.id}-${song.cid}',
      title: song.title,
      artist: song.author,
      duration: audioPlayer.duration,
    ));
  }

  void setPlayMode(PlayMode playMode) {
    this.playMode = playMode;
  }

  Future<void> playByIndex(int index) async {
    currentIndex.value = index;
    List<Song> songs = playListService.getBox().values.toList();
    songs.sort((a, b) => -a.timestamp.compareTo(b.timestamp));
    final song = songs[index];
    setMediaItem(song);
    await audioPlayer.setUrl(await getAudioUrl(song.id, cid: song.cid), headers: headers);
    await play();
  }

  void updateIndex(){
    if (currentIndex.value == -1){
      return;
    }

    List<Song> songs = playListService.getBox().values.toList();
    songs.sort((a, b) => -a.timestamp.compareTo(b.timestamp));

    final index = songs.indexWhere((song) => song.id == currentSong.value!.id && song.cid == currentSong.value!.cid);
    if (index == -1){
      currentIndex.value -= 1;
    } else {
      currentIndex.value = index;
    }
  }

  @override
  Future<void> play() async {
    await audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await audioPlayer.stop();
  }

  @override
  Future<void> skipToPrevious() async {
    final List<Song> songs = playListService.getBox().values.toList();
    final length = songs.length;
    int index;
    if (currentIndex.value == -1 || length == 1){
      index = 0;
    }
    else if (playMode == PlayMode.single || playMode == PlayMode.loop){
      index = (currentIndex.value + length - 1) % length;
    }
    else {
      index = shuffleIndex(songs);
    }

    currentIndex.value = index;
    await playByIndex(index);
  }

  @override
  Future<void> skipToNext() async {
    final List<Song> songs = playListService.getBox().values.toList();
    final length = songs.length;
    int index;
    if (currentIndex.value == -1 || length == 1){
      index = 0;
    }
    else if (playMode == PlayMode.single || playMode == PlayMode.loop){
      index = (currentIndex.value + 1) % length;
    }
    else {
      index = shuffleIndex(songs);
    }

    currentIndex.value = index;
    await playByIndex(index);
  }

  int shuffleIndex(List<Song> songs){
    var random = Random();
    int index;
    do {
      index = random.nextInt(songs.length);
    } while(songs[index].id == currentSong.value!.id && songs[index].cid == currentSong.value!.cid);

    return index;
  }
}

Future<PlaylistAudioPlayer> initPlaylistAudioPlayer() async {
  return await AudioService.init(
    builder: () => PlaylistAudioPlayer(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.bili_music.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'mipmap/ic_launcher'
    ),
  );
}

Future<String> getAudioUrl(String id, {num? cid}) async {
  final biliService = Get.find<BiliService>();
  return await biliService.getAudioUrl(id, cid: cid);
}

