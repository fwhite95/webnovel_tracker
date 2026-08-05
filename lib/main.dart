import 'package:flutter/material.dart';

import 'package:webnovel_tracker/app.dart';
import 'package:webnovel_tracker/core/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const WebNovelTrackerApp());
}
