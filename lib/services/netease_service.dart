import 'dart:convert';
import 'dart:math';
import 'package:bili_music/models/search_result.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import 'package:bili_music/models/lyrics_item.dart';


class WEAPIEncryptor {
  static const String _pubExp = '010001';
  static const String _pubMod = '00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7';
  static const String _nonceKey = '0CoJUm6Qyw8W8jud';

  static Map<String, String> encryptRequest(String data) {
    final randomKey = _generateRandomString(16);
    final firstEncrypt = _aesEncrypt(data, _nonceKey);
    final secondEncrypt = _aesEncrypt(firstEncrypt, randomKey);
    final encSecKey = _rsaEncrypt(randomKey, _pubMod, _pubExp);
    return {
      'params': secondEncrypt,
      'encSecKey': encSecKey,
    };
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _aesEncrypt(String text, String key) {
    final iv = encrypt.IV.fromUtf8('0102030405060708');
    final encryptor = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key.fromUtf8(key),
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
    final encrypted = encryptor.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  static String _rsaEncrypt(String text, String pubKeyModHex, String pubKeyExpHex) {
    final modulus = BigInt.parse(pubKeyModHex, radix: 16);
    final exponent = BigInt.parse(pubKeyExpHex, radix: 16);

    final codeUnits = text.codeUnits.toList();
    while (codeUnits.length % 126 != 0) {
      codeUnits.add(0);
    }

    List<String> encryptedChunks = [];

    for (int i = 0; i < codeUnits.length; i += 126) {
      final chunk = codeUnits.sublist(i, i + 126);

      List<int> digits = [];
      for (int j = 0; j < chunk.length; j += 2) {
        int low = chunk[j];
        int high = (j + 1 < chunk.length) ? chunk[j + 1] : 0;
        digits.add(low + (high << 8));
      }

      BigInt bigInt = BigInt.zero;
      for (int k = 0; k < digits.length; k++) {
        bigInt += BigInt.from(digits[k]) << (16 * k);
      }

      BigInt encrypted = bigInt.modPow(exponent, modulus);
      encryptedChunks.add(encrypted.toRadixString(16));
    }

    return encryptedChunks.join(' ');
  }
}

class NeteaseService {
  late Dio dio;

  NeteaseService() {
    dio = Dio(
      BaseOptions(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
          'Referer': 'https://music.163.com/',
          'Origin': 'https://music.163.com',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      ),
    );
  }

  Future<List<SearchResult>> search(String s, {int searchType=1, int offset=0, int limit=10}) async {
    if (s.contains('https://163cn.tv/')){
      final response = await dio.get(extractUrl(s)!);
      return await searchById(extractSongId(response.realUri.toString())!);
    }
    else if (s.contains('https://music.163.com/') && s.contains('song?id=')){
      return await searchById(extractSongId(s)!);
    }
    else if (RegExp(r'^\d+$').hasMatch(s)){
      return await searchById(s);
    }

    final payload = {
      's': s,
      'type': searchType,
      'offset': offset,
      'limit': limit,
    };
    final encrypted = WEAPIEncryptor.encryptRequest(json.encode(payload));

    try {
      final response = await dio.post('https://music.163.com/weapi/cloudsearch/pc', data: encrypted);
      final jsonContent = json.decode(response.data);

      List<dynamic> songs = jsonContent['result']['songs'];
      List<SearchResult> results = await Future.wait(songs.map((song) async {
        String id = song['id'].toString();
        String title = song['name'];
        String author = (song['ar'] as List)
          .map((artist) => artist['name'])
          .join(' ');
        String duration = formatDuration(song['dt']);
        String imageUrl = await getImageUrl(id: id);

        return SearchResult('Netease', id, title, author, imageUrl, duration);
      }));

      return results;
    } on DioException catch (e) {
      throw Exception('Failed to search in Netease Cloud Music: ${e.message}');
    }
  }

  Future<List<SearchResult>> searchById(String id) async {
    try {
      final response = await dio.get('https://music.163.com/song', queryParameters: {'id': id});
      final html = response.data;
      Document document = parse(html);

      Element? titleMeta = document.head?.querySelector('meta[property="og:title"]');
      String title = titleMeta?.attributes['content'] ?? '';

      Element? artistMeta = document.head?.querySelector('meta[property="og:music:artist"]');
      String artist = artistMeta?.attributes['content'] ?? '';
      artist = artist.replaceAll('/', ' ');

      Element? durationMeta = document.head?.querySelector('meta[property="music:duration"]');
      String duration = durationMeta?.attributes['content'] ?? '';
      duration = formatDurationFromStr(duration);

      String imageUrl = await getImageUrl(id: id);
      return [SearchResult('Netease', id, title, artist, imageUrl, duration)];
    } on DioException catch (e) {
      throw Exception('Failed to search in Netease Cloud Music: ${e.message}');
    }
  }

  Future<String> getAudioUrl(String id, {String level='exhigh', String encode_type='acc'}) async {
    final payload = {"ids": [id], "level": level, "encodeType": encode_type};
    final encrypted = WEAPIEncryptor.encryptRequest(json.encode(payload));

    try {
      final response = await dio.post('https://music.163.com/weapi/song/enhance/player/url/v1', data: encrypted);
      final jsonContent = json.decode(response.data);
      final url = jsonContent['data'][0]['url'];

      if (url == null) {
        throw Exception('URL is null. This song may be VIP-only.');
      }

      return url;
    } on DioException catch (e) {
      throw Exception('Failed to get audio url: ${e.message}');
    }
  }

  Future<List<LyricsItem>> getLyric(String id, {int lv=-1, int tv=-1}) async {
    final payload = {
      'id': id,
      'lv': lv,
      'tv': tv,
    };
    final encrypted = WEAPIEncryptor.encryptRequest(json.encode(payload));
      try {
        final response = await dio.post('https://music.163.com/weapi/song/lyric', data: encrypted);
        final jsonContent = json.decode(response.data);
        final lyric = jsonContent['lrc']['lyric'];

        final result = <LyricsItem>[];

        final lines = lyric.split('\n');
        final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

        for (var line in lines) {
          final matches = timeRegex.allMatches(line);
          if (matches.isEmpty) continue;

          final text = line.replaceAll(timeRegex, '').trim();
          if (text.isEmpty) continue;

          final times = matches.map((match) {
            final minutes = int.parse(match.group(1)!);
            final seconds = int.parse(match.group(2)!);
            final milliStr = match.group(3)!;
            final milliseconds = milliStr.length == 2
              ? int.parse(milliStr) * 10
              : int.parse(milliStr);
            return Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            );
          }).toList();
          
          for (final time in times) {
            result.add(LyricsItem(time, text));
          }
        }

        result.sort((a, b) => a.time.compareTo(b.time));
        return result;
      } on DioException catch (e) {
        throw Exception('Failed to get lyric in Netease Cloud Music: ${e.message}');
      }
  }

  Future<String> getIdByTitleAndAuthor(String title, String author) async {
    final payload = {
      's': '$title $author',
      'type': 1,
      'offset': 0,
      'limit': 10,
    };
    final encrypted = WEAPIEncryptor.encryptRequest(json.encode(payload));

    final response = await dio.post('https://music.163.com/weapi/cloudsearch/pc', data: encrypted);
    final jsonContent = json.decode(response.data);
    final songs = jsonContent['result']['songs'];

    for (var song in songs) {
      if (song['name'] == title) {
        for (var artist in song['ar']) {
          if (artist['name'] == author) {
            return song['id'].toString();
          }
        }
      }
    }
    return '';
  }

  Future<String> getImageUrlByTitleAndAuthor(String title, String author) async {
    var id = await getIdByTitleAndAuthor(title, author);
    if (id == '') {
      return '';
    }
    return await getImageUrl(id: id);
  }

  Future<Document> getSongHtml(String id) async {
    final response = await dio.get('https://music.163.com/song', queryParameters: {'id': id});
    final html = response.data;
    return parse(html);
  }

  Future<String> getImageUrl({String? id, Document? document}) async {
    if (id != null){
      document = await getSongHtml(id);
    }

    Element? imgUrlMeta = document!.head?.querySelector('meta[property="og:image"]');
    String imageUrl = imgUrlMeta?.attributes['content'] ?? '';
    if (imageUrl.isNotEmpty){
      return '$imageUrl?param=500y500';
    }
    return '';
  }

  String formatDuration(int milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$minutes:$seconds';
  }

  String formatDurationFromStr(String secondsStr) {
    int totalSeconds = int.tryParse(secondsStr) ?? 0;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStrFormatted = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStrFormatted';
  }

  String? extractUrl(String text) {
    final regex = RegExp(r'https?://[^\s)]+');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  String? extractSongId(String url) {
    final regex = RegExp(r'[?&]id=(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }
}