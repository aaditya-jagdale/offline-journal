import 'package:flutter/material.dart';
import 'package:jrnl/modules/shared/widgets/colors.dart';
import 'package:jrnl/modules/shared/widgets/shadows.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final String hint;
  final String? prefix;
  final TextEditingController? controller;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final Function()? onTap;
  final Function(String)? onChanged;
  final bool autofocus;

  const CustomTextField({
    super.key,
    required this.title,
    required this.hint,
    this.prefix,
    this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
    this.maxLines,
    this.validator,
    this.onSaved,
    this.onTap,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    focusNode.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: AppColors.black),
              boxShadow: focusNode.hasFocus
                  ? [CustomShadows.customShadowPressed]
                  : [CustomShadows.customShadow],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              autofocus: widget.autofocus,
              focusNode: focusNode,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              enabled: widget.enabled,
              controller: widget.controller,
              obscureText: widget.isPassword,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              validator: widget.validator,
              onSaved: widget.onSaved,
              minLines: 1,
              maxLines: widget.maxLines ?? 1,
              decoration: InputDecoration(
                prefix: widget.prefix != null ? Text(widget.prefix!) : null,
                prefixStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.black,
                  fontWeight: FontWeight.normal,
                ),
                counterText: '',
                hintText: '',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.black25,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ).copyWith(hintText: widget.hint),
            ),
          ),
        ],
      ),
    );
  }
}
