import 'dart:io';
import 'dart:math';

import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/transactionEntry/transactionLabel.dart';
import 'package:budget/widgets/util/showTimePicker.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/timeDigits.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

bool notificationsGlobalEnabled = kIsWeb == false;

class DailyNotificationsSettings extends StatefulWidget {
  const DailyNotificationsSettings({super.key});

  @override
  State<DailyNotificationsSettings> createState() =>
      _DailyNotificationsSettingsState();
}

class _DailyNotificationsSettingsState
    extends State<DailyNotificationsSettings> {
  bool notificationsEnabled = appStateSettings["notifications"];
  TimeOfDay timeOfDay = TimeOfDay(
      hour: appStateSettings["notificationHour"],
      minute: appStateSettings["notificationMinute"]);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainerSwitch(
          title: "daily-notifications".tr(),
          description: "daily-notifications-description".tr(),
          onSwitched: (value) async {
            updateSettings("notifications", value, updateGlobalState: false);
            if (value == true) {
              await initializeNotificationsPlatform();
              await scheduleDailyNotification(context, timeOfDay);
            } else {
              await cancelDailyNotification();
            }
            setState(() {
              notificationsEnabled = !notificationsEnabled;
            });
            return true;
          },
          initialValue: appStateSettings["notifications"],
          icon: Icons.calendar_today_rounded,
        ),
        AnimatedSize(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutCubicEmphasized,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: notificationsEnabled
                ? SettingsContainer(
                    key: ValueKey(1),
                    title: "alert-time".tr(),
                    icon: Icons.timer,
                    onTap: () async {
                      TimeOfDay? newTime =
                          await showCustomTimePicker(context, timeOfDay);
                      if (newTime != null) {
                        await initializeNotificationsPlatform();
                        await scheduleDailyNotification(context, newTime);
                        setState(() {
                          timeOfDay = newTime;
                        });
                        updateSettings(
                          "notificationHour",
                          timeOfDay.hour,
                          pagesNeedingRefresh: [],
                          updateGlobalState: false,
                        );
                        updateSettings(
                          "notificationMinute",
                          timeOfDay.minute,
                          pagesNeedingRefresh: [],
                          updateGlobalState: false,
                        );
                      }
                    },
                    afterWidget: TimeDigits(timeOfDay: timeOfDay),
                  )
                : Container(),
          ),
        ),
        Divider(
          indent: 20,
          endIndent: 20,
          color: getColor(context, "dividerColor"),
        ),
      ],
    );
  }
}

class UpcomingTransactionsNotificationsSettings extends StatefulWidget {
  const UpcomingTransactionsNotificationsSettings({super.key});

  @override
  State<UpcomingTransactionsNotificationsSettings> createState() =>
      _UpcomingTransactionsNotificationsSettingsState();
}

class _UpcomingTransactionsNotificationsSettingsState
    extends State<UpcomingTransactionsNotificationsSettings> {
  bool notificationsEnabled =
      appStateSettings["notificationsUpcomingTransactions"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainerSwitch(
          title: "upcoming-transactions".tr(),
          onSwitched: (value) async {
            updateSettings("notificationsUpcomingTransactions", value,
                updateGlobalState: false);
            if (value == true) {
              await initializeNotificationsPlatform();
              await scheduleUpcomingTransactionsNotification(context);
            } else {
              await cancelUpcomingTransactionsNotification();
            }
            setState(() {
              notificationsEnabled = !notificationsEnabled;
            });
            return true;
          },
          initialValue: appStateSettings["notificationsUpcomingTransactions"],
          icon: Icons.calendar_month_rounded,
        ),
        IgnorePointer(
          ignoring: !notificationsEnabled,
          child: AnimatedOpacity(
            opacity: notificationsEnabled ? 1 : 0,
            duration: Duration(milliseconds: 300),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: getColor(context, "lightDarkAccent"),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: StreamBuilder<List<Transaction>>(
                  stream: database.watchAllUpcomingTransactions(
                      startDate: null, endDate: null),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          for (Transaction transaction in snapshot.data!)
                            StreamBuilder<TransactionCategory>(
                              stream: database
                                  .getCategory(transaction.categoryFk)
                                  .$1,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return SettingsContainerSwitch(
                                    onLongPress: () {
                                      pushRoute(
                                        context,
                                        AddTransactionPage(
                                          transaction: transaction,
                                          routesToPopAfterDelete:
                                              RoutesToPopAfterDelete.One,
                                        ),
                                      );
                                    },
                                    onTap: () {
                                      pushRoute(
                                        context,
                                        AddTransactionPage(
                                          transaction: transaction,
                                          routesToPopAfterDelete:
                                              RoutesToPopAfterDelete.One,
                                        ),
                                      );
                                    },
                                    icon: getTransactionTypeIcon(
                                        transaction.type),
                                    title: getTransactionLabelSync(
                                        transaction, snapshot.data!),
                                    description: getWordedDateShortMore(
                                            transaction.dateCreated) +
                                        ", " +
                                        getWordedTime(transaction.dateCreated),
                                    onSwitched: (value) async {
                                      await database.createOrUpdateTransaction(
                                          transaction.copyWith(
                                              upcomingTransactionNotification:
                                                  Value(value)));
                                      await initializeNotificationsPlatform();
                                      await scheduleUpcomingTransactionsNotification(
                                          context);
                                      return;
                                    },
                                    syncWithInitialValue: false,
                                    initialValue: transaction
                                            .upcomingTransactionNotification ??
                                        true,
                                  );
                                }
                                return Container();
                              },
                            )
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<String> _reminderStrings = [
  for (int i = 1; i <= 26; i++) "notification-reminder-" + i.toString()
];

Future<bool> scheduleDailyNotification(context, TimeOfDay timeOfDay,
    {bool scheduleNowDebug = false}) async {
  // If the app was opened on the day the notification was scheduled it will be
  // cancelled and set to the next day because of _nextInstanceOfSetTime
  await cancelDailyNotification();

  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'transactionReminders',
    'Transaction Reminders',
    importance: Importance.max,
    priority: Priority.high,
    color: Theme.of(context).colorScheme.primary,
  );

  DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(threadIdentifier: 'transactionReminders');

  // schedule a week worth of notifications
  for (int i = 1; i <= 7; i++) {
    String chosenMessage =
        _reminderStrings[Random().nextInt(_reminderStrings.length)].tr();
    tz.TZDateTime dateTime = _nextInstanceOfSetTime(timeOfDay, dayOffset: i);
    if (scheduleNowDebug)
      dateTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: i * 5));
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      i,
      'notification-reminder-title'.tr(),
      chosenMessage,
      dateTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      payload: 'addTransaction',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    print("Notification " +
        chosenMessage +
        " scheduled for " +
        dateTime.toString() +
        " with id " +
        i.toString());
  }

  // final List<PendingNotificationRequest> pendingNotificationRequests =
  //     await flutterLocalNotificationsPlugin.pendingNotificationRequests();

  return true;
}

Future<bool> cancelDailyNotification() async {
  for (int i = 1; i <= 7; i++) {
    await flutterLocalNotificationsPlugin.cancel(i);
  }
  print("Cancelled notifications for daily reminder");
  return true;
}

Future<bool> scheduleUpcomingTransactionsNotification(context) async {
  await cancelUpcomingTransactionsNotification();

  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'upcomingTransactions',
    'Upcoming Transactions',
    importance: Importance.max,
    priority: Priority.high,
    color: Theme.of(context).colorScheme.primary,
  );

  DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(threadIdentifier: 'upcomingTransactions');

  List<Transaction> upcomingTransactions =
      await database.getAllUpcomingTransactions(
    startDate: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day - 1),
    endDate: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day + 365),
  );
  // print(upcomingTransactions);
  int idStart = 100;
  for (Transaction upcomingTransaction in upcomingTransactions) {
    idStart++;
    // Note: if upcomingTransactionNotification is NULL the loop will continue and schedule a notification
    if (upcomingTransaction.upcomingTransactionNotification == false) continue;
    if (upcomingTransaction.dateCreated.year == DateTime.now().year &&
        upcomingTransaction.dateCreated.month == DateTime.now().month &&
        upcomingTransaction.dateCreated.day == DateTime.now().day &&
        (upcomingTransaction.dateCreated.hour < DateTime.now().hour ||
            (upcomingTransaction.dateCreated.hour == DateTime.now().hour &&
                upcomingTransaction.dateCreated.minute <=
                    DateTime.now().minute))) {
      continue;
    }
    String chosenMessage = await getTransactionLabel(upcomingTransaction);
    tz.TZDateTime dateTime = tz.TZDateTime(
      tz.local,
      upcomingTransaction.dateCreated.year,
      upcomingTransaction.dateCreated.month,
      upcomingTransaction.dateCreated.day,
      upcomingTransaction.dateCreated.hour,
      upcomingTransaction.dateCreated.minute,
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    if (upcomingTransaction.dateCreated.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        idStart,
        'notification-upcoming-transaction-title'.tr(),
        chosenMessage,
        dateTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        payload: 'upcomingTransaction',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      print("Cannot set up notification before current time!");
    }

    print("Notification " +
        chosenMessage +
        " scheduled for " +
        dateTime.toString() +
        " with id " +
        upcomingTransaction.transactionPk.toString());
  }

  return true;
}

Future<bool> cancelUpcomingTransactionsNotification() async {
  List<Transaction> upcomingTransactions =
      await database.getAllUpcomingTransactions(
    startDate: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day - 1),
    endDate: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day + 30),
  );
  int idStart = 100;
  for (Transaction upcomingTransaction in upcomingTransactions) {
    idStart++;
    await flutterLocalNotificationsPlugin.cancel(idStart);
  }
  print("Cancelled notifications for upcoming");
  return true;
}

tz.TZDateTime _nextInstanceOfSetTime(TimeOfDay timeOfDay, {int dayOffset = 0}) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  // tz.TZDateTime scheduledDate = tz.TZDateTime(
  //     tz.local, now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  // if (scheduledDate.isBefore(now)) {
  //   scheduledDate = scheduledDate.add(const Duration(days: 1));
  // }

  // add one to current day (if app wasn't opened, it will notify)
  tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
      now.day + dayOffset, timeOfDay.hour, timeOfDay.minute);

  return scheduledDate;
}

Future<bool> initializeNotificationsPlatform() async {
  if (kIsWeb || Platform.isLinux) {
    return false;
  }
  try {
    if (Platform.isAndroid) await checkNotificationsPermissionAndroid();
    if (Platform.isIOS) await checkNotificationsPermissionIOS();
  } catch (e) {
    print("Error setting up notifications: " + e.toString());
    return false;
  }
  print("Notifications initialized");
  return true;
}

Future<bool> checkNotificationsPermissionIOS() async {
  bool? result = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  if (result != true) return false;
  return true;
}

Future<bool> checkNotificationsPermissionAndroid() async {
  bool? result = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();
  if (result != true) return false;
  return true;
}
