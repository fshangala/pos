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
    required String phone,
    required String pin,
  }) async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_bartenders',
        where: 'is_active = ?',
        whereArgs: [1],
      );
      final enteredPhone = _digitsOnly(phone);
      Map<String, Object?>? match;
      for (final row in rows) {
        if (_digitsOnly(row['phone'] as String) == enteredPhone) {
          match = row;
          break;
        }
      }
      if (match == null) return null;
      final bartender = BartenderModel.fromMap(match);
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

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}
