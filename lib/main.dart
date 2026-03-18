import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  if (!kIsWeb) {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
    await WidgetService.init();
    await WidgetService.updateWidgetData();
  }

  runApp(
    const ProviderScope(
      child: PlanerApp(),
    ),
  );
}
