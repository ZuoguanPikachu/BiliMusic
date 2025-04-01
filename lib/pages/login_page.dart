import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';


class LoginPage extends StatelessWidget{
  LoginPage({super.key});
  final biliService = Get.find<BiliService>();

  @override
  Widget build(BuildContext context) {
    CookieManager cookieManager = CookieManager.instance();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Bili Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42.sp, fontFamily: 'Consolas')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://passport.bilibili.com/h5-app/passport/login')),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
          ),
          onLoadStop: (controller, url) async {
            if (url!.host.contains('bilibili.com')){

              controller.evaluateJavascript(source: """
                var nav_bar_back = document.getElementsByClassName('v-navbar__back')[0];
                nav_bar_back.style.display = 'none'
              """);

              List<Cookie> cookies = await cookieManager.getCookies(url: url);
              if (cookies.any((cookie) => cookie.name == 'SESSDATA')){
                await biliService.setCookies(cookies);
                await biliService.getWbiKeys();

                Get.back();
              }
            }
          }
        ),
      ),
    );
  }
}
