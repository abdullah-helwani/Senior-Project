// import 'package:flutter/material.dart';
// import 'package:qr_certificate/core/utils/app_color.dart';
// import 'package:qr_certificate/core/utils/values_manager.dart';

// class TextFieldWithLabel extends StatelessWidget {
//   const TextFieldWithLabel({
//     super.key,
//     required this.label,
//     required this.child,
//     this.padding = EdgeInsets.zero,
//     this.textColor = ColorManager.whiteColor,
//     this.fontSize,
//   });

//   final String label;
//   final Widget child;
//   final EdgeInsets? padding;
//   final Color? textColor;
//   final double? fontSize;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: fontSize ?? 13,
//             fontWeight: FontWeight.w500,
//             color: textColor,
//           ),
//         ),
//         const SizedBox(
//           height: AppSize.s8,
//         ),
//         child
//       ],
//     );
//   }
// }
