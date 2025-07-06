import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/models/song_model.dart';
import 'clearable_text_field.dart';
import 'song_edit_controller.dart';


class SongFormDialog extends StatelessWidget {
  final String title;
  final Song? song; // 如果是 null 代表新增
  final Function(Song) onSubmit;
  final Function()? onDelete;
  final bool isBilibili;
  final SongEditController songEditController = Get.put(SongEditController());

  SongFormDialog({
    super.key,
    required this.title,
    required this.onSubmit,
    this.song,
    this.onDelete,
    required this.isBilibili,
  });

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final imageUrlController = TextEditingController();
  final lyricIdController = TextEditingController();
  final lyricBiasController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (song != null) {
      titleController.text = song!.title;
      authorController.text = song!.author;
      imageUrlController.text = song!.imageUrl;
      lyricIdController.text = song!.lyricId;
      lyricBiasController.text = song!.lyricBias.toString();
    }

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontFamily: 'Consolas')),
      content:
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400, minWidth: 500),
        child: SingleChildScrollView(
          child: IntrinsicHeight(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClearableTextField(
                controller: titleController,
                label: 'Title',
              ),
              ClearableTextField(
                controller: authorController,
                label: 'Author',
              ),
              if (isBilibili)
                ClearableTextField(
                  controller: imageUrlController,
                  label: 'Image Url',
                  onAutoFill: () async {
                    imageUrlController.text = await songEditController.getImageUrl(
                      titleController.text,
                      authorController.text,
                    );
                  },
                ),
              if (isBilibili)
                ClearableTextField(
                  controller: lyricIdController,
                  label: 'Lyric Id (Netease)',
                  onAutoFill: () async {
                    lyricIdController.text = await songEditController.getLyricId(
                      titleController.text,
                      authorController.text,
                    );
                  },
                ),
              if (isBilibili)
                TextField(
                  controller: lyricBiasController,
                  decoration: const InputDecoration(
                    labelText: 'Lyric Bias (ms)',
                    labelStyle: TextStyle(fontFamily: 'Consolas'),
                    helperText: 'Positive: lyrics appear later; Negative: earlier',
                  ),
                )
            ]
          ))
        )
      ),
      actions: [
        if (onDelete != null)
          TextButton(
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontFamily: 'Consolas')),
            onPressed: () {
              onDelete!();
              Get.back();
            },
          ),
        TextButton(
          child: const Text('CANCEL', style: TextStyle(fontFamily: 'Consolas')),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: const Text('SAVE', style: TextStyle(fontFamily: 'Consolas')),
          onPressed: () {
            final result = Song(
              platform: song?.platform ?? 'bilibili',
              id: song?.id ?? '',
              cid: song?.cid ?? 0,
              title: titleController.text,
              author: authorController.text,
              imageUrl: imageUrlController.text,
              lyricId: lyricIdController.text,
              lyricBias: int.tryParse(lyricBiasController.text) ?? 0,
              timestamp: song?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
            );
            onSubmit(result);
            Get.back();
          },
        )
      ],
    );
  }
}
