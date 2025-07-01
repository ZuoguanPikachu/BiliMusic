import 'package:bili_music/services/llm_service.dart';
import 'package:get/get.dart';


class LLMapiPageController extends GetxController {
  final LLMService apiStorageService = Get.find<LLMService>();

  String getData(String key) {
    return apiStorageService.getData(key);
  }

  Future<void> saveData(String key, String value) async {
    await apiStorageService.saveData(key, value);
  }
}