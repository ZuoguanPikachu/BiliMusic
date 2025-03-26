import 'package:bili_music/services/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:bili_music/pages/playlist_page.dart';
import 'package:bili_music/pages/search_page.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/audio_play_service.dart';


void main() {
  runApp(const MyApp());
  Get.put(BiliService());
  Get.put(AudioPlayService());
  Get.put(PlayListService());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(720, 1560),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bili Music',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: TabPage(),
        );
      },
    );
  }
}

class NavigationController extends GetxController {
  RxInt selectedIndex = 0.obs;

  final List<Widget> pages = [
    PlayListPage(),
    SearchPage(),
  ];

  void changePage(int index) {
    selectedIndex.value = index;
  }
}

class TabPage extends StatelessWidget {
  TabPage({super.key});
  final NavigationController controller = Get.put(NavigationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Bili Music',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42.sp, fontFamily: 'Consolas'),
        )),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(() => controller.pages[controller.selectedIndex.value]),
      bottomNavigationBar: Obx(() => SnakeNavigationBar.color(
        currentIndex: controller.selectedIndex.value,
        onTap: controller.changePage,
        snakeViewColor: Theme.of(context).colorScheme.primaryFixedDim,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        snakeShape: SnakeShape.circle,
        selectedLabelStyle: const TextStyle(fontFamily: 'Consolas'),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Consolas'),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'PlayList'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ))
    );
  }
}