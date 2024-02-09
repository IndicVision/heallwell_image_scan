import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:azblob/azblob.dart';
import 'package:mime/mime.dart';
import 'package:logger/logger.dart';

class ImageUploadService {
  Future<void> uploadImages(File leftFootImage, File rightFootImage, String title, String description) async {
    var logger = Logger();
    final connectionString = dotenv.env['AZURE_STORAGE_CONNECTION_STRING']!;
    final containerName = dotenv.env['AZURE_STORAGE_CONTAINER_NAME']!;
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String leftFootImageFileName = 'leftFoot_$timestamp.jpg';
    String rightFootImageFileName = 'rightFoot_$timestamp.jpg';
    String metadataFileName = 'metadata_$timestamp.txt';

    try {
      Uint8List leftFootImageContent = await leftFootImage.readAsBytes();
      Uint8List rightFootImageContent = await rightFootImage.readAsBytes();
      Uint8List metadataContent = Uint8List.fromList('$title\n$description'.codeUnits);

      var storage = AzureStorage.parse(connectionString);

      // Upload left foot image
      String? leftFootImageContentType = lookupMimeType(leftFootImage.path);
      await storage.putBlob('/$containerName/$leftFootImageFileName',
          bodyBytes: leftFootImageContent, contentType: leftFootImageContentType, type: BlobType.BlockBlob);

      // Upload right foot image
      String? rightFootImageContentType = lookupMimeType(rightFootImage.path);
      await storage.putBlob('/$containerName/$rightFootImageFileName',
          bodyBytes: rightFootImageContent, contentType: rightFootImageContentType, type: BlobType.BlockBlob);

      // Upload metadata
      await storage.putBlob('/$containerName/$metadataFileName',
          bodyBytes: metadataContent, contentType: 'text/plain', type: BlobType.BlockBlob);

      logger.d('Upload successful');
    } catch (e) {
      logger.e('Upload failed: $e');
    }
  }
}