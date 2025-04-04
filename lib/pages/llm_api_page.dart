import 'package:bili_music/services/llm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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


class LLMApiPage extends StatelessWidget {
  LLMApiPage({super.key});
  final controller = Get.put(LLMapiPageController());
  final baseUrlController = TextEditingController();
  final modelNameController = TextEditingController();
  final apiKeyController = TextEditingController();

  final showBaseUrlClearButton = false.obs;
  final showModelNameClearButton = false.obs;
  final showApiKeyClearButton = false.obs;

  @override
  Widget build(BuildContext context) {

    baseUrlController.addListener(() {
      showBaseUrlClearButton.value = baseUrlController.text.isNotEmpty;
    });
    modelNameController.addListener(() {
      showModelNameClearButton.value = modelNameController.text.isNotEmpty;
    });
    apiKeyController.addListener(() {
      showApiKeyClearButton.value = apiKeyController.text.isNotEmpty;
    });

    baseUrlController.text = controller.getData('baseUrl');
    modelNameController.text = controller.getData('modelName');
    apiKeyController.text = controller.getData('apiKey');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Bili Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42.sp, fontFamily: 'Consolas')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 48, right: 48, top: 32).w,
        child: Column(
          children: [
            Obx(() => TextField(
              decoration: InputDecoration(
                labelText: 'Base Url',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showBaseUrlClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_outlined, color: Colors.grey),
                  onPressed: () => baseUrlController.clear(),
                ) : null,
              ),
              controller: baseUrlController,
            )),
            SizedBox(height: 32.h),
            Obx(() => TextField(
              decoration: InputDecoration(
                labelText: 'Model Name',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showModelNameClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_outlined, color: Colors.grey),
                  onPressed: () => modelNameController.clear(),
                ) : null,
              ),
              controller: modelNameController,
            )),
            SizedBox(height: 32.h),
            Obx(() => TextField(
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: const TextStyle(fontFamily: 'Consolas'),
                suffixIcon: showApiKeyClearButton.value ?
                IconButton(
                  icon: const Icon(Icons.clear_outlined, color: Colors.grey),
                  onPressed: () => apiKeyController.clear(),
                ) : null,
              ),
              controller: apiKeyController,
            )),
            SizedBox(height: 64.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryFixedDim,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('SAVE', style: TextStyle(fontFamily: 'Consolas')),
                    onPressed: () async {
                      await controller.saveData('baseUrl', baseUrlController.text);
                      await controller.saveData('modelName', modelNameController.text);
                      await controller.saveData('apiKey', apiKeyController.text);

                      Get.back();
                      Get.snackbar('Tips', 'Saved Successfully!');
                    },
                  ),
                )
              ]
            )
          ],
        )
      ),
    );
  }
}