import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';


class LyricsPage extends StatelessWidget {
  final LyricsPageController lyricsController = Get.put(LyricsPageController(), permanent: true);

  LyricsPage({super.key}) {
    lyricsController.scrollOnPageLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Bili Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Consolas')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(() => lyricsController.lyrics.isEmpty ?
        const Center(child: Text('No lyrics found.')) :
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            lyricsController.handleScrollNotification(notification);
            return true;
          },
          child: ListView.builder(
            controller: lyricsController.scrollController,
            itemCount: lyricsController.lyrics.length + 14,
            itemBuilder: (context, index) {
              if (index < 7 || index >= lyricsController.lyrics.length + 7) {
                return const SizedBox(
                  height: 55,
                );
              } else {
                return Obx(() {
                  final isCurrent = index - 7 == lyricsController.currentLyricsIndex.value;
                  final item = lyricsController.lyrics[index - 7];
                  return InkWell(
                    onTap: () => lyricsController.seekToLyric(index - 7),
                    child: SizedBox(
                      height: 55,
                      child: Center(
                        child: Text(item.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCurrent? 20 : 16,
                            color: isCurrent? Theme.of(context).colorScheme.primary : Colors.black,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        )
                      ),
                    ),
                  );
                });
              }
            },
          )
        )
      )
    );
  }
}