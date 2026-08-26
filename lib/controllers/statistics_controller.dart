import 'package:flutter/foundation.dart';
import '../services/statistics_service.dart';

class StatisticsController extends ChangeNotifier {
  final StatisticsService _statisticsService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _totalDetections = 0;
  int _uniqueObjects = 0;
  String _mostDetected = 'None';
  int _todayDetections = 0;

  Map<String, int> _frequency = {};
  Map<String, int> _timeBased = {};
  Map<String, int> _weeklyTrend = {};

  int get totalDetections => _totalDetections;
  int get uniqueObjects => _uniqueObjects;
  String get mostDetected => _mostDetected;
  int get todayDetections => _todayDetections;

  Map<String, int> get frequency => _frequency;
  Map<String, int> get timeBased => _timeBased;
  Map<String, int> get weeklyTrend => _weeklyTrend;

  StatisticsController(this._statisticsService) {
    refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _totalDetections = await _statisticsService.getTotalDetections();
      _uniqueObjects = await _statisticsService.getUniqueObjectCount();
      _mostDetected = await _statisticsService.getMostDetectedObject();
      _todayDetections = await _statisticsService.getTodayDetectionCount();

      _frequency = await _statisticsService.getObjectDetectionFrequency();
      _timeBased = await _statisticsService.getTimeBasedStatistics();
      _weeklyTrend = await _statisticsService.getWeeklyDetectionTrend();
    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
