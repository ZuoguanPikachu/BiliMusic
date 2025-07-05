import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String platform;

  @HiveField(1)
  String id;

  @HiveField(2)
  num cid;

  @HiveField(3)
  String title;

  @HiveField(4)
  String author;

  @HiveField(5)
  String imageUrl;

  @HiveField(6)
  String lyricId;

  @HiveField(7)
  int lyricBias;

  @HiveField(8)
  int timestamp;

  Song({
    required this.platform,
    required this.id,
    required this.cid,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.lyricId,
    required this.lyricBias,
    required this.timestamp,
  });

  Song copyWith({
    String? platform,
    String? id,
    num? cid,
    String? title,
    String? author,
    String? imageUrl,
    String? lyricId,
    int? lyricBias,
    int? timestamp,
  }) {
    return Song(
      platform: this.platform,
      id: id ?? this.id,
      cid: cid ?? this.cid,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      lyricId: this.lyricId,
      lyricBias: this.lyricBias,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}