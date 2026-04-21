// import 'package:flutter/material.dart';
// import 'package:qr_certificate/core/utils/app_color.dart';
// import 'package:qr_certificate/core/utils/app_style.dart';
// import 'package:qr_certificate/core/utils/values_manager.dart';

// class TextFieldWidget extends StatelessWidget {
//   const TextFieldWidget(
//       {super.key,
//       this.controller,
//       required this.label,
//       this.validator,
//       this.enableBorderColor,
//       this.labelColor,
//       this.keyboardType});

//   final TextEditingController? controller;
//   final String label;
//   final String? Function(String?)? validator;
//   final TextInputType? keyboardType;
//   final Color? enableBorderColor;
//   final Color? labelColor;

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: Theme.of(context).copyWith(
//           textSelectionTheme: const TextSelectionThemeData(
//         cursorColor: ColorManager.cursorColor, // Cursor color
//         selectionColor: ColorManager.errorColor, // Text selection color
//         selectionHandleColor: Colors.amber, // Handle color
//       )),
//       child: TextFormField(
//         style: getStyleTextFormField(),
//         controller: controller,
//         cursorColor: ColorManager.cursorColor,
//         cursorWidth: 1,
//         maxLines: null,
//         validator: validator,
//         keyboardType: keyboardType ?? TextInputType.multiline,
//         textAlign: TextAlign.start,
//         decoration: InputDecoration(
//           floatingLabelBehavior: FloatingLabelBehavior.auto,
//           labelText: label,
//           labelStyle: getLabelTextFormField(color: labelColor),
//           errorStyle: const TextStyle(
//             color: ColorManager.errorColor, // Error text color
//           ),

//           //focus text field border
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(AppRadius.r4),
//             borderSide: const BorderSide(
//                 color: ColorManager.primaryColor, width: AppSize.s1),
//           ),

//           // enable text field border
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(AppRadius.r4),
//             borderSide: BorderSide(
//                 color: enableBorderColor ?? ColorManager.textFieldBorderColor,
//                 width: AppSize.s1),
//           ),

//           // error text field border
//           errorBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(AppRadius.r4),
//             borderSide: const BorderSide(
//                 color: ColorManager.errorColor, width: AppSize.s1),
//           ),
//         ),
//       ),
//     );
//   }
// }
