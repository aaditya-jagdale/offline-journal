import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/home/screens/splash_screen.dart';
import 'package:jrnl/modules/settings/screens/login_screen.dart';
import 'package:jrnl/modules/shared/widgets/custom_progress_indicator.dart';
import 'package:jrnl/modules/shared/widgets/transitions.dart';

import 'package:jrnl/riverpod/auth_rvpd.dart';
import 'package:jrnl/riverpod/backup_rvpd.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/services/database_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:jrnl/services/sync_service.dart';
import 'package:intl/intl.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  bool _isBackingUp = false;
  bool _isResetting = false;

  void _handleBackup() async {
    setState(() => _isBackingUp = true);

    try {
      // 1. Ensure Authentication
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Auto-sign in anonymously if not logged in
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user;
      }

      if (user == null) throw Exception('Authentication failed');

      // 2. Perform Sync via Service
      final success = await SyncService.instance.syncIfNeeded(ref);

      ref.invalidate(lastBackupTimeProvider);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Backup successful!')));
        } else {
          // If false, it could be no changes or error. SyncService logs details.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup complete (up to date).')),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('Backup Error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup failed: ${e.toString().split(']').last.trim()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  void _restorePurchases() async {
    try {
      await RevenueCatService.instance.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore purchases: $e')),
        );
      }
    }
  }

  void _signIn() async {
    rightSlideTransition(
      context,
      const LoginScreen(),
      onComplete: () async {
        setState(() {});

        // GET all the data from firebase and replace the existing local data completely
        final user = FirebaseAuth.instance.currentUser;

        // Only restore if user is actually logged in (not anonymous)
        if (user != null && !user.isAnonymous) {
          try {
            debugPrint(
              '[Settings] User logged in, restoring data from Firebase...',
            );

            // Show loading indicator
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restoring your data from cloud...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }

            // Restore all data from Firebase
            final success = await SyncService.instance.restoreFromFirebase();

            if (mounted) {
              if (success) {
                // Refresh the entries list by invalidating the provider
                ref.invalidate(entriesProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data restored from cloud successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to restore data from cloud'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('[Settings] Error restoring data: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error restoring data: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    clearAllAndPush(context, const SplashScreen());
  }

  void _deleteAccount() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. We will delete your account and all associated data within 7 days from our servers.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deletion failed (requires recent login): $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.value;

    // Apple-like grouping colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: [
          // ACCOUNT SECTION
          _SettingsSection(
            title: "Account",
            children: [
              if (user == null || user.isAnonymous)
                _SettingsTile(
                  icon: CupertinoIcons.person_circle,
                  title: "Sign In",
                  iconColor: Colors.blue,
                  onTap: _signIn,
                )
              else ...[
                _SettingsTile(
                  icon: CupertinoIcons.person_fill,
                  title: user.email!,
                  iconColor: Colors.blue,
                  trailing: Icon(Icons.logout, size: 20, color: Colors.red),
                  onTap: _signOut,
                ),
              ],
            ],
          ),

          // DATA SECTION
          _SettingsSection(
            title: "Data",
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final lastBackup = ref.watch(lastBackupTimeProvider);
                  String subtitle = "Never backed up";

                  lastBackup.when(
                    data: (time) {
                      if (time != null) {
                        subtitle =
                            "Last: ${DateFormat('MMM d, h:mm a').format(time)}";
                      }
                    },
                    loading: () => subtitle = "Checking backup status...",
                    error: (err, stack) {
                      subtitle = "Backup status unavailable";
                      debugPrint("Firestore fetch error: $err");
                    },
                  );

                  final isEnabled =
                      ref
                          .watch(preferencesProvider)
                          .value
                          ?.isAutoBackupEnabled ??
                      false;

                  return _SettingsTile(
                    icon: CupertinoIcons.cloud_upload_fill,
                    title: _isBackingUp ? "Backing up..." : "Auto Backup",
                    subtitle: subtitle,
                    iconColor: Colors.purple,
                    onTap: () async {
                      // Optionally still allow manual trigger on tap if not already backing up
                      if (!_isBackingUp) _handleBackup();
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isBackingUp)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        CupertinoSwitch(
                          value: isEnabled,
                          onChanged: (value) {
                            ref
                                .read(preferencesProvider.notifier)
                                .setAutoBackup(value);
                            if (value) {
                              _handleBackup();
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Delete local data, refetch all from cloud
              if (kDebugMode)
                _SettingsTile(
                  icon: CupertinoIcons.trash,
                  title: "Delete Local Data",
                  iconColor: Colors.red,
                  trailing: _isResetting ? CustomProgressIndicator() : null,
                  onTap: () async {
                    setState(() => _isResetting = true);
                    DatabaseService.deleteAllEntries();

                    // GET all the data from firebase and replace the existing local data completely
                    final user = FirebaseAuth.instance.currentUser;

                    // Only restore if user is actually logged in (not anonymous)
                    if (user != null && !user.isAnonymous) {
                      try {
                        debugPrint(
                          '[Settings] User logged in, restoring data from Firebase...',
                        );

                        // Show loading indicator
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Restoring your data from cloud...',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }

                        // Restore all data from Firebase
                        final success = await SyncService.instance
                            .restoreFromFirebase();

                        if (mounted) {
                          if (success) {
                            ref.invalidate(entriesProvider);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Data restored from cloud successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to restore data from cloud',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('[Settings] Error restoring data: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error restoring data: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() => _isResetting = false);
                      }
                    }
                  },
                ),
            ],
          ),

          // LEGAL & SUPPORT
          _SettingsSection(
            title: "Legal & Support",
            children: [
              _SettingsTile(
                icon: CupertinoIcons.lock_fill,
                title: "Privacy Policy",
                iconColor: Colors.grey,
                onTap: () {},
              ),
              _SettingsTile(
                icon: CupertinoIcons.doc_text_fill,
                title: "Terms of Service",
                iconColor: Colors.grey,
                onTap: () {},
              ),
              _SettingsTile(
                icon: CupertinoIcons.arrow_2_circlepath,
                title: "Restore Purchases",
                iconColor: Colors.green,
                onTap: _restorePurchases,
              ),
            ],
          ),

          // DANGER ZONE
          if (user != null)
            _SettingsSection(
              title: "DANGER ZONE",
              children: [
                _SettingsTile(
                  icon: CupertinoIcons.trash_fill,
                  title: "Delete Account",
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  showChevron: false,
                  onTap: _deleteAccount,
                ),
              ],
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: sectionColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 50,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool showChevron;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    this.titleColor,
    this.onTap,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, color: titleColor),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron && trailing == null)
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.grey,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
