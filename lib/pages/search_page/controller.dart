import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/llm_service.dart';
import 'package:bili_music/models/song_model.dart';
import 'package:bili_music/models/search_result_item.dart';
import 'package:bili_music/models/detail_info.dart';


class SearchPageController extends GetxController {
  final biliService = Get.find<BiliService>();
  final audioPlayService = Get.find<AudioPlayService>();
  final playListService = Get.find<PlayListService>();
  final llmService = Get.find<LLMService>();
  final playerId = 'searchPage';

  RxList<SearchResultItem> searchResults = <SearchResultItem>[].obs;
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

  Future<void> play(SearchResultItem item) async {
    await audioPlayService.play(playerId, searchResultItem: item);
  }

  Future<void> addToPlaylist(Song song) async {
    await playListService.addSong(song);
  }

  Future<DetailInfo> getDetailInfo(SearchResultItem info) async {
    final results = await Future.wait([
      llmService.extractInfo(info.title),
      biliService.getCid(info.id),
    ]);

    final detailInfo = results[0] as DetailInfo;
    final cid = results[1] as num;

    detailInfo.title ??= info.title;
    detailInfo.cid = cid;

    return detailInfo;
  }

  void updatePlaylistPlayerIndex() {
    audioPlayService.updateIndex('playlistPage');
  }
}