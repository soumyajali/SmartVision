import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/detection_controller.dart';
import '../core/constants/app_colors.dart';
import '../services/on_device_ai_service.dart';

class MainLayoutShell extends StatelessWidget {
  final Widget child;

  const MainLayoutShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final isCamera = location == '/camera_detection';

    // If on camera screen on mobile, let the camera screen have full immersive view
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return _buildMobileLayout(context, location, isCamera);
        } else {
          return _buildDesktopLayout(context, location);
        }
      },
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, String location, bool isCamera) {
    final isDetecting = context.watch<DetectionController>().isDetecting;

    // Determine bottom nav index
    int selectedIndex = 0;
    if (location == '/home') {
      selectedIndex = 0;
    } else if (location == '/camera_detection') {
      selectedIndex = 1;
    } else if (location == '/document_screening') {
      selectedIndex = 2;
    } else if (location == '/alerts') {
      selectedIndex = 3;
    } else if (location == '/statistics') {
      selectedIndex = 4;
    } else {
      selectedIndex = -1;
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: isCamera
          ? null
          : AppBar(
              backgroundColor: AppColors.secondaryBackground,
              elevation: 0,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppColors.primaryViolet.withValues(alpha: 0.4)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SmartVision AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDetecting
                              ? AppColors.success
                              : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDetecting ? 'SCANNING' : 'STANDBY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDetecting
                              ? AppColors.success
                              : AppColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: AppColors.primaryText),
                    tooltip: 'All Features',
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              ],
            ),
      endDrawer: _buildNavigationDrawer(context, location),
      body: child,
      bottomNavigationBar: isCamera
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.secondaryBackground,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                backgroundColor: AppColors.secondaryBackground,
                elevation: 0,
                height: 65,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (idx) {
                  switch (idx) {
                    case 0:
                      context.go('/home');
                      break;
                    case 1:
                      context.go('/camera_detection');
                      break;
                    case 2:
                      context.go('/document_screening');
                      break;
                    case 3:
                      context.go('/alerts');
                      break;
                    case 4:
                      context.go('/statistics');
                      break;
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.camera_alt_outlined),
                    selectedIcon: Icon(Icons.camera_alt_rounded),
                    label: 'Scan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge_rounded),
                    label: 'ID Screen',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.warning_amber_rounded),
                    selectedIcon: Icon(Icons.warning_rounded),
                    label: 'Alerts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics_rounded),
                    label: 'Analytics',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String location) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Row(
        children: [
          // Desktop / Tablet Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.neonAccent.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.neonAccent.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child:
                              Image.asset('assets/logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SmartVision',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.primaryText,
                              ),
                            ),
                            Text(
                              'AI Vision Suite',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.brightViolet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    children: [
                      _buildNavItem(context, 'Dashboard',
                          Icons.dashboard_outlined, '/home', location),
                      _buildNavItem(
                          context,
                          'Live Detection',
                          Icons.camera_alt_outlined,
                          '/camera_detection',
                          location),
                      _buildNavItem(context, 'Vision Chatbot',
                          Icons.auto_awesome, '/chatbot', location),
                      _buildNavItem(
                          context,
                          'OCR & ID Screening',
                          Icons.badge_outlined,
                          '/document_screening',
                          location),
                      _buildNavItem(context, 'Find Object',
                          Icons.search_rounded, '/find_object', location),
                      _buildNavItem(context, 'Threat Alerts',
                          Icons.warning_amber_rounded, '/alerts', location),
                      _buildNavItem(context, 'Face Biometrics',
                          Icons.face_rounded, '/face_id', location),
                      _buildNavItem(
                          context,
                          'Video Fast Review',
                          Icons.movie_filter_rounded,
                          '/video_review',
                          location),
                      _buildNavItem(context, 'Detection History',
                          Icons.history_rounded, '/history', location),
                      _buildNavItem(context, 'Analytics',
                          Icons.analytics_outlined, '/statistics', location),
                      _buildNavItem(context, 'Settings',
                          Icons.settings_outlined, '/settings', location),
                      _buildNavItem(context, 'About',
                          Icons.info_outline_rounded, '/about', location),
                    ],
                  ),
                ),

                // Show whether the bundled inference model is ready.
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Consumer<OnDeviceAiService>(
                    builder: (context, ai, _) {
                      final ready = ai.isModelLoaded;
                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  ready ? AppColors.success : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ready
                                      ? 'On-device model ready'
                                      : ai.isLoading
                                          ? 'Loading on-device model'
                                          : 'On-device model unavailable',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                Text(
                                  ai.modelError ?? ai.modelName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Load on-device model',
                            onPressed: ai.initialize,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.secondaryText,
                              size: 18,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          ),

          // Main Content Area
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context, String currentLocation) {
    return Drawer(
      backgroundColor: AppColors.secondaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.neonAccent.withValues(alpha: 0.4)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SmartVision AI',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryText)),
                        Text('All Modules & Tools',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildNavItem(context, 'Dashboard', Icons.dashboard_outlined,
                      '/home', currentLocation),
                  _buildNavItem(
                      context,
                      'Live Detection',
                      Icons.camera_alt_outlined,
                      '/camera_detection',
                      currentLocation),
                  _buildNavItem(context, 'Vision Chatbot AI',
                      Icons.auto_awesome, '/chatbot', currentLocation),
                  _buildNavItem(
                      context,
                      'OCR & ID Screening',
                      Icons.badge_outlined,
                      '/document_screening',
                      currentLocation),
                  _buildNavItem(context, 'Find Object / Target',
                      Icons.search_rounded, '/find_object', currentLocation),
                  _buildNavItem(context, 'Threat & Hazard Alerts',
                      Icons.warning_amber_rounded, '/alerts', currentLocation),
                  _buildNavItem(context, 'Face ID & Biometrics',
                      Icons.face_rounded, '/face_id', currentLocation),
                  _buildNavItem(
                      context,
                      'Video Fast Review',
                      Icons.movie_filter_rounded,
                      '/video_review',
                      currentLocation),
                  _buildNavItem(context, 'Detection History',
                      Icons.history_rounded, '/history', currentLocation),
                  _buildNavItem(context, 'Analytics & Stats',
                      Icons.analytics_outlined, '/statistics', currentLocation),
                  _buildNavItem(context, 'Settings', Icons.settings_outlined,
                      '/settings', currentLocation),
                  _buildNavItem(context, 'About System',
                      Icons.info_outline_rounded, '/about', currentLocation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon,
      String route, String currentLocation) {
    final bool isActive = currentLocation == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Close drawer if open
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            context.go(route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryViolet.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.primaryViolet.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isActive ? AppColors.neonAccent : AppColors.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.neonAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
