import 'package:bcrypt/bcrypt.dart';
import 'package:logger/logger.dart';

import '../core/services/local_db_service.dart';
import '../models/bartender_model.dart';

class LocalAuthRepository {
  LocalAuthRepository({required LocalDbService localDb, Logger? logger})
    : _localDb = localDb,
      _logger = logger ?? Logger();

  final LocalDbService _localDb;
  final Logger _logger;

  Future<BartenderModel?> authenticate({
    required String bartenderId,
    required String pin,
  }) async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_bartenders',
        where: 'id = ? AND is_active = ?',
        whereArgs: [bartenderId, 1],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final bartender = BartenderModel.fromMap(rows.single);
      if (!BCrypt.checkpw(pin, bartender.pinHash)) return null;
      return bartender;
    } catch (error, stackTrace) {
      _logger.e(
        'Local bartender authentication failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
