import 'package:flutter/material.dart';
import 'package:jrnl/modules/shared/widgets/colors.dart';

class manpowerLogo extends StatelessWidget {
  final double fontSize;
  const manpowerLogo({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Zun',
              style: TextStyle(
                height: 1,
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'day',
              style: TextStyle(
                height: 1,
                color: AppColors.primary,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
