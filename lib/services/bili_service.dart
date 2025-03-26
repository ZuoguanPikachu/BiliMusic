import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';


class BiliService {
  late Dio dio;
  late String imgKey;
  late String subKey;

  BiliService() {
    dio = Dio(
      BaseOptions(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
          'Referer': 'https://www.bilibili.com/'
        },
      ),
    );

    getWbiKeys();
  }

  final List<int> mixinKeyEncTab = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
    33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40,
    61, 26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11,
    36, 20, 34, 44, 52
  ];

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

  Future getWbiKeys() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    final cookieJar = PersistCookieJar(
      storage: FileStorage("$appDocPath/.cookies/"),
      ignoreExpires: true,
    );
    dio.interceptors.add(CookieManager(cookieJar));

    try {
      await dio.get('https://bilibili.com/');
      await dio.get('https://www.bilibili.com/');

      final response = await dio.get('https://api.bilibili.com/x/web-interface/nav');
      final jsonContent = response.data;
      final imgUrl = jsonContent['data']['wbi_img']['img_url'] as String;
      final subUrl = jsonContent['data']['wbi_img']['sub_url'] as String;

      imgKey = imgUrl.split('/').last.split('.').first;
      subKey = subUrl.split('/').last.split('.').first;
    } on DioException catch (e) {
      throw Exception('Failed to load WBI keys: ${e.message}');
    }
  }

  Future<List<Map<String, String>>> search(String keyword) async {
    try {
      final response = await dio.get('https://api.bilibili.com/x/web-interface/wbi/search/type',
        queryParameters: encWbi({
          'search_type': 'video',
          'keyword': keyword.replaceAll(' ', '+'),
        }),
      );
      final jsonContent = response.data;

      List<Map<String, String>> result = [];
      jsonContent['data']['result'].forEach((item) {
        if (item['type'] != 'video') {
          return;
        }
        result.add({
          "bvid": item['bvid'],
          "title": extractContent(item['title']),
          "author": item['author'],
          "pic": 'https:${item['pic']}',
          "duration": formatTime(item['duration']),
        });
      });
      return result;
    } on DioException catch (e) {
      throw Exception('Failed to search: ${e.message}');
    }
  }

  Future<String> getAudioUrl(String bvid, {num? cid}) async {
    try {
      cid ??= await getCid(bvid);
      final response = await dio.get('https://api.bilibili.com/x/player/wbi/playurl',
          queryParameters: {'bvid': bvid, 'cid': cid, 'fnval': 16},
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