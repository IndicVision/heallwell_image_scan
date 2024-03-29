import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/upload_service.dart'; // Adjust this path as needed
import 'package:http/http.dart' as http;

class MetadataFormPage extends StatefulWidget {
  final String leftFootImagePath;
  final String rightFootImagePath;

  const MetadataFormPage({Key? key, required this.leftFootImagePath, required this.rightFootImagePath})
      : super(key: key);

  @override
  MetadataFormPageState createState() => MetadataFormPageState();
}

class MetadataFormPageState extends State<MetadataFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  var logger = Logger();
  bool isUploading = false;
  bool isUploadComplete = false; // Tracks if the upload process is complete
  Uint8List? leftFootImageProcessed;
  Uint8List? rightFootImageProcessed;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        isUploading = true;
      });
      try {
        ImageUploadService imageUploadService = ImageUploadService();
        List<http.Response> responses = await imageUploadService.uploadImages(
          File(widget.leftFootImagePath), 
          File(widget.rightFootImagePath), 
          title, 
          description
        );

        if (!mounted) return;

        // Extract image data directly from the response body bytes
        leftFootImageProcessed = responses[0].bodyBytes;
        rightFootImageProcessed = responses[1].bodyBytes;

        logger.d("Images processed successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images processed successfully')),
        );

      } catch (e) {
        logger.e("Image processing failed: $e");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image processing failed, please try again')),
        );
      } finally {
        if (mounted) {
          setState(() {
            isUploading = false;
            isUploadComplete = true; // Mark the upload process as complete
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display uploading indicator or the form based on the state
    Widget content = isUploading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onSaved: (value) => title = value!,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10.0),
                  ),
                  onSaved: (value) => description = value ?? '',
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upload Images', style: TextStyle(fontFamily: 'Poppins')),
                ),
              ],
            ),
          );

    // If the upload is complete, display the images fullscreen
    if (isUploadComplete) {
      content = PageView(
        children: <Widget>[
          if (leftFootImageProcessed != null) Image.memory(leftFootImageProcessed!),
          if (rightFootImageProcessed != null) Image.memory(rightFootImageProcessed!),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isUploadComplete ? "Callus Detections" : "Info", style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false, // Removes the default back button
      ),
      body: content,
      floatingActionButton: isUploadComplete ? FloatingActionButton(
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.home),
      ) : null, // Display the home button only after images are uploaded
    );
  }
}
