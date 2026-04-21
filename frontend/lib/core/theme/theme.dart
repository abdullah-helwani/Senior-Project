// import 'package:flutter/material.dart';
// import 'package:qr_certificate/core/utils/app_color.dart';
// import 'package:qr_certificate/core/utils/app_style.dart';

// // todo must add the second and third and fourth color
// // todo see the chatGpt chat archive he give me a way to make a extension in themeData

// class MyTheme extends ThemeExtension<MyTheme> {
//   final Color? secondaryColor;
//   final Color? thirdColor;
//   final Color? fourthColor;
//   final Color? textColor;
//   final Color? textButtonColor;
//   final Color? backgroundColor1;
//   final Color? backgroundColor2;
//   final Color? backgroundColor3;
//   const MyTheme({
//     this.fourthColor,
//     this.secondaryColor,
//     this.thirdColor,
//     this.textColor,
//     this.textButtonColor,
//     this.backgroundColor1,
//     this.backgroundColor2,
//     this.backgroundColor3,
//   });

//   @override
//   MyTheme copyWith({
//     Color? secondaryColor,
//     Color? thirdColor,
//     Color? fourthColor,
//     Color? textColor,
//     Color? textButtonColor,
//     Color? backgroundColor1,
//     Color? backgroundColor2,
//     Color? backgroundColor3,
//   }) {
//     return MyTheme(
//       fourthColor: fourthColor ?? this.fourthColor,
//       secondaryColor: secondaryColor ?? this.secondaryColor,
//       thirdColor: thirdColor ?? this.thirdColor,
//       textColor: textColor ?? this.textColor,
//       textButtonColor: textButtonColor ?? this.textButtonColor,
//       backgroundColor1: backgroundColor1 ?? this.backgroundColor1,
//       backgroundColor2: backgroundColor2 ?? this.backgroundColor2,
//       backgroundColor3: backgroundColor3 ?? this.backgroundColor3,
//     );
//   }

//   @override
//   ThemeExtension<MyTheme> lerp(ThemeExtension<MyTheme>? other, double t) {
//     if (other is! MyTheme) {
//       return this;
//     }
//     return MyTheme(
//       fourthColor: Color.lerp(fourthColor, other.fourthColor, t),
//       secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t),
//       thirdColor: Color.lerp(thirdColor, other.thirdColor, t),
//       textColor: Color.lerp(textColor, other.textColor, t),
//       textButtonColor: Color.lerp(textButtonColor, other.textButtonColor, t),
//       backgroundColor1: Color.lerp(backgroundColor1, other.backgroundColor1, t),
//       backgroundColor2: Color.lerp(backgroundColor2, other.backgroundColor2, t),
//       backgroundColor3: Color.lerp(backgroundColor3, other.backgroundColor3, t),
//     );
//   }
// }

// final ThemeData lightTheme = ThemeData(
//     datePickerTheme: DatePickerThemeData(
//       backgroundColor:
//           ColorManager.backgroundColor, // DatePicker dialog background

//       // Header customization
//       headerBackgroundColor: ColorManager.whiteColor,
//       headerForegroundColor: ColorManager.textColor,
//       headerHeadlineStyle: getSubTiltle(color: ColorManager.textColor),
//       headerHelpStyle: getParagraph(color: ColorManager.greyColor),

//       // Day picker customization
//       dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.whiteColor; // Selected day text color
//           } else if (states.contains(WidgetState.disabled)) {
//             return ColorManager.greyColor; // Disabled day text color
//           }
//           return ColorManager.textColor; // Default day text color
//         },
//       ),
//       dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.primaryColor; // Selected day background
//           }
//           return null; // Default transparent background
//         },
//       ),
//       dayOverlayColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.hovered)) {
//             return ColorManager.primaryColor.withOpacity(0.08); // Hover color
//           } else if (states.contains(WidgetState.focused)) {
//             return ColorManager.primaryColor.withOpacity(0.12); // Focused color
//           }
//           return null;
//         },
//       ),
//       dayShape: WidgetStateProperty.all<OutlinedBorder>(
//         CircleBorder(), // Circular shape for days
//       ),

//       // Today customization
//       todayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.whiteColor; // Selected today text color
//           }
//           return ColorManager.primaryColor; // Default today text color
//         },
//       ),
//       todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.primaryColor; // Selected today background
//           }
//           return null;
//         },
//       ),
//       todayBorder: BorderSide(
//         color: ColorManager.primaryColor,
//         width: 1.5,
//       ),

//       // Year picker customization
//       yearForegroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.whiteColor; // Selected year text color
//           }
//           return ColorManager.textColor; // Default year text color
//         },
//       ),
//       yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.primaryColor; // Selected year background
//           }
//           return null; // Default transparent background
//         },
//       ),
//       yearOverlayColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.hovered)) {
//             return ColorManager.primaryColor.withOpacity(0.08); // Hover effect
//           } else if (states.contains(WidgetState.focused)) {
//             return ColorManager.primaryColor
//                 .withOpacity(0.12); // Focused effect
//           }
//           return null;
//         },
//       ),

//       // Range picker customization
//       rangePickerBackgroundColor: ColorManager.backgroundColor,
//       rangePickerHeaderBackgroundColor: ColorManager.whiteColor,
//       rangePickerHeaderForegroundColor: ColorManager.textColor,
//       rangeSelectionBackgroundColor:
//           ColorManager.primaryColor.withOpacity(0.12),
//       rangeSelectionOverlayColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.hovered)) {
//             return ColorManager.primaryColor.withOpacity(0.08); // Hover effect
//           } else if (states.contains(WidgetState.focused)) {
//             return ColorManager.primaryColor
//                 .withOpacity(0.12); // Focused effect
//           }
//           return null;
//         },
//       ),
//     ),
//     appBarTheme: AppBarTheme(
//       backgroundColor: ColorManager.whiteColor,
//       titleTextStyle: getSubTiltle(color: ColorManager.blackColor),
//     ),
//     brightness: Brightness.dark,
//     // useWidget3: true,
//     primaryColor: ColorManager.primaryColor,
//     scaffoldBackgroundColor: ColorManager.backgroundColor,
//     navigationBarTheme: NavigationBarThemeData(
//         backgroundColor: ColorManager.whiteColor,
//         indicatorColor: ColorManager.primaryColor,
//         labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
//             (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return getItemNavBarLabelStyle(
//                 selectedColor: ColorManager.primaryColor, isSelected: true);
//           }
//           return getItemNavBarLabelStyle(
//               selectedColor: ColorManager.primaryColor, isSelected: false);
//         }),
//         labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
//         iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
//             (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return const IconThemeData(color: ColorManager.whiteColor);
//           }
//           return const IconThemeData(color: ColorManager.anactiveNavBarItem);
//         })),
//     colorScheme: ColorScheme.fromSeed(
//       /// tertiary color to text color
//       tertiary: ColorManager.primaryColor,
//       brightness: Brightness.dark,
//       seedColor: ColorManager.primaryColor,
//       secondary: ColorManager.secondaryColor,
//       primary: ColorManager.primaryColor,
//       onPrimary: ColorManager.thirdColor,
//       onSecondary: ColorManager.fourthColor,
//     ),
//     extensions: <ThemeExtension<dynamic>>[
//       MyTheme(
//           secondaryColor: ColorManager.secondaryColor,
//           thirdColor: ColorManager.thirdColor,
//           fourthColor: ColorManager.fourthColor,
//           textColor: ColorManager.textColor,
//           textButtonColor: ColorManager.greyColor,
//           backgroundColor1: ColorManager.whiteColor,
//           backgroundColor2: const Color(0xFFE6E5Eb), //#E5E1F4
//           backgroundColor3: const Color(0xFFF0EDFB))
//     ]);

// final ThemeData darkTheme = ThemeData(
//     datePickerTheme: DatePickerThemeData(
//       backgroundColor:
//           ColorManager.darkBackgroundColor, // DatePicker dialog background

//       // Header customization
//       headerBackgroundColor: ColorManager.navBarBackgroundColor,
//       headerForegroundColor: ColorManager.whiteColor,
//       headerHeadlineStyle: getSubTiltle(color: ColorManager.primaryColor),
//       headerHelpStyle: getParagraph(color: ColorManager.greyColor),

//       // Day picker customization
//       dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.whiteColor; // Selected day text color
//           } else if (states.contains(WidgetState.disabled)) {
//             return ColorManager.greyColor; // Disabled day text color
//           }
//           return ColorManager.whiteColor; // Default day text color
//         },
//       ),
//       dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.primaryColor; // Selected day background
//           }
//           return null; // Default transparent background
//         },
//       ),
//       dayOverlayColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.hovered)) {
//             return ColorManager.primaryColor.withOpacity(0.08); // Hover color
//           } else if (states.contains(WidgetState.focused)) {
//             return ColorManager.primaryColor.withOpacity(0.12); // Focused color
//           }
//           return null;
//         },
//       ),
//       dayShape: WidgetStateProperty.all<OutlinedBorder>(
//         CircleBorder(), // Circular shape for days
//       ),

//       // Today customization
//       todayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.whiteColor; // Selected today text color
//           }
//           return ColorManager.primaryColor; // Default today text color
//         },
//       ),
//       todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.primaryColor; // Selected today background
//           }
//           return null;
//         },
//       ),
//       todayBorder: const BorderSide(
//         color: ColorManager.primaryColor,
//         width: 1.5,
//       ),

//       // Year picker customization
//       yearForegroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.whiteColor; // Selected year text color
//           }
//           return ColorManager.greyColor; // Default year text color
//         },
//       ),
//       yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return ColorManager.primaryColor; // Selected year background
//           }
//           return null; // Default transparent background
//         },
//       ),
//       yearOverlayColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.hovered)) {
//             return ColorManager.primaryColor.withOpacity(0.08); // Hover effect
//           } else if (states.contains(WidgetState.focused)) {
//             return ColorManager.primaryColor
//                 .withOpacity(0.12); // Focused effect
//           }
//           return null;
//         },
//       ),

//       // Range picker customization
//       rangePickerBackgroundColor: ColorManager.darkBackgroundColor,
//       rangePickerHeaderBackgroundColor: ColorManager.navBarBackgroundColor,
//       rangePickerHeaderForegroundColor: ColorManager.whiteColor,
//       rangeSelectionBackgroundColor:
//           ColorManager.primaryColor.withOpacity(0.12),
//       rangeSelectionOverlayColor: WidgetStateProperty.resolveWith<Color?>(
//         (Set<WidgetState> states) {
//           if (states.contains(WidgetState.hovered)) {
//             return ColorManager.primaryColor.withOpacity(0.08); // Hover effect
//           } else if (states.contains(WidgetState.focused)) {
//             return ColorManager.primaryColor
//                 .withOpacity(0.12); // Focused effect
//           }
//           return null;
//         },
//       ),
//     ),
//     appBarTheme: AppBarTheme(
//       backgroundColor: ColorManager.navBarBackgroundColor,
//       titleTextStyle: getSubTiltle(color: ColorManager.whiteColor),
//     ),
//     brightness: Brightness.light,
//     scaffoldBackgroundColor:
//         // Color(0xff494454),
//         ColorManager.backgroundColor,
//     primaryColor: ColorManager.darkPrimaryColor,
//     navigationBarTheme: NavigationBarThemeData(
//         backgroundColor: ColorManager.navBarBackgroundColor,
//         indicatorColor: ColorManager.darkSecondaryColor,
//         labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
//             (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return getItemNavBarLabelStyle(
//                 selectedColor: ColorManager.darkSecondaryColor,
//                 isSelected: true);
//           }
//           return getItemNavBarLabelStyle(
//               selectedColor: ColorManager.darkSecondaryColor,
//               isSelected: false);
//         }),
//         labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
//         iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
//             (Set<WidgetState> states) {
//           if (states.contains(WidgetState.selected)) {
//             return const IconThemeData(color: ColorManager.darkGreyColor);
//           }
//           return const IconThemeData(color: ColorManager.anactiveNavBarItem);
//         })),
//     colorScheme: ColorScheme.fromSeed(
//       /// tertiary color to text color
//       tertiary: ColorManager.whiteColor,
//       brightness: Brightness.light,
//       seedColor: ColorManager.darkPrimaryColor,
//       secondary: ColorManager.darkSecondaryColor,
//       primary: ColorManager.darkPrimaryColor,
//       onPrimary: ColorManager.darkThirdColor,
//       onSecondary: ColorManager.darkFourthColor,
//     ),
//     extensions: const <ThemeExtension<dynamic>>[
//       MyTheme(
//           secondaryColor: ColorManager.darkSecondaryColor,
//           thirdColor: ColorManager.darkThirdColor,
//           fourthColor: ColorManager.darkFourthColor,
//           textColor: ColorManager.whiteColor,
//           textButtonColor: ColorManager.whiteColor,
//           // backgroundColor1: ColorManager.darkBackgroundColor3,
//           backgroundColor1: ColorManager.whiteColor,
//           backgroundColor2: ColorManager.darkBackgroundColor2,
//           backgroundColor3: ColorManager.darkGreyColor)
//     ]);
