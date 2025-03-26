import 'package:just_audio/just_audio.dart';


class AudioPlayService {
  final players = {
    'playlistPage': AudioPlayer(),
    'searchPage': AudioPlayer(),
  };

  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
    'Referer': 'https://www.bilibili.com/'
  };

  Future<void> play(String id, {String? url}) async {
    await stop('searchPage');
    await pause('playlistPage');

    AudioPlayer player = players[id]!;

    if (url != null) {
      await player.setUrl(url, headers: headers);
    }
    await player.play();
  }

  Future<void> stop(String id) async {
    await players[id]!.stop();
  }

  Future<void> pause(String id) async {
    await players[id]!.pause();
  }

  Future<void> seek(String id, Duration position) async {
    await players[id]!.seek(position);
  }

  Stream<Duration> getPlayerPosition(String id) => players[id]!.positionStream;
  Stream<Duration?> getPlayerDuration(String id) => players[id]!.durationStream;
  Stream<PlayerState> getPlayerState(String id) => players[id]!.playerStateStream;
}