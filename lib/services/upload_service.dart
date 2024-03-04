import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:azblob/azblob.dart';
import 'package:mime/mime.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  Future<List<http.Response>> uploadImages(File leftFootImage, File rightFootImage, String title, String description) async {
    var logger = Logger();
    final connectionString = dotenv.env['AZURE_STORAGE_CONNECTION_STRING'];
    if (connectionString == null) {
      throw Exception('AZURE_STORAGE_CONNECTION_STRING not found');
    }
    final accountName = dotenv.env['AZURE_STORAGE_ACCOUNT_NAME'];
    if (accountName == null) {
      throw Exception('AZURE_STORAGE_ACCOUNT_NAME not found');
    }
    final containerName = dotenv.env['AZURE_STORAGE_CONTAINER_NAME'];
    if (containerName == null) {
      throw Exception('AZURE_STORAGE_CONTAINER_NAME not found');
    }
    final azureFunctionUrl = dotenv.env['AZURE_FUNCTION_URL'];
    if (azureFunctionUrl == null) {
      throw Exception('AZURE_FUNCTION_URL not found');
    }

    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String leftFootImageFileName = 'leftFoot_$timestamp.jpg';
    String rightFootImageFileName = 'rightFoot_$timestamp.jpg';
    String metadataFileName = 'metadata_$timestamp.txt';

    try {
      Uint8List leftFootImageContent = await leftFootImage.readAsBytes();
      Uint8List rightFootImageContent = await rightFootImage.readAsBytes();
      Uint8List metadataContent = Uint8List.fromList('$title\n$description'.codeUnits);

      var storage = AzureStorage.parse(connectionString);

      // Upload images and metadata simultaneously
      await Future.wait([
        _uploadBlob(storage, containerName, leftFootImageFileName, leftFootImageContent, lookupMimeType(leftFootImage.path)),
        _uploadBlob(storage, containerName, rightFootImageFileName, rightFootImageContent, lookupMimeType(rightFootImage.path)),
        _uploadBlob(storage, containerName, metadataFileName, metadataContent, 'text/plain'),
      ]);

      logger.d('Upload successful');

      // Construct the blob URLs
      String leftFootImageUrl = _constructBlobUrl(accountName, containerName, leftFootImageFileName);
      String rightFootImageUrl = _constructBlobUrl(accountName, containerName, rightFootImageFileName);

      // Make Azure function calls one after another and log the responses
      http.Response leftFootImageResponse = await _makeAzureFunctionCall(azureFunctionUrl, leftFootImageUrl);
      logger.d('Left foot image response: ${leftFootImageResponse.body}');
      
      http.Response rightFootImageResponse = await _makeAzureFunctionCall(azureFunctionUrl, rightFootImageUrl);
      logger.d('Right foot image response: ${rightFootImageResponse.body}');

      // Return the responses
      return [leftFootImageResponse, rightFootImageResponse];
    } catch (e) {
      logger.e('Upload failed: $e');
      throw e;
    }
  }

  Future<void> _uploadBlob(AzureStorage storage, String containerName, String fileName, Uint8List content, String? contentType) async {
    await storage.putBlob('/$containerName/$fileName',
        bodyBytes: content, contentType: contentType ?? 'application/octet-stream', type: BlobType.BlockBlob);
  }

  String _constructBlobUrl(String accountName, String containerName, String fileName) {
    return 'https://$accountName.blob.core.windows.net/$containerName/$fileName';
  }

  Future<http.Response> _makeAzureFunctionCall(String azureFunctionUrl, String imageUrl) async {
    final Uri uri = Uri.parse('$azureFunctionUrl&imageUrl=$imageUrl');
    final Duration timeoutDuration = Duration(minutes: 20); // Adjust based on your needs

    return await http.get(uri).timeout(timeoutDuration, onTimeout: () {
      // This block will be executed in case of a timeout
      throw Exception('The request to the Azure function timed out after $timeoutDuration.');
    });
  }
}
