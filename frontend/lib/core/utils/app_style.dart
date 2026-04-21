import 'package:first_try/core/utils/app_color.dart';
import 'package:first_try/core/utils/app_fonts.dart';
import 'package:flutter/material.dart';

TextStyle _getTextStyle(
    {double? fontSize,
    TextDecoration? decoration,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    String? fontFamily,
    bool isArabic = false}) {
  return TextStyle(
      fontFamily:
          isArabic ? FontManager.fontFamilyAR : FontManager.fontFamilyEN,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      decoration: decoration ?? TextDecoration.none,
      color: color);
}

TextStyle getTiltle({bool isArabic = false, Color? color, double? fontSize}) {
  return _getTextStyle(
    fontFamily:
        isArabic ? FontManager.fontFamilyAR : FontManager.fontFamilyTitleEN,
    fontSize: fontSize ?? FontSize.s60,
    fontWeight: FontWegihtManager.extraBold,
    color: color ?? ColorManager.textHeadOne,
    isArabic: isArabic,
  );
}

TextStyle getSecondaryTiltle({bool isArabic = false}) {
  return _getTextStyle(
    fontSize: FontSize.s48,
    fontWeight: FontWegihtManager.bold,
    color: ColorManager.textHeadTwo,
    isArabic: isArabic,
  );
}

TextStyle getSubTiltle(
    {bool isArabic = false,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s24,
    fontWeight: fontWeight ?? FontWegihtManager.medium,
    color: color ?? ColorManager.textHeadThree,
    isArabic: isArabic,
  );
}

TextStyle getHeaderFour({bool isArabic = false, Color? color}) {
  return _getTextStyle(
    fontSize: FontSize.s14,
    fontWeight: FontWegihtManager.light,
    color: color ?? ColorManager.textHeadFour,
    isArabic: isArabic,
  );
}

TextStyle getMediumStyle({
  bool isArabic = false,
  Color? color,
  double? fontSize,
  TextDecoration? decoration,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s16,
    fontWeight: FontWegihtManager.medium,
    color: color ??
        ColorManager.textParagraphs, // Or your default medium text color
    isArabic: isArabic,
    decoration: decoration,
  );
}

TextStyle getParagraph(
    {bool isArabic = false,
    Color? color,
    bool isMedium = true,
    double? fontSize}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s16,
    fontWeight: isMedium ? FontWegihtManager.medium : FontWegihtManager.regular,
    color: color ?? ColorManager.darkGreyColor, //todo edit the color
    isArabic: isArabic,
  );
}

TextStyle getLabelTextFormField({bool isArabic = false, Color? color}) {
  return _getTextStyle(
    fontSize: FontSize.s16,
    fontWeight: FontWegihtManager.medium,
    color: color ?? ColorManager.textParagraphs,
    isArabic: isArabic,
  );
}

TextStyle getStyleTextFormField({bool isArabic = false}) {
  return _getTextStyle(
    decoration: TextDecoration.none,
    fontSize: FontSize.s16,
    fontWeight: FontWegihtManager.medium,
    color: ColorManager.primaryColor,
    isArabic: isArabic,
  );
}

TextStyle getCustomTextStyle(
    {bool isArabic = false,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s16,
    fontWeight: fontWeight ?? FontWegihtManager.regular,
    color: color ?? ColorManager.primaryColor,
    isArabic: isArabic,
  );
}

TextStyle getItemNavBarLabelStyle({
  bool isArabic = false,
  bool isSelected = false,
  required Color selectedColor,
}) {
  return _getTextStyle(
    fontSize: isSelected ? FontSize.s12 : FontSize.s14,
    fontWeight: isSelected ? FontWegihtManager.bold : FontWegihtManager.medium,
    color: isSelected ? selectedColor : ColorManager.anactiveNavBarItem,
    isArabic: isArabic,
  );
}

TextStyle getSmallLabel({
  bool isArabic = false,
  double? fontSize,
  Color? color,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s12,
    fontWeight: FontWegihtManager.light,
    color: color ?? ColorManager.greyColor,
    isArabic: isArabic,
  );
}

TextStyle getTitleStyle({
  bool isArabic = false,
  double? fontSize,
  Color? color,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s28,
    fontWeight: FontWegihtManager.semiBold,
    color: color ?? ColorManager.titleColor,
    isArabic: isArabic,
  );
}

TextStyle getSubTitleStyle({
  bool isArabic = false,
  FontWeight? fontWeight,
  double? fontSize,
  Color? color,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? FontSize.s22,
    fontWeight: fontWeight ?? FontWegihtManager.semiBold,
    color: color ?? ColorManager.titleColor,
    isArabic: isArabic,
  );
}
