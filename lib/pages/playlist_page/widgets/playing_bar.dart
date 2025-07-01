import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller.dart';


class PlayingBar extends StatelessWidget {
  final PlayListPageController controller;
  const PlayingBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixedDim,
          borderRadius: BorderRadius.circular(12)
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed('/lyrics');
        },
        child: Row(
          children: [
            const Icon(Icons.library_music_rounded, size: 42, color: Colors.black45,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(controller.currentSong.value == null ? '' : controller.currentSong.value!.title,
                                style: const TextStyle(fontSize: 16)
                            )),
                            const SizedBox(height: 6),
                            Obx(() => Text(controller.currentSong.value == null ? '' : controller.currentSong.value!.author,
                                style: const TextStyle(fontSize: 12, color: Colors.black45)
                            )),
                          ],
                        )
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_outlined),
                            iconSize: 32,
                            onPressed: () async {
                              await controller.playPrevious();
                            }
                          ),
                          Obx(() => IconButton(
                            icon: Icon(controller.isPlaying.value? Icons.pause_circle_outline_outlined : Icons.play_circle_outline_outlined),
                            iconSize: 40,
                            onPressed: () async {
                              if (controller.isPlaying.value){
                                await controller.pause();
                              }
                              else if (controller.currentIndex.value == -1){
                                await controller.play(0);
                              }
                              else{
                                await controller.resume();
                              }
                            }
                          )),
                          IconButton(
                            icon: const Icon(Icons.skip_next_outlined),
                            iconSize: 32,
                            onPressed: () async {
                              await controller.playNext();
                            }
                          ),
                        ]
                      )
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        trackHeight: 1
                    ),
                    child: Obx(() => Slider(
                      value: controller.position.value.inSeconds.toDouble(),
                      min: 0,
                      max: controller.duration.value.inSeconds.toDouble(),
                      onChanged: (value) async {
                        await controller.seek(Duration(seconds: value.toInt()));
                      },
                    ))
                  )
                ],
              )
            )
          ],
        )
      )
    );
  }
}