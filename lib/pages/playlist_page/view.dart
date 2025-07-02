import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/playing_bar.dart';
import 'widgets/song_list.dart';
import 'widgets//cookie_loader .dart';
import 'controller.dart';


class PlayListPage extends StatelessWidget {
  PlayListPage({super.key});
  final controller = Get.put(PlayListPageController());

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Column(
        children: [
          CookieLoader(),
          Expanded(
            child: SongList(controller: controller),
          ),
          PlayingBar(controller: controller),

        ]
      )
    );
  }
}