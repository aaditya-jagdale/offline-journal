// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:jrnl/modules/shared/widgets/colors.dart';
// import 'package:jrnl/modules/shared/widgets/shadows.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class ImagePickerWidget extends ConsumerStatefulWidget {
//   final String? title;
//   final void Function(File?)? onImageSelected;
//   final File? initialImage;
//   final String? defaultImageUrl;
//   final double? width;
//   final double? height;
//   final bool isLoading;

//   const ImagePickerWidget({
//     super.key,
//     this.title,
//     this.onImageSelected,
//     this.initialImage,
//     this.defaultImageUrl,
//     this.width,
//     this.height,
//     this.isLoading = false,
//   });

//   @override
//   ConsumerState<ImagePickerWidget> createState() => _ImagePickerWidgetState();
// }

// class _ImagePickerWidgetState extends ConsumerState<ImagePickerWidget> {
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _selectedImage = widget.initialImage;
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 800,
//         maxHeight: 800,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//         });
//         widget.onImageSelected?.call(_selectedImage);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error picking image: $e'),
//           backgroundColor: AppColors.red,
//         ),
//       );
//     }
//   }

//   void _removeImage() async {
//     setState(() {
//       _selectedImage = null;
//     });
//     widget.onImageSelected?.call(null);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           if (widget.title != null)
//             Text(
//               widget.title!,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           const SizedBox(height: 8),
//           GestureDetector(
//             onTap: _pickImage,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               width: widget.width ?? 120,
//               height: widget.height ?? 120,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.black),
//                 boxShadow: const [CustomShadows.customShadow],
//               ),
//               child: widget.isLoading
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               AppColors.primary,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Uploading...',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.black50,
//                           ),
//                         ),
//                       ],
//                     )
//                   : (_selectedImage != null || widget.defaultImageUrl != null)
//                   ? Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: _selectedImage != null
//                               ? Image.file(
//                                   _selectedImage!,
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   fit: BoxFit.cover,
//                                 )
//                               : widget.defaultImageUrl != null &&
//                                     widget.defaultImageUrl!.isNotEmpty
//                               ? CachedNetworkImage(
//                                   imageUrl: widget.defaultImageUrl!,
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   fit: BoxFit.cover,
//                                   placeholder: (context, url) => Container(
//                                     color: AppColors.primary10,
//                                     child: const Center(
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor:
//                                             AlwaysStoppedAnimation<Color>(
//                                               AppColors.primary,
//                                             ),
//                                       ),
//                                     ),
//                                   ),
//                                   errorWidget: (context, url, error) =>
//                                       Container(
//                                         color: AppColors.primary10,
//                                         child: const Icon(
//                                           Icons.person,
//                                           color: AppColors.primary,
//                                           size: 40,
//                                         ),
//                                       ),
//                                 )
//                               : Container(
//                                   color: AppColors.primary10,
//                                   child: const Icon(
//                                     Icons.person,
//                                     color: AppColors.primary,
//                                     size: 40,
//                                   ),
//                                 ),
//                         ),
//                         Positioned(
//                           top: 4,
//                           right: 4,
//                           child: GestureDetector(
//                             onTap: () {
//                               _removeImage();
//                             },
//                             child: Container(
//                               width: 24,
//                               height: 24,
//                               decoration: const BoxDecoration(
//                                 color: AppColors.red,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.close,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 4,
//                           right: 4,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.black.withOpacity(0.7),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               Icons.edit,
//                               color: Colors.white,
//                               size: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   : Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: AppColors.primary10,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: const Icon(
//                             Icons.add_photo_alternate_outlined,
//                             color: AppColors.primary,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Add Image',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.black50,
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
