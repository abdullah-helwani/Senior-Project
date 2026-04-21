import 'dart:io';
import 'dart:typed_data';

// import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
// Future uploadImageToApi(XFile image) async {
//   return await MultipartFile.fromFile(image.path,
//       filename: image.path.split('/').last);
// }

Future<MultipartFile> uploadVideoToApi(File video) async {
  return await MultipartFile.fromFile(
    video.path,
    filename: video.path.split('/').last,
  );
}

Future uploadImageToApiWeb(Uint8List imageBytes, String? imageName) async {
  // if (imageBytes == null) {
  //   print('No image selected to upload.');
  //   return;
  // }
  return MultipartFile.fromBytes(
    imageBytes,
    filename: imageName ?? 'image.jpg',
  );
}

Future<MultipartFile> uploadSvgToApiWeb(
    String svgString, String fileName) async {
  final bytes = Uint8List.fromList(svgString.codeUnits);
  return MultipartFile.fromBytes(
    bytes,
    filename: fileName,
    contentType: MediaType('image', 'svg+xml'),
  );
}

Future<MultipartFile> uploadDocumentToApi(File document) async {
  return await MultipartFile.fromFile(
    document.path,
    filename:
        document.path.split('/').last, // Extracts the file name from the path
  );
}
