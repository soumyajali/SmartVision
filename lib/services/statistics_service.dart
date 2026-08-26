import 'dart:developer';
import 'package:intl/intl.dart';
import 'database_service.dart';

class StatisticsService {
  final DatabaseService _databaseService;

  StatisticsService(this._databaseService);

  Future<int> getTotalDetections() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT SUM(count) as total FROM statistics');
      final val = result.first['total'];
      return val != null ? (val as int) : 0;
    } catch (e) {
      log('Error getting total detections: $e');
      return 0;
    }
  }

  Future<int> getUniqueObjectCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT COUNT(DISTINCT object_name) as count FROM statistics');
      final val = result.first['count'];
      return val != null ? (val as int) : 0;
    } catch (e) {
      log('Error getting unique object count: $e');
      return 0;
    }
  }

  Future<String> getMostDetectedObject() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('''
        SELECT object_name, SUM(count) as total_count 
        FROM statistics 
        GROUP BY object_name 
        ORDER BY total_count DESC 
        LIMIT 1
      ''');
      
      if (result.isNotEmpty) {
        return result.first['object_name'] as String;
      }
      return 'None';
    } catch (e) {
      log('Error getting most detected object: $e');
      return 'Error';
    }
  }

  Future<int> getTodayDetectionCount() async {
    try {
      final db = await _databaseService.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await db.rawQuery('''
        SELECT SUM(count) as total 
        FROM statistics 
        WHERE date = ?
      ''', [today]);
      
      final val = result.first['total'];
      return val != null ? (val as int) : 0;
    } catch (e) {
      log('Error getting today detection count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getObjectDetectionFrequency() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('''
        SELECT object_name, SUM(count) as total_count 
        FROM statistics 
        GROUP BY object_name 
        ORDER BY total_count DESC
      ''');
      
      Map<String, int> frequency = {};
      for (var row in result) {
        frequency[row['object_name'] as String] = row['total_count'] as int;
      }
      return frequency;
    } catch (e) {
      log('Error getting object frequency: $e');
      return {};
    }
  }

  // Parses timestamps from the raw detections table to get exact time of day
  Future<Map<String, int>> getTimeBasedStatistics() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT timestamp FROM detections');
      
      int morning = 0;   // 6 - 12
      int afternoon = 0; // 12 - 18
      int evening = 0;   // 18 - 22
      int night = 0;     // 22 - 6

      for (var row in result) {
        final timestampStr = row['timestamp'] as String;
        final date = DateTime.tryParse(timestampStr);
        if (date != null) {
          final hour = date.hour;
          if (hour >= 6 && hour < 12) {
            morning++;
          } else if (hour >= 12 && hour < 18) {
            afternoon++;
          } else if (hour >= 18 && hour < 22) {
            evening++;
          } else {
            night++;
          }
        }
      }

      return {
        'Morning': morning,
        'Afternoon': afternoon,
        'Evening': evening,
        'Night': night,
      };
    } catch (e) {
      log('Error getting time based statistics: $e');
      return {'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
    }
  }

  Future<Map<String, int>> getWeeklyDetectionTrend() async {
    try {
      final db = await _databaseService.database;
      
      // We will look at the last 7 days
      final now = DateTime.now();
      Map<String, int> weeklyData = {};
      
      // Initialize last 7 days with 0
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        weeklyData[dateStr] = 0;
      }

      final limitDateStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 6)));

      final result = await db.rawQuery('''
        SELECT date, SUM(count) as total_count 
        FROM statistics 
        WHERE date >= ?
        GROUP BY date
      ''', [limitDateStr]);
      
      for (var row in result) {
        final date = row['date'] as String;
        if (weeklyData.containsKey(date)) {
          weeklyData[date] = row['total_count'] as int;
        }
      }
      
      return weeklyData;
    } catch (e) {
      log('Error getting weekly trend: $e');
      return {};
    }
  }
}
