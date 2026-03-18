import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
