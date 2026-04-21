import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

Future<void> pickImage(Function(Uint8List?, String?) onImagePicked) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final Uint8List? bytes = await image.readAsBytes();
    final String? name = image.name;
    onImagePicked(bytes, name); // Call the callback with the picked image data
  } else {
    onImagePicked(
        null, null); // Call the callback with null if no image was picked
  }
}

//! example of using this Function
//? first define this function to edit the Values 
// void _handleImagePicked(Uint8List? bytes, String? name) {
//     setState(() {
//       selectedImageBytes = bytes;
//       selectedImageName = name;
//       print('Selected image name: $selectedImageName');
//     });
//   }
//? and must define this in page to handle the value :
// Uint8List? selectedImageBytes; // To store image bytes for web
//   String? selectedImageName;

//? now exapmle of how using in page:
// const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () {
//                 pickImage(_handleImagePicked);
//               },
//               child: const Text('اختر صورة'),
//             ),

//! after the image choose can view it like in any UX in web and also name(optional view name )

// if (selectedImageBytes != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: SizedBox(
//                   height: 100, // Adjust as needed
//                   child: Image.memory(selectedImageBytes!),
//                 ),
//               ),
//             if (selectedImageName != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text('اسم الصورة: $selectedImageName'),
//               ),