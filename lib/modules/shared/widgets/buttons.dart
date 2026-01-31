import 'package:flutter/services.dart';
import 'package:jrnl/modules/shared/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:jrnl/modules/shared/widgets/custom_progress_indicator.dart';
import 'package:jrnl/modules/shared/widgets/shadows.dart';

class PrimaryButton extends StatefulWidget {
  final String title;
  final TextStyle textStyle;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;

  final void Function()? onPressed;
  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.textStyle = const TextStyle(
      fontSize: 16,
      color: AppColors.white,
      fontWeight: FontWeight.w600,
    ),
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,

      child: Opacity(
        opacity: widget.onPressed == null ? 0.5 : 1,
        child: Container(
          height: 52,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.black,
            border: Border.all(color: AppColors.black),
          ),
          child: widget.isLoading
              ? const Center(
                  child: CustomProgressIndicator(color: AppColors.primary50),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                      widget.mainAxisAlignment ?? MainAxisAlignment.center,
                  crossAxisAlignment:
                      widget.crossAxisAlignment ?? CrossAxisAlignment.center,
                  children: [
                    if (widget.icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: widget.icon,
                      ),
                    Text(widget.title, style: widget.textStyle),
                    if (widget.trailingIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: widget.trailingIcon,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class GhostButton extends StatefulWidget {
  final String title;
  final TextStyle textStyle;
  final Widget icon;
  final Widget trailingIcon;
  final TextAlign? textAlign;
  final void Function()? onPressed;
  const GhostButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.textAlign,
    this.textStyle = const TextStyle(
      fontSize: 18,
      color: AppColors.black,
      fontWeight: FontWeight.normal,
    ),
    this.icon = const SizedBox(),
    this.trailingIcon = const SizedBox(),
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: AppColors.white,
          shadowColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: const BorderSide(color: AppColors.black),
          ),
        ),
        onPressed: widget.onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.icon != const SizedBox())
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: widget.icon,
              ),
            Text(
              widget.title,
              textAlign: widget.textAlign,
              style: widget.textStyle,
            ),
            const Spacer(),
            widget.trailingIcon,
          ],
        ),
      ),
    );
  }
}

class CustomRoundedButton extends StatefulWidget {
  const CustomRoundedButton({
    super.key,
    this.backgroundColor = AppColors.primary,
    required this.onPressed,
    required this.child,
    this.size = 36,
  });

  final Color backgroundColor;
  final Function()? onPressed;
  final Widget child;
  final double size;

  @override
  State<CustomRoundedButton> createState() => _CustomRoundedButtonState();
}

class _CustomRoundedButtonState extends State<CustomRoundedButton> {
  bool isPressed = false;
  final duration = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          isPressed = true;
        });

        Future.delayed(duration, () {
          setState(() {
            isPressed = false;
          });
        });

        widget.onPressed?.call();
      },
      child: AnimatedContainer(
        curve: Curves.easeOutExpo,
        duration: duration,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.black),
          boxShadow: isPressed
              ? [CustomShadows.customShadowPressed]
              : [CustomShadows.customShadow],
        ),
        child: widget.child,
      ),
    );
  }
}
