import 'package:flutter/material.dart';
import 'live_detection_page.dart';
import 'danger_alert_page.dart';
import 'face_recognition_page.dart';
import 'document_ocr_page.dart';
import 'analytics_history_page.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    LiveDetectionPage(),
    DangerAlertPage(),
    FaceRecognitionPage(),
    DocumentOcrPage(),
    AnalyticsHistoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xFF161B22),
            indicatorColor: const Color(0xFF00FFC2).withOpacity(0.2),
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(color: Color(0xFF00FFC2), fontSize: 11, fontWeight: FontWeight.bold);
              }
              return const TextStyle(color: Colors.white54, fontSize: 11);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(color: Color(0xFF00FFC2));
              }
              return const IconThemeData(color: Colors.white54);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.remove_red_eye_outlined),
                selectedIcon: Icon(Icons.remove_red_eye),
                label: 'Detection',
              ),
              NavigationDestination(
                icon: Icon(Icons.warning_amber_rounded),
                selectedIcon: Icon(Icons.warning),
                label: 'Hazards',
              ),
              NavigationDestination(
                icon: Icon(Icons.face_outlined),
                selectedIcon: Icon(Icons.face),
                label: 'Face ID',
              ),
              NavigationDestination(
                icon: Icon(Icons.document_scanner_outlined),
                selectedIcon: Icon(Icons.document_scanner),
                label: 'OCR',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
