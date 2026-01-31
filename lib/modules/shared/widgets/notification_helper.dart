// import 'package:flutter/material.dart';
// import 'package:jrnl/modules/shared/services/notification_service.dart';

// class NotificationHelper {
//   /// Show a test notification
//   static Future<void> showTestNotification() async {
//     await NotificationService.showNotification(
//       title: 'Test Notification',
//       body: 'This is a test notification from Manpower app',
//       payload: 'test_notification',
//     );
//   }

//   /// Show a custom notification
//   static Future<void> showCustomNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     await NotificationService.showNotification(
//       title: title,
//       body: body,
//       payload: payload,
//     );
//   }

//   /// Get FCM token
//   static Future<String?> getFCMToken() async {
//     return await NotificationService.getFCMToken();
//   }

//   /// Subscribe to a topic
//   static Future<void> subscribeToTopic(String topic) async {
//     await NotificationService.subscribeToTopic(topic);
//   }

//   /// Unsubscribe from a topic
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     await NotificationService.unsubscribeFromTopic(topic);
//   }

//   /// Clear all notifications
//   static Future<void> clearAllNotifications() async {
//     await NotificationService.clearAllNotifications();
//   }

//   /// Check if notifications are enabled
//   static Future<bool> areNotificationsEnabled() async {
//     return await NotificationService.areNotificationsEnabled();
//   }

//   /// Request notification permissions
//   static Future<bool> requestPermissions() async {
//     return await NotificationService.requestPermissionsAgain();
//   }
// }

// /// A widget that provides notification testing functionality
// class NotificationTestWidget extends StatelessWidget {
//   const NotificationTestWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Notification Testing',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => NotificationHelper.showTestNotification(),
//                     child: const Text('Test Notification'),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => NotificationHelper.clearAllNotifications(),
//                     child: const Text('Clear All'),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final token = await NotificationHelper.getFCMToken();
//                       if (context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'FCM Token: ${token ?? "Not available"}',
//                             ),
//                             duration: const Duration(seconds: 3),
//                           ),
//                         );
//                       }
//                     },
//                     child: const Text('Get FCM Token'),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final enabled =
//                           await NotificationHelper.areNotificationsEnabled();
//                       if (context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Notifications: ${enabled ? "Enabled" : "Disabled"}',
//                             ),
//                             duration: const Duration(seconds: 2),
//                           ),
//                         );
//                       }
//                     },
//                     child: const Text('Check Status'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
