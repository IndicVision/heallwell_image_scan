import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/upload_service.dart'; // Make sure this path matches your actual service file path
import 'package:healwell_foot_scan/main.dart'; // Update this import to the path of your HomeScreen or equivalent screen

class MetadataFormPage extends StatefulWidget {
  final String leftFootImagePath;
  final String rightFootImagePath;

  const MetadataFormPage({Key? key, required this.leftFootImagePath, required this.rightFootImagePath}) : super(key: key);

  @override
  MetadataFormPageState createState() => MetadataFormPageState();
}

class MetadataFormPageState extends State<MetadataFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  var logger = Logger();
  bool isUploading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        isUploading = true;
      });
      try {
        // Assuming ImageUploadService is correctly implemented and accessible
        ImageUploadService imageUploadService = ImageUploadService();
        await imageUploadService.uploadImages(File(widget.leftFootImagePath), File(widget.rightFootImagePath), title, description);

        if (!mounted) return;

        logger.d("Images uploaded successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images upload successful')),
        );

        // Navigate back to home screen or any appropriate screen
        Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        logger.e("Images upload failed: $e");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images upload failed, please try again')),
        );
      } finally {
        if (mounted) {
          setState(() {
            isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Images", style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blue,
      ),
      body: isUploading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
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
                  ),
                ),
              ),
            ),
    );
  }
}
