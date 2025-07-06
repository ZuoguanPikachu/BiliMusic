import 'package:get/get.dart';
import 'package:bili_music/services/netease_service.dart';


class SongEditController extends GetxController {
  final neteaseService = Get.find<NeteaseService>();

  Future<String> getImageUrl(String title, String author) async =>
      await neteaseService.getImageUrlByTitleAndAuthor(title, author);

  Future<String> getLyricId(String title, String author) async =>
      await neteaseService.getIdByTitleAndAuthor(title, author);
}