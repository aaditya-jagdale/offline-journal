import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for managing cover images stored locally on device.
/// Images are stored in app documents directory under cover_images/{entryId}.jpg
class CoverImageService {
  static const String _coverImagesDir = 'cover_images';

  /// Get the cover images directory path
  static Future<Directory> _getCoverImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory(p.join(appDir.path, _coverImagesDir));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }
    return coverDir;
  }

  /// Get the expected path for a cover image
  static Future<String> _getCoverImagePath(String entryId) async {
    final dir = await _getCoverImagesDirectory();
    return p.join(dir.path, '$entryId.jpg');
  }

  /// Save a cover image for an entry
  /// Copies the source file to app storage under the entry ID
  static Future<void> saveCoverImage(String entryId, File sourceImage) async {
    final targetPath = await _getCoverImagePath(entryId);
    await sourceImage.copy(targetPath);
  }

  /// Get the cover image file for an entry if it exists
  static Future<File?> getCoverImageFile(String entryId) async {
    final path = await _getCoverImagePath(entryId);
    final file = File(path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Check if a cover image exists for an entry
  static Future<bool> hasCoverImage(String entryId) async {
    final file = await getCoverImageFile(entryId);
    return file != null;
  }

  /// Delete the cover image for an entry
  static Future<void> deleteCoverImage(String entryId) async {
    final path = await _getCoverImagePath(entryId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
