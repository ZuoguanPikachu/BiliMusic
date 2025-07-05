import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inappwebview;
import 'package:bili_music/models/search_result.dart';
import 'package:bili_music/models/lyrics_item.dart';


class BiliService {
  late Dio dio;
  late PersistCookieJar cookieJar;
  late String imgKey;
  late String subKey;
  Rx<bool> isLogin = false.obs;
  Rx<String> uName = ''.obs;

  final List<int> mixinKeyEncTab = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
    33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40,
    61, 26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11,
    36, 20, 34, 44, 52
  ];

  BiliService() {
    dio = Dio(
      BaseOptions(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36',
          'Referer': 'https://www.bilibili.com/'
        },
      ),
    );
  }

  Future init(List<inappwebview.Cookie> cookies) async {
    await initCookieJar();
    await setCookies(cookies);
    await getWbiKeys();
  }

  Future initCookieJar() async {
    final exists = dio.interceptors.any((e) => e is CookieManager);

    if (!exists) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      cookieJar = PersistCookieJar(
        storage: FileStorage("$appDocPath/.cookies/"),
        ignoreExpires: true,
      );
      dio.interceptors.add(CookieManager(cookieJar));
    }
  }

  Future<void> setCookies(List<inappwebview.Cookie> cookies) async {
    List<Cookie> ioCookies = cookies.map((cookie) {
      final ioCookie = Cookie(cookie.name, cookie.value);
      ioCookie.domain = cookie.domain;
      ioCookie.path = cookie.path ?? "/";
      if (cookie.expiresDate != null) {
        ioCookie.expires = DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!);
      }
      ioCookie.secure = cookie.isSecure ?? false;
      ioCookie.httpOnly = cookie.isHttpOnly ?? false;
      return ioCookie;
    }).toList();

    final uri = Uri.parse('https://www.bilibili.com/');
    await cookieJar.delete(uri);
    await cookieJar.saveFromResponse(uri, ioCookies);
  }

  Future<void> logout() async {
    final removeName = [
      'SESSDATA', 'bili_jct', 'DedeUserID', 'DedeUserID__ckMd5', 'sid'
    ];
    List<Cookie> cookies = await cookieJar.loadForRequest(Uri.parse('https://www.bilibili.com/'));
    cookies.removeWhere((cookie) => removeName.contains(cookie.name));

    await cookieJar.deleteAll();
    await cookieJar.saveFromResponse(Uri.parse('https://www.bilibili.com/'), cookies);
  }

  Future getWbiKeys() async {
    try {
      final response = await dio.get('https://api.bilibili.com/x/web-interface/nav');
      final jsonContent = response.data;
      final imgUrl = jsonContent['data']['wbi_img']['img_url'] as String;
      final subUrl = jsonContent['data']['wbi_img']['sub_url'] as String;

      imgKey = imgUrl.split('/').last.split('.').first;
      subKey = subUrl.split('/').last.split('.').first;

      if (jsonContent['message'] as String == '0'){
        isLogin.value = true;
        uName.value = jsonContent['data']['uname'] as String;
      }else{
        isLogin.value = false;
        uName.value = '';
      }

    } on DioException catch (e) {
      throw Exception('Failed to load WBI keys: ${e.message}');
    }
  }

  String getMixinKey(String orig) {
    return mixinKeyEncTab.fold('', (s, i) => s + orig[i]).substring(0, 32);
  }

  Map<String, String> encWbi(Map<String, dynamic> params) {
    final mixinKey = getMixinKey(imgKey + subKey);
    final currTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    params['wts'] = currTime;
    final sortedParams = Map<String, dynamic>.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    final filteredParams = sortedParams.map((k, v) {
      final filtered = v.toString().split('').where((chr) => !"!'()*".contains(chr)).join();
      return MapEntry(k, filtered);
    });

    final query = Uri(queryParameters: filteredParams).query;

    final wbiSign = md5.convert(utf8.encode(query + mixinKey)).toString();
    filteredParams['w_rid'] = wbiSign;

    return filteredParams;
  }

  Future<List<BiliSearchResult>> search(String keyword) async {
    try {
      final response = await dio.get('https://api.bilibili.com/x/web-interface/wbi/search/type',
        queryParameters: encWbi({
          'search_type': 'video',
          'keyword': keyword.replaceAll(' ', '+'),
        }),
      );
      final jsonContent = response.data;

      if (jsonContent['data'].containsKey('v_voucher')){
        throw Exception('Risk control triggered. Please log in BiliBili.');
      }

      List<BiliSearchResult> result = [];
      jsonContent['data']['result'].forEach((item) {
        if (item['type'] != 'video') {
          return;
        }

        result.add(BiliSearchResult(
          item['bvid'],
          extractContent(item['title']),
          item['author'],
          'https:${item['pic']}',
          formatTime(item['duration']),
        ));
      });
      return result;
    } on DioException catch (e) {
      throw Exception('Failed to search: ${e.message}');
    }
  }

  Future<String> getAudioUrl(String id, {num? cid}) async {
    try {
      cid ??= await getCid(id);
      final response = await dio.get('https://api.bilibili.com/x/player/wbi/playurl',
          queryParameters: {'bvid': id, 'cid': cid, 'fnval': 16},
      );
      final jsonContent = response.data;

      final audios = jsonContent['data']['dash']['audio']..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return audios.first['baseUrl'];
    } on DioException catch (e) {
      throw Exception('Failed to get audio url: ${e.message}');
    }
  }

  Future<num> getCid(String bvid) async {
    try {
      final response = await dio.get('https://api.bilibili.com/x/web-interface/wbi/view',
          queryParameters: {'bvid': bvid},
      );
      final jsonContent = response.data;

      return jsonContent['data']['cid'];
    } on DioException catch (e) {
      throw Exception('Failed to get cid: ${e.message}');
    }
  }

  Future<List<LyricsItem>> getLyricsFromSubtitle(String id, {num? cid}) async {
    try {
      cid ??= await getCid(id);
      final response = await dio.get('https://api.bilibili.com/x/player/wbi/v2',
          queryParameters: {'bvid': id, 'cid': cid},
      );
      final jsonContent = response.data;
      final subtitles = jsonContent['data']['subtitle']['subtitles'] as List<dynamic>;
      if (subtitles.isEmpty) {
        return [];
      }

      List<List<dynamic>> rawLyricsList = [];
      for (var subtitle in subtitles) {
        final lyricsUrl = subtitle['subtitle_url'] as String;
        final response = await dio.get("https:$lyricsUrl");
        rawLyricsList.add(response.data['body'] as List<dynamic>);
      }

      List<LyricsItem> lyricsList = [];
      for(int i = 0; i < rawLyricsList[0].length; i++) {
        LyricsItem lyricsItem = LyricsItem(Duration(milliseconds: ((rawLyricsList[0][i]['from'] as num) * 1000).toInt()), '');

        for (var rawLyrics in rawLyricsList){
          lyricsItem.text += rawLyrics[i]['content'] + '\n';
        }
        lyricsItem.text = lyricsItem.text.trim();
        lyricsList.add(lyricsItem);
      }
      return lyricsList;
    } on DioException catch (e) {
      throw Exception('Failed to get lyrics: ${e.message}');
    }
  }

  String extractContent(String htmlString) {
    var document = parse(htmlString);
    return document.body?.text ?? htmlString;
  }

  String formatTime(String time) {
    List<String> parts = time.split(':');
    String minutes = parts[0].padLeft(2, '0');
    String seconds = parts[1].padLeft(2, '0');
    return '$minutes:$seconds';
  }
}