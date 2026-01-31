import 'package:flutter/material.dart';
import 'package:jrnl/modules/shared/widgets/colors.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  const CustomShimmerBox({
    super.key,
    this.height = 24,
    this.width = 24,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.black26,
      highlightColor: AppColors.black10,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
