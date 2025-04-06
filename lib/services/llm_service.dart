import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:bili_music/models/detail_info.dart';


class LLMService {
  final dio = Dio();
  final systemPrompt = """你是一个API接口，从用户提交的文本中提取歌曲名和作者，以JSON格式返回：{"title": "songName", "author": "authorName"}。
- 输入是一段文本，可能包含歌曲名和作者的描述，或仅部分信息。
- 如果无法明确识别歌曲名或作者，对应字段返回空字符串""。
- 如果文本中提及多首歌或作者，只提取第一个出现的歌曲名和作者。
- 返回的歌曲名和作者保持原始文本的大小写和拼写，不进行猜测或规范化。
- 如果文本中无相关信息，返回{"title": "", "author": ""}。
示例：
- 输入："【4K60FPS】陈奕迅《人来人往》让人泪目的现场！你还相信爱情吗？" → 输出：{"title": "人来人往", "author": "陈奕迅"}
- 输入："人来人往 翻唱" → 输出：{"title": "人来人往", "author": ""}
- 输入："人来人往的街道" → 输出：{"title": "", "author": ""}""";

  
  Future<void> saveData(String key, String value) async {
    await Hive.box('llm_api').put(key, value);
  }

  String getData(String key) {
    return Hive.box('llm_api').get(key, defaultValue: '');
  }

  Future<DetailInfo> extractInfo(String rawTitle) async {
    String baseUrl = getData('baseUrl');
    final modelName = getData('modelName');
    final apiKey = getData('apiKey');

    if (baseUrl.isEmpty || modelName.isEmpty || apiKey.isEmpty){
      return DetailInfo();
    }

    if (!(baseUrl.endsWith('chat/completions') || baseUrl.endsWith('chat/completions/'))){
      baseUrl += baseUrl.endsWith('/') ? 'chat/completions' : '/chat/completions';
    }

    final Map<String, dynamic> data = {
      "model": modelName,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": rawTitle}
      ]
    };
    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    final response = await dio.post(baseUrl, data: data, options: Options(headers: headers));
    final jsonContent = response.data;
    final llmOutput = jsonContent['choices'][0]['message']['content'] as String;
    final llmOutputJson = json.decode(
      llmOutput.trim().replaceAll('```json', '').replaceAll('```', '').replaceAll(RegExp(r'^\s*', multiLine: true), '')
    );

    return DetailInfo(
      title: llmOutputJson['title'],
      author: llmOutputJson['author'],
    );
  }
}