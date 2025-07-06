import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/models/play_mode.dart';
import '../controller.dart';


class PlayingBar extends StatelessWidget {
  const PlayingBar({super.key});

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
          child: const Row(
            children: [
              Icon(Icons.library_music_rounded, size: 42, color: Colors.black45,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: SongInfoLabels()),
                        ControlButtons()
                      ],
                    ),
                    ProgressBar()
                  ],
                )
              )
            ],
          )
        )
    );
  }
}


class SongInfoLabels extends StatelessWidget {
  const SongInfoLabels({super.key});
  AudioPlayerController get audioPlayerController => Get.find();


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(audioPlayerController.currentSong.value?.title ?? '',
            style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis, maxLines: 1
          )),
          const SizedBox(height: 6),
          Obx(() => Text(audioPlayerController.currentSong.value?.author ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black45), overflow: TextOverflow.ellipsis, maxLines: 1
          )),
        ],
      )
    );
  }
}


class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});
  AudioPlayerController get audioPlayerController => Get.find();

  IconData getModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.single:
        return Icons.repeat_one;
      case PlayMode.loop:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_outlined),
          iconSize: 32,
          onPressed: () async {
            await audioPlayerController.playPrevious();
          }
        ),
        Obx(() => IconButton(
          icon: Icon(audioPlayerController.isPlaying.value? Icons.pause_circle_outline_outlined : Icons.play_circle_outline_outlined),
          iconSize: 40,
          onPressed: () async {
            if (audioPlayerController.isPlaying.value){
              await audioPlayerController.pause();
            }
            else if (audioPlayerController.currentIndex.value == -1){
              await audioPlayerController.play(0);
            }
            else{
              await audioPlayerController.resume();
            }
          }
        )),
        IconButton(
          icon: const Icon(Icons.skip_next_outlined),
          iconSize: 32,
          onPressed: () async {
            await audioPlayerController.playNext();
          }
        ),
        Obx(() => IconButton(
          icon: Icon(getModeIcon(audioPlayerController.playMode.value)),
          iconSize: 32,
          onPressed: () async {
            audioPlayerController.switchPlayMode();
          }
        )),
      ]
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key});
  AudioPlayerController get audioPlayerController => Get.find();

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        trackHeight: 1
      ),
      child: Obx(() => Slider(
        value: audioPlayerController.position.value.inSeconds.toDouble(),
        min: 0,
        max: audioPlayerController.duration.value.inSeconds.toDouble(),
        onChanged: (value) async {
          await audioPlayerController.seek(Duration(seconds: value.toInt()));
        },
      ))
    );
  }
}