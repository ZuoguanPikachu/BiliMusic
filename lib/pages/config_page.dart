import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';



class ConfigPage extends StatelessWidget {
  ConfigPage({super.key});
  final biliService = Get.find<BiliService>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          InkWell(
            child: Container(
              padding: const EdgeInsets.only(top: 8, bottom: 8).h,
              child: ListTile(
                leading: const Icon(Icons.account_circle_rounded),
                title: Obx(() => biliService.isLogin.value ? Text(biliService.uName.value) : const Text('点击登录')),
              ),
            ),
            onTap: () {
              if (!biliService.isLogin.value) {
                Get.toNamed('/login');
              }
            },
            onLongPress: () {
              if (biliService.isLogin.value) {
                showLogoutDialog();
              }
            },
          ),
          InkWell(
            child: Container(
              padding: const EdgeInsets.only(top: 8, bottom: 8).h,
              child: const ListTile(
                leading: Icon(Icons.key_rounded),
                title: Text('LLM API Key'),
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

void showLogoutDialog() {
  final biliService = Get.find<BiliService>();

  Get.dialog(
    AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are You Sure You Want to Log Out?'),
      actions: [
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: const Text('CONFIRM'),
          onPressed: () async {
            CookieManager cookieManager = CookieManager.instance();
            await cookieManager.deleteAllCookies();
            await biliService.clearCookies();
            await biliService.getWbiKeys();

            Get.back();
          },
        ),
      ],
    ),
  );
}