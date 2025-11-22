import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/utils/logger.dart';

const _logger = Logger('Main');

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  _logger.info('Starting app in local-only mode');
  
  // Run the app
  runApp(
    const ProviderScope(
      child: EncryptedNotebookApp(),
    ),
  );
}
