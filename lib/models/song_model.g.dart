// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      platform: fields[0] as String,
      id: fields[1] as String,
      cid: fields[2] as num,
      title: fields[3] as String,
      author: fields[4] as String,
      imageUrl: fields[5] as String,
      lyricId: fields[6] as String,
      lyricBias: fields[7] as int,
      timestamp: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.platform)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.cid)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.author)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.lyricId)
      ..writeByte(7)
      ..write(obj.lyricBias)
      ..writeByte(8)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
