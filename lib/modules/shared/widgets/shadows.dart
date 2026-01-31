import 'package:flutter/material.dart';
import 'package:jrnl/modules/shared/widgets/colors.dart';

abstract final class CustomShadows {
  static const BoxShadow customShadow = BoxShadow(
    color: AppColors.black,
    blurRadius: 0,
    offset: Offset(0, 4),
  );
  static const BoxShadow customShadowPressed = BoxShadow(
    color: AppColors.black,
    blurRadius: 0,
    offset: Offset(0, 1),
  );
}
