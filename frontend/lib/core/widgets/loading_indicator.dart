import 'package:first_try/core/utils/values_manager.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  double? height;
  double? width;
  Color? backgroundColor;
  Color? color;

  LoadingIndicator(
      {super.key, this.height, this.width, this.color, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
          height: height ?? AppSize.s30,
          width: width ?? AppSize.s30,
          child: CircularProgressIndicator(
            backgroundColor: backgroundColor ?? const Color(0xffffc353),
            valueColor:
                AlwaysStoppedAnimation(color ?? const Color(0xff0095d5)),
          )),
    );
  }
}
