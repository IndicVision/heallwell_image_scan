import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/camera_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Adding a Key parameter to the constructor
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Capture App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // Set SplashScreen as the home widget
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {

      Future<void> _recordImages() async {
      // Simply navigate to the CameraPage
      // The CameraPage itself handles recording and navigation to the next page
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const CameraPage()),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: const Center(
        child: Text('Tap + to capture the images.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recordImages,
        tooltip: 'Capture Images',
        child: const Icon(Icons.add),
      ),
    );
  }
}
