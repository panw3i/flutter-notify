import 'dart:io';

import 'package:flutter/material.dart' hide MenuItem;
import 'package:local_notifier/local_notifier.dart';
import 'package:preference_list/preference_list.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:web_socket_channel/io.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  final IOWebSocketChannel _channel =
      IOWebSocketChannel.connect(Uri.parse("ws://localhost:9999/ws"));
  ws() async {
    _channel.stream.listen((message) {
      print("Received message: $message");

      LocalNotification? exampleNotification = LocalNotification(
        identifier: '_exampleNotification',
        title: "jenkins",
        body: "$message",
        actions: [
          LocalNotificationAction(
            text: 'Yes',
          ),
          LocalNotificationAction(
            text: 'No',
          ),
        ],
      );

      exampleNotification.show();
    });
  }

  List<LocalNotification> _notificationList = [];

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    ws();
    _initTray();
  }

  void _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          label: 'Show Window',
          onClick: (_) async {
            await windowManager.show();
            await windowManager.setSkipTaskbar(false);
          },
        ),
        MenuItem(
          label: 'Hide Window',
          onClick: (_) async {
            await windowManager.hide();
            await windowManager.setSkipTaskbar(true);
          },
        ),
        MenuItem.separator(),
        MenuItem.separator(),
        MenuItem(
          label: 'Exit App',
          onClick: (_) async {
            await windowManager.destroy();
          },
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    setState(() {});
  }

  _handleNewLocalNotification() async {
    LocalNotification notification = LocalNotification(
      title: "example - ${_notificationList.length}",
      subtitle: "local_notifier_example",
      body: "hello flutter!",
    );
    notification.onShow = () {
      print('onShow ${notification.identifier}');
    };
    notification.onClose = (closeReason) {
      print('onClose ${notification.identifier} - $closeReason');
    };
    notification.onClick = () {
      print('onClick ${notification.identifier}');
    };

    _notificationList.add(notification);

    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        TextButton(
            onPressed: () {
              print("object");
              // _channel.stream.s;
              _channel.sink.add("ping1");
            },
            child: Text("show exampleNotification")),
        Expanded(
          child: PreferenceList(
            children: <Widget>[
              PreferenceListSection(
                children: [
                  PreferenceListItem(
                    title: Text('New a notification'),
                    onTap: _handleNewLocalNotification,
                  ),
                ],
              ),
              for (var notification in _notificationList)
                PreferenceListSection(
                  title: Text('${notification.identifier}'),
                  children: [
                    PreferenceListItem(
                      title: Text('show'),
                      onTap: () => notification.show(),
                    ),
                    PreferenceListItem(
                      title: Text('close'),
                      onTap: () => notification.close(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: _buildBody(context),
    );
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }
}
