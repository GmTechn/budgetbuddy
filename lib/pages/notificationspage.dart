import 'package:expenses_tracker/components/mybutton.dart';
import 'package:expenses_tracker/models/notificationmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expenses_tracker/providers/notificationprovider.dart';

class NotificationsPage extends StatelessWidget {
  final String email;

  const NotificationsPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.allNotifications;

    return Scaffold(
      backgroundColor: const Color(0xff0f1014),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f1014),
        elevation: 0,
        title: const Text(
          'N O T I F I C A T I O N S',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                "You don't have any notifications!",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];

                      // 🎨 Choose colors based on notification type
                      Color startColor;
                      Color endColor;

                      switch (n.type) {
                        case NotificationType.lowBalance:
                          startColor = const Color(0xff8B0000); // dark red
                          endColor = const Color(0xffB22222); // lighter red
                          break;

                        case NotificationType.highExpense:
                          startColor = const Color(0xffB8860B); // golden brown
                          endColor = const Color(0xffDAA520);
                          break;
                        // case NotificationType.newCard:
                        //   startColor = const Color(0xff006994); // blue
                        //   endColor = const Color(0xff00BFFF);
                        //   glowColor = Colors.blueAccent;
                        //   break;
                        // case NotificationType.cardUpdated:
                        //   startColor = const Color(0xff4B0082); // indigo
                        //   endColor = const Color(0xff8A2BE2);
                        //   glowColor = Colors.purpleAccent;
                        //   break;
                        // case NotificationType.cardRemoved:
                        //   startColor = const Color(0xff5A5A5A); // gray
                        //   endColor = const Color(0xff2F4F4F);
                        //   glowColor = Colors.grey;
                        //   break;
                        // case NotificationType.system:
                        //   startColor = const Color(0xff2F4F4F);
                        //   endColor = const Color(0xff708090);
                        //   glowColor = Colors.cyanAccent;
                        //   break;
                        default:
                          startColor = const Color.fromARGB(
                              255, 44, 101, 46); // dark green
                          endColor = Colors.green; // light green
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Dismissible(
                          key: ValueKey(n.id),
                          background: Container(
                            color: Colors.redAccent.shade700,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              CupertinoIcons.trash_fill,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            notifProvider.deleteNotification(n.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification deleted!'),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: n.read
                                    ? [
                                        startColor =
                                            Color.fromARGB(255, 35, 37, 46),
                                        endColor =
                                            Color.fromARGB(255, 35, 37, 46),
                                      ]
                                    : [startColor, endColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                if (!n.read)
                                  const BoxShadow(
                                    //color: glowColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              title: Text(
                                n.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  n.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                '${n.date?.day}/${n.date?.month}/${n.date?.year}\n${n.date?.hour.toString().padLeft(2, '0')}:${n.date.minute.toString().padLeft(2, '0')}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                notifProvider.markAsRead(n.id);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                MyButton(
                  textbutton: 'Mark all as read',
                  buttonHeight: 45,
                  buttonWidth: 220,
                  onTap: () {
                    notifProvider.markAllAsRead();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          backgroundColor: Color(0xff181a1e),
                          content: Text(
                            "You're all caught up!\nYou have read all the notifications.",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
    );
  }
}
