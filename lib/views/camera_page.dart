import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'metadata_form_page.dart';
import 'package:logger/logger.dart'; 
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
GlobalKey _previewContainerKey = GlobalKey();

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
  bool showFocusCircle = false; // Add this line
  double x = 0; // Add this line
  double y = 0; // Add this line
  Offset? focusPoint;

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

    if (mounted) { // Check if the widget is still in the widget tree
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

  Future<void> _onTap(TapUpDetails details) async {
    if (controller?.value.isInitialized ?? false) {
      final RenderBox renderBox = _previewContainerKey.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero); // this is the top-left position of the widget
      final size = renderBox.size; // this is the size of the widget

      double x = details.localPosition.dx - position.dx;
      double y = details.localPosition.dy - position.dy;

      // Check if the tap position is within the bounds of the CameraPreview widget
      if (x >= 0 && x <= size.width && y >= 0 && y <= size.height) {
        // If it is, show the focus circle
        double xp = x / size.width;
        double yp = y / size.height;

        Offset point = Offset(xp, yp);
        focusPoint = Offset(x + position.dx, y + position.dy);

        // Manually focus
        await controller?.setFocusPoint(point);

        // Manually set light exposure
        // controller?.setExposurePoint(point);

        showFocusCircle = true;
        setState(() {
          Future.delayed(const Duration(seconds: 2)).whenComplete(() {
            setState(() {
              showFocusCircle = false;
            });
          });
        });
      }
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Retake', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: leftFootImagePath == null ? onPreviewNext : onPreviewUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                    ),
                    child: Text(leftFootImagePath == null ? 'Next' : 'Upload', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTapUp: _onTap,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Take Picture'),
              backgroundColor: Colors.blue[800],
              actions: [
                flashToggle,
              ],
            ),
            body: Container(
              key: _previewContainerKey,
              child: CameraPreview(controller!),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: takePicture,
              backgroundColor: Colors.blue[800],
              child: const Icon(Icons.camera),
            ),
          ),
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
            top: 100, // Adjust this value to move the text down
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Poppins', decoration: TextDecoration.none,),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (showFocusCircle && focusPoint != null)
            Positioned(
              left: focusPoint!.dx - 32,
              top: focusPoint!.dy - 32,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}