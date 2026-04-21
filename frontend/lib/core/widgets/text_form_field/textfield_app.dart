// import 'package:flutter/material.dart';
// import 'package:qr_certificate/core/utils/app_color.dart';
// import 'package:qr_certificate/core/utils/app_fonts.dart';
// import 'package:qr_certificate/core/utils/app_style.dart';
// import 'package:qr_certificate/core/utils/values_manager.dart';

// class TextFiledApp extends StatefulWidget {
//   TextFiledApp(
//       {super.key,
//       this.textInputAction = TextInputAction.next,
//       this.keyboardType = TextInputType.text,
//       this.controller,
//       this.iconData,
//       this.isDarkMode = false,
//       this.hintText,
//       this.obscureText = false,
//       this.suffixIcon,
//       this.wantObscure = false, // New bool to control behavior
//       this.validator,
//       this.onChanged,
//       this.onTap,
//       this.autofocus = false,
//       this.readOnly = false,
//       this.maxLine = 1,
//       this.minLine = 1,
//       this.fillColor = ColorManager.textFieldColor,
//       this.textFieldHintColor = ColorManager.textFieldHintColor,
//       this.requiredField = false,
//       this.helperText,
//       this.prefixColor,
//       this.textColor,
//       this.maxLength});

//   final TextInputAction textInputAction;
//   final TextInputType keyboardType;
//   final TextEditingController? controller;
//   final IconData? iconData;
//   final String? hintText;
//   final String? helperText;
//   final Widget? suffixIcon; // Keep this as a Widget
//   final bool wantObscure; // Control whether to show password toggle
//   final bool autofocus;
//   final bool readOnly;
//   final bool requiredField;
//   bool obscureText;
//   bool isDarkMode;
//   final String? Function(String?)? validator;
//   final Function(String)? onChanged;
//   final VoidCallback? onTap;
//   final int? maxLine;
//   final int? minLine;
//   final int? maxLength;
//   final Color? fillColor;
//   final Color? prefixColor;
//   final Color? textColor;
//   final Color? textFieldHintColor;

//   @override
//   State<TextFiledApp> createState() => _TextFiledAppState();
// }

// class _TextFiledAppState extends State<TextFiledApp> {
//   void showPassword() {
//     setState(() {
//       widget.obscureText = !widget.obscureText;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return TextFormField(
//       maxLength: widget.maxLength,
//       maxLines: widget.maxLine,
//       minLines: widget.minLine,
//       readOnly: widget.readOnly,
//       autofocus: widget.autofocus,
//       validator: widget.validator ??
//           (String? val) {
//             if (val!.trim().isEmpty && widget.requiredField) {
//               return 'Field is required*';
//             }
//             return null;
//           },
//       onChanged: widget.onChanged,
//       style:
//           getCustomTextStyle(color: widget.textColor, fontSize: FontSize.s16),
//       onTap: widget.onTap,
//       textInputAction: widget.textInputAction,
//       keyboardType: widget.keyboardType,
//       obscureText: widget.obscureText,
//       controller: widget.controller,
//       decoration: InputDecoration(
//         helperMaxLines: 2,

//         helperText: widget.helperText,

//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: AppPadding.p16,
//           vertical: AppPadding.p14, // Taller padding for web
//         ),

//         // ====== Border States ======
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.r8),
//           borderSide: BorderSide(
//             color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.r8),
//           borderSide: BorderSide(
//             color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.r8),
//           borderSide: BorderSide(
//             color: theme.primaryColor,
//             width: 2.0,
//           ),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.r8),
//           borderSide: const BorderSide(
//             color: Colors.red,
//             width: 1.5,
//           ),
//         ),
//         // ====== Colors & Interactions ======
//         fillColor: widget.fillColor,
//         hoverColor: theme.primaryColor.withOpacity(0.05), // Hover effect
//         focusColor: theme.primaryColor.withOpacity(0.1), // Focus effect
//         filled: true,
//         hintStyle: TextStyle(
//           fontSize: FontSize.s14,
//           color: widget.textFieldHintColor,
//         ),
//         errorStyle: const TextStyle(
//           color: Colors.red,
//           fontSize: FontSize.s12,
//         ),
//         prefixIcon: Icon(
//           widget.iconData,
//           color: widget.prefixColor ?? theme.iconTheme.color,
//         ),
//         suffixIcon: widget.wantObscure
//             ? IconButton(
//                 onPressed: showPassword,
//                 icon: Icon(
//                   widget.obscureText
//                       ? Icons.visibility_outlined // Standard "show" icon
//                       : Icons.visibility_off_outlined,
//                   color: widget.obscureText
//                       ? Colors.grey // Dimmed when password is hidden
//                       : theme.primaryColor, // Highlighted when visible
//                 ),
//               )
//             : widget.suffixIcon,
//         hintText: widget.hintText,
//       ),
//     );
//   }
// }
