import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:bili_music/models/song_model.dart';

class PlayListService {
  static const playlist = 'playlist';
  bool isInit = false;

  Future<Box<Song>> init() async {
    Hive.registerAdapter(SongAdapter());
    isInit = true;
    return await Hive.openBox<Song>(playlist);
  }

  Box<Song> getBox() {
    return Hive.box<Song>(playlist);
  }

  List<Song> getPlaylist() {
    final box = getBox();
    return box.values.toList();
  }

  Future<void> addSong(Song song) async {
    final box = getBox();
    await box.put('${song.bvid}-${song.cid}', song);
  }

  Future<void> removeSong(int index) async {
    final box = getBox();
    box.deleteAt(index);
  }
}
