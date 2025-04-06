import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  num cid;

  @HiveField(2)
  String title;

  @HiveField(3)
  String author;

  Song(this.id, this.cid, this.title, this.author);
}