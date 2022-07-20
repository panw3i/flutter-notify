import 'dart:io';

import 'package:flutter/material.dart' hide MenuItem;
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:web_socket_channel/io.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  List<LocalNotification> _notificationList = [];

  final IOWebSocketChannel _channel =
      IOWebSocketChannel.connect(Uri.parse("ws://localhost:9999/ws"));
  ws() async {
    _channel.stream.listen((message) {
      print("Received message: $message");
      LocalNotification? notification = LocalNotification(
        identifier: '_notification',
        title: "Jenkins 打包提醒",
        subtitle: DateTime.now().toString(),
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
      _notificationList.add(notification);
      notification.show();
    });
  }

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    ws();
    _initTray();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    _channel.sink.close();
    super.dispose();
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

  Widget _buildBody(BuildContext context) {
    return ListView.builder(
      itemCount: _notificationList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_notificationList[index].title +
              (_notificationList[index].subtitle ?? "")),
          subtitle: Text(_notificationList[index].body ?? ""),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _notificationList[index].close();
              _notificationList.removeAt(index);
              setState(() {});
            },
          ),
        );
      },
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
