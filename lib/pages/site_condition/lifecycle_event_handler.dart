import 'package:flutter/widgets.dart';

typedef OnLifecycleCallback = Future<void> Function(AppLifecycleState state);

class LifecycleEventHandler extends WidgetsBindingObserver {
  final OnLifecycleCallback onLifecycleEvent;

  LifecycleEventHandler({required this.onLifecycleEvent});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    await onLifecycleEvent(state);
  }
}
