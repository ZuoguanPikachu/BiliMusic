import 'package:bili_music/services/netease_service.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/llm_service.dart';
import 'package:bili_music/models/search_result.dart';
import 'package:bili_music/models/detail_info.dart';


class SearchPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final neteaseService = Get.find<NeteaseService>();
  final llmService = Get.find<LLMService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final playerId = 'searchPage';

  final RxString selectedPlatform = 'Bili'.obs;
  final List<String> platforms = ['Bili', 'Netease'];
  RxList<SearchResult> searchResults = <SearchResult>[].obs;
  RxBool isLoading = false.obs;

  Future<void> search(String keyword) async{
    try {
      isLoading.value = true;

      List<SearchResult> results;
      if (selectedPlatform.value == 'Bili'){
        results = await biliService.search(keyword);
      }
      else{
        results = await neteaseService.search(keyword);
      }
      searchResults.value = results;
    } catch (e) {
      Get.snackbar('Error', '$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> play(SearchResult searchResult) async {
    try {
      await audioPlayService.play(playerId, searchResult: searchResult);
    }
    catch (e) {
      Get.snackbar('Error', '$e');
    }
  }

  Future<DetailInfo> getDetailInfo(SearchResult info) async {
    DetailInfo detailInfo;
    if (info.platform == 'Bili'){
      final results = await Future.wait([
        llmService.extractInfo(info.title),
        biliService.getCid(info.id),
      ]);

      detailInfo = results[0] as DetailInfo;
      if (detailInfo.title.isNotEmpty && detailInfo.author.isNotEmpty){
        final lyricId = await neteaseService.getIdByTitleAndAuthor(detailInfo.title, detailInfo.author);
        final imageUrl = await neteaseService.getImageUrl(lyricId);

        detailInfo.lyricId = lyricId;
        detailInfo.imageUrl = imageUrl;
      }

      if (detailInfo.title.isEmpty){
        detailInfo.title = info.title;
      }

      final cid = results[1] as num;
      detailInfo.cid = cid;
    }else{
      final _ = await neteaseService.getAudioUrl(info.id);

      detailInfo = DetailInfo();
      detailInfo.title = info.title;
      detailInfo.author = info.author;
      detailInfo.lyricId = info.id;
      detailInfo.imageUrl = info.imageUrl;
      detailInfo.cid = 0;
    }

    return detailInfo;
  }
}