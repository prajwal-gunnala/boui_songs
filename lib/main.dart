import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/splash.dart';
import 'screens/home.dart';

import 'category_pages/latest_songs_page.dart';
import 'category_pages/albums_page.dart';
import 'category_pages/playlists_page.dart';
import 'category_pages/artists_page.dart';
import 'screens/category.dart';
import 'controllers/music_player_controller.dart';

// ADD THIS IMPORT:
import 'screens/search_pg.dart'; // for the new search page

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  try{
    await Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform);
  }catch(e){
    debugPrint('Firebase initialization failed:$e');
  }
  // Inject the global MusicPlayerController.
  Get.put(MusicPlayerController());
  runApp(const BOUISongsApp());
}

class BOUISongsApp extends StatelessWidget{
  const BOUISongsApp({Key?key}):super(key:key);

  @override
  Widget build(BuildContext ctx){
    return GetMaterialApp(
      title:'BOUI SONGS',
      theme:ThemeData.dark(),
      debugShowCheckedModeBanner:false,
      initialRoute:'/splash',
      getPages:[
        GetPage(name:'/splash',page:()=>const SplashScreen()),
        GetPage(name:'/home',page:()=>const HomeScreen()),
        GetPage(name:'/latest',page:()=>const LatestSongsPage()),
        GetPage(name:'/albums',page:()=>const AlbumsPage()),
        GetPage(name:'/playlists',page:()=>const PlaylistsPage()),
        GetPage(name:'/artists',page:()=>const ArtistsPage()),
        GetPage(name:'/category',page:()=>const CategoryPage()),
      //  GetPage(name:'/player',page:()=>MusicPlayerPage()),

        // ADD THIS LINE:
        GetPage(name:'/search',page:()=>const SearchPg()),
      ],
    );
  }
}