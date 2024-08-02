import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'login_page.dart'; 
import 'my_home_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCbBIq7NWV4W8-XGg2kDCmpzLBRFM9dxBk",
        authDomain: "plex-d9d6d.firebaseapp.com",
        projectId: "plex-d9d6d",
        storageBucket: "plex-d9d6d.appspot.com",
        messagingSenderId: "1079093832903",
        appId: "1:1079093832903:web:81b299be2e88fa547ce2e2",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filelist Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
textTheme: TextTheme(
  bodyLarge: TextStyle(color: Colors.white),
  bodyMedium: TextStyle(color: Colors.white),
),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.withOpacity(0.3),
          titleTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: FirebaseAuth.instance.currentUser == null ? LoginPage() : MyHomePage(),
    );
  }
}
