import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'metadata_form_page.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  String? leftFootImagePath;
  String? rightFootImagePath;
  int pictureCount = 0;
  String message = 'Place your left foot inside the rectangle';
  Uint8List? imageBytes;
  bool isPreviewing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    initCamera();
    _setFlashMode(FlashMode.off);
  }

  Future<void> initCamera() async {
    var logger = Logger();
    try {
      cameras = await availableCameras();
      controller = CameraController(cameras[0], ResolutionPreset.ultraHigh);
      await controller!.initialize();
      setState(() {});
    } catch (e) {
      logger.e('Error initializing camera: $e');
    }
  }

  Future<void> takePicture() async {
    if (controller != null && controller!.value.isInitialized) {
      final XFile file = await controller!.takePicture();
      final bytes = await file.readAsBytes();
      setState(() {
        imageBytes = bytes;
        isPreviewing = true; // Enter preview mode
      });
    }
  }

  Future<void> onPreviewNext() async {
    // Save the first image and proceed to take the second image
    leftFootImagePath = join(
      (await getApplicationDocumentsDirectory()).path,
      'left_foot_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(leftFootImagePath!).writeAsBytes(imageBytes!);
    setState(() {
      isPreviewing = false; // Exit preview mode
      message = 'Place your right foot inside the rectangle';
      imageBytes = null;
    });
  }

  Future<void> onPreviewUpload() async {
    // Save the second image and proceed to the metadata form page
    rightFootImagePath = join(
      (await getApplicationDocumentsDirectory()).path,
      'right_foot_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(rightFootImagePath!).writeAsBytes(imageBytes!);

    // Navigate to the metadata form page with the image paths
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MetadataFormPage(
          leftFootImagePath: leftFootImagePath!,
          rightFootImagePath: rightFootImagePath!,
        ),
      ),
    );
  }

  void retakePicture() {
    setState(() {
      imageBytes = null;
      isPreviewing = false; // Exit preview mode
    });
  }

  // Method to toggle flash mode
  void _toggleFlash() {
    FlashMode newMode;
    if (_flashMode == FlashMode.off) {
      newMode = FlashMode.torch;
    } else {
      newMode = FlashMode.off;
    }
    _setFlashMode(newMode);
  }

  // Method to set flash mode
  Future<void> _setFlashMode(FlashMode mode) async {
    if (controller != null && controller!.value.isInitialized) {
      await controller!.setFlashMode(mode);
      setState(() {
        _flashMode = mode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Take Picture'), backgroundColor: Colors.blue[800]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    Widget flashToggle = IconButton(
      icon: Icon(
        // Change the icon based on the current flash mode
        _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
        color: Colors.white,
      ),
      onPressed: _toggleFlash,
    );
    if (isPreviewing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Preview'),
          backgroundColor: Colors.blue[800],
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              isPreviewing = false;
            }),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: retakePicture,
                    child: const Text('Retake', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: leftFootImagePath == null ? onPreviewNext : onPreviewUpload,
                    child: Text(leftFootImagePath == null ? 'Next' : 'Upload', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Picture'),
        backgroundColor: Colors.blue[800],
        actions: [
          // Add the flash toggle button to the AppBar actions
          flashToggle,
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(controller!),
          Center(
            child: Container(
              width: 300,
              height: 600,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[800]!, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: takePicture,
        child: const Icon(Icons.camera),
        backgroundColor: Colors.blue[800],
      ),
    );
  }
}