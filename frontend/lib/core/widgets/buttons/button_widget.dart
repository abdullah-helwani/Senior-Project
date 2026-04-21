import 'package:first_try/core/utils/app_color.dart';
import 'package:first_try/core/utils/app_fonts.dart';
import 'package:first_try/core/utils/app_style.dart';
import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget(
      {super.key,
      required this.label,
      required this.onPressed,
      this.color,
      this.padding,
      this.fontSize});

  final String label;
  final void Function()? onPressed;
  final Color? color;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color ?? ColorManager.textSelectedColor,
        disabledBackgroundColor: ColorManager.iputTextFieldColor,
      ),
      child: Text(
        label,
        style: getCustomTextStyle(
          color: Colors.white,
          fontSize: fontSize ?? FontSize.s18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
