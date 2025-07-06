import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'widgets/playing_bar.dart';
import 'widgets/song_list.dart';
import 'widgets/cookie_loader.dart';
import 'controller.dart';


class PlayListPage extends StatelessWidget {
  PlayListPage({super.key});
  final biliService = Get.find<BiliService>();

  @override
  Widget build(BuildContext context) {
    Get.put(AudioPlayerController());
    Get.put(PlayListController());

    return SafeArea(
      child: Column(
        children: [
          Obx(() => biliService.hasInit.value
            ? const SizedBox.shrink()
            : CookieLoader()
          ),
          const Expanded(
            child: SongList(),
          ),
          const PlayingBar(),
        ]
      )
    );
  }
}