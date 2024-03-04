import 'dart:typed_data';
import 'package:flutter/material.dart';

class DisplayImagesPage extends StatelessWidget {
  final Uint8List leftFootImage;
  final Uint8List rightFootImage;

  DisplayImagesPage({required this.leftFootImage, required this.rightFootImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Processed Images'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: PageView(
                children: [
                  Image.memory(leftFootImage),
                  Image.memory(rightFootImage),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Icon(Icons.home),
            ),
          ],
        ),
      ),
    );
  }
}