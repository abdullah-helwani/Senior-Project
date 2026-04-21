import 'package:flutter/cupertino.dart';

Size getSize(context) {
  return MediaQuery.of(context).size;
}

double getWidth(context) {
  return getSize(context).width;
}

double getHeight(context) {
  return getSize(context).height;
}

double getStatusBarHeight(context) {
  return MediaQuery.of(context).padding.top;
}
