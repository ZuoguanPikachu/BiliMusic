import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:bili_music/pages/playlist_page.dart';
import 'package:bili_music/pages/search_page.dart';
import 'package:bili_music/pages/config_page.dart';
import 'package:bili_music/pages/login_page.dart';
import 'package:bili_music/pages/llm_api_page.dart';
import 'package:bili_music/services/audio_play_service.dart';
import 'package:bili_music/services/bili_service.dart';
import 'package:bili_music/services/playlist_service.dart';
import 'package:bili_music/services/llm_service.dart';
import 'package:bili_music/models/song_model.dart';


Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  await Hive.openBox<Song>('playlist');
  await Hive.openBox('llm_api');

  runApp(const MyApp());
  Get.put(BiliService());
  Get.put(AudioPlayService());
  Get.put(PlayListService());
  Get.put(LLMService());
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
          // home: TabPage(),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => TabPage()),
            GetPage(name: '/login', page: () => LoginPage()),
            GetPage(name: '/llm', page: () => LLMApiPage()),
          ],
        );
      },
    );
  }
}

class NavigationController extends GetxController {
  RxInt selectedIndex = 0.obs;
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
  }

  final List<Widget> pages = [
    PlayListPage(),
    SearchPage(),
    ConfigPage(),
  ];

  void onItemTapped(int index) {
    selectedIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 375),
      curve: Curves.easeInOut,
    );
  }
}

class TabPage extends StatelessWidget {
  TabPage({super.key});
  final NavigationController controller = Get.put(NavigationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Bili Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42.sp, fontFamily: 'Consolas')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: controller.pages
      ),
      bottomNavigationBar: Obx(() => SnakeNavigationBar.color(
        currentIndex: controller.selectedIndex.value,
        onTap: controller.onItemTapped,
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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ))
    );
  }
}