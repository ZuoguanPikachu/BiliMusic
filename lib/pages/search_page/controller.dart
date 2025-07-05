import 'package:bili_music/services/netease_service.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/llm_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/models/search_result.dart';
import 'package:bili_music/models/detail_info.dart';


class SearchPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final neteaseService = Get.find<NeteaseService>();
  final llmService = Get.find<LLMService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final playerId = 'searchPage';

  RxList<BiliSearchResult> searchResults = <BiliSearchResult>[].obs;
  RxBool isLoading = false.obs;

  Future<void> search(String keyword) async{
    try {
      isLoading.value = true;
      final results = await biliService.search(keyword);
      searchResults.value = results;
    } catch (e) {
      Get.snackbar('Error', '$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> play(BiliSearchResult searchResult) async {
    await audioPlayService.play(playerId, searchResult: searchResult);
  }

  Future<void> addToPlaylist(String id, num cid, String title, String author, String imageUrl) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    final song = Song(platform: 'bilibili', id: id, cid: cid, title: title, author: author,  imageUrl: imageUrl, lyricId: '', lyricBias: 0, timestamp: timestamp);
    await playListService.addSong(song);

    audioPlayService.updateIndex('playlistPage');
  }

  Future<DetailInfo> getDetailInfo(BiliSearchResult info) async {
    final results = await Future.wait([
      llmService.extractInfo(info.title),
      biliService.getCid(info.id),
    ]);

    final detailInfo = results[0] as DetailInfo;

    if (detailInfo.title.isNotEmpty && detailInfo.author.isNotEmpty){
      final imageUrl = await getImageUrlByTitleAndAuthor(detailInfo.title, detailInfo.author);
      detailInfo.imageUrl = imageUrl;
    }

    if (detailInfo.title.isEmpty){
      detailInfo.title = info.title;
    }

    final cid = results[1] as num;
    detailInfo.cid = cid;

    return detailInfo;
  }

  Future<String> getImageUrlByTitleAndAuthor(String title, String author) async {
    return await neteaseService.getImageUrlByTitleAndAuthor(title, author);
  }
}