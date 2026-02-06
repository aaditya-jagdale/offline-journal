import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  /// Checks for update availability and performs the update flow.
  /// Preferrs Flexible updates, falls back to Immediate if necessary.
  Future<void> checkForUpdate(BuildContext context) async {
    // In-app updates are only available on Android.
    if (!Platform.isAndroid) return;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.flexibleUpdateAllowed) {
          _performFlexibleUpdate(context);
        } else if (info.immediateUpdateAllowed) {
          _performImmediateUpdate();
        }
      } else if (info.installStatus == InstallStatus.downloaded) {
        // If an update is already downloaded (e.g. from previous session), prompt to complete
        _showCompleteUpdateSnackBar(context);
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      if (result == AppUpdateResult.success) {
        _showCompleteUpdateSnackBar(context);
      }
    } catch (e) {
      debugPrint("Flexible update failed: $e");
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint("Immediate update failed: $e");
    }
  }

  void _showCompleteUpdateSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded!'),
        action: SnackBarAction(
          label: 'Restart',
          onPressed: () => InAppUpdate.completeFlexibleUpdate(),
        ),
        duration: const Duration(days: 1), // Keep visible until interaction
      ),
    );
  }
}
