import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/services/firebase_firestore_service.dart';
import 'package:jrnl/riverpod/auth_rvpd.dart';

final lastBackupTimeProvider = FutureProvider<DateTime?>((ref) async {
  // Watch user so we refetch if user changes
  ref.watch(userProvider);
  return FirebaseFirestoreService.getLastBackupTime();
});
