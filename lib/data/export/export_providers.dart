import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import 'export_service.dart';

/// Provider for ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final vaultDao = ref.watch(vaultDaoProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  
  return ExportService(
    notesDao: notesDao,
    vaultDao: vaultDao,
    cryptoService: cryptoService,
  );
});
