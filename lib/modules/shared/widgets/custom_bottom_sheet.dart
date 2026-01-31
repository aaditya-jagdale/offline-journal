// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:jrnl/modules/shared/widgets/colors.dart';
// import 'package:jrnl/modules/shared/widgets/shadows.dart';

// class CustomBottomSheet extends StatefulWidget {
//   const CustomBottomSheet({super.key});

//   @override
//   State<CustomBottomSheet> createState() => _CustomBottomSheetState();
// }

// class _CustomBottomSheetState extends State<CustomBottomSheet> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).viewPadding.bottom + 80,
//       color: Colors.white,
//       child: Padding(
//         padding: EdgeInsets.fromLTRB(
//           16,
//           10,
//           16,
//           MediaQuery.of(context).viewPadding.bottom + 10,
//         ),
//         child: Row(
//           spacing: 16,
//           children: [
//             BottomSheetButton(
//               label: "Home",
//               icon: SvgPicture.asset("assets/icons/home.svg"),
//               index: 0,
//             ),
//             BottomSheetButton(
//               label: "Home",
//               icon: SvgPicture.asset("assets/icons/book.svg"),
//               index: 1,
//             ),
//             BottomSheetButton(
//               label: "Home",
//               icon: SvgPicture.asset("assets/icons/person.svg"),
//               index: 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class BottomSheetButton extends ConsumerStatefulWidget {
//   final String label;
//   final Widget icon;
//   final int index;
//   const BottomSheetButton({
//     super.key,
//     required this.label,
//     required this.icon,
//     required this.index,
//   });

//   @override
//   ConsumerState<BottomSheetButton> createState() => _BottomSheetButtonState();
// }

// class _BottomSheetButtonState extends ConsumerState<BottomSheetButton> {
//   @override
//   Widget build(BuildContext context) {
//     final bool isPressed = widget.index == ref.watch(navIndexProvider);
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           HapticFeedback.lightImpact();
//           ref.read(navIndexProvider.notifier).setIndex(widget.index);
//         },
//         child: Opacity(
//           opacity: isPressed ? 1 : 0.75,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: EdgeInsets.all(isPressed ? 0 : 4),
//             width: double.infinity,
//             height: 50,
//             decoration: BoxDecoration(
//               color: AppColors.primary,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppColors.black),
//               boxShadow: isPressed
//                   ? [CustomShadows.customShadowPressed]
//                   : [CustomShadows.customShadow],
//             ),
//             child: Center(child: widget.icon),
//           ),
//         ),
//       ),
//     );
//   }
// }
