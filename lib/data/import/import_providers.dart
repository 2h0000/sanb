import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import 'import_service.dart';

/// Provider for ImportService
final importServiceProvider = Provider<ImportService>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final vaultDao = ref.watch(vaultDaoProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  
  return ImportService(
    notesDao: notesDao,
    vaultDao: vaultDao,
    cryptoService: cryptoService,
  );
});
