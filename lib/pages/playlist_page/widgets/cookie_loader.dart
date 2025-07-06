import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:bili_music/services/bili_service.dart';


class CookieLoader extends StatelessWidget {
  final biliService = Get.find<BiliService>();
  CookieLoader ({super.key});

  @override
  Widget build(BuildContext context) {
    CookieManager cookieManager = CookieManager.instance();

    return Offstage(
      offstage: true,
      child: SizedBox(
        height: 650,
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://m.bilibili.com/')),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
          ),
          onLoadStop: (controller, url) async {
            if (url!.host.contains('bilibili.com')){
              List<Cookie> cookies = await cookieManager.getCookies(url: url);
              if (cookies.length >= 8){
                await biliService.init(cookies);
              }
            }
          }
        )
      )
    );
  }
}
