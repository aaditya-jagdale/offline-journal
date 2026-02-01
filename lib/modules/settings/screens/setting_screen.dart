import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jrnl/riverpod/auth_rvpd.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/riverpod/backup_rvpd.dart';
import 'package:jrnl/services/firebase_firestore_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:intl/intl.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  bool _isBackingUp = false;

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

      // 2. Get entries safely
      final entries = ref.read(entriesProvider).value ?? [];

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No entries to backup')));
        }
        return;
      }

      // 3. Perform Backup
      await FirebaseFirestoreService.backupAllEntries(entries);
      ref.invalidate(lastBackupTimeProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup successful!')));
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
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await user?.delete();
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
    // TODO: Hook up to RevenueCat provider if you want to show "Pro" status

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
              if (user == null)
                _SettingsTile(
                  icon: CupertinoIcons.person_circle,
                  title: "Sign In",
                  iconColor: Colors.blue,
                  onTap: _signIn,
                )
              else ...[
                _SettingsTile(
                  icon: CupertinoIcons.person_fill,
                  title: "User ID: ${user.uid.substring(0, 5)}...",
                  iconColor: Colors.blue,
                  showChevron: false,
                ),
                _SettingsTile(
                  icon: CupertinoIcons.arrow_right_square,
                  title: "Sign Out",
                  iconColor: Colors.orange,
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

                  return _SettingsTile(
                    icon: CupertinoIcons.cloud_upload_fill,
                    title: _isBackingUp ? "Backing up..." : "Backup Data",
                    subtitle: subtitle,
                    iconColor: Colors.purple,
                    onTap: _isBackingUp || user == null
                        ? null
                        : () async {
                            try {
                              // Re-using the robust _handleBackup logic
                              _handleBackup();

                              // Also performing the test fetch as per user's debug intent
                              final data = await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user.uid)
                                  .get();

                              if (data.exists) {
                                log("User data found: ${data.data()}");
                              } else {
                                log("No user document found for ${user.uid}");
                              }
                            } catch (e) {
                              debugPrint("Error fetching data: $e");
                            }
                          },
                    trailing: _isBackingUp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  );
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
              title: null, // No header for this isolated button usually
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
