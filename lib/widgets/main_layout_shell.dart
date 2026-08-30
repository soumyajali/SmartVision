import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart'; 

class MainLayoutShell extends StatelessWidget {
  final Widget child;

  const MainLayoutShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current location to highlight the active tab
    final String location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white, // White sidebar
              border: Border(
                right: BorderSide(
                  color: AppColors.border, // Subtle border
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, color: AppColors.primary, size: 32),
                      const SizedBox(width: 12),
                      const Text(
                        'SmartVision',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      _buildNavItem(context, 'Dashboard', Icons.dashboard_outlined, '/home', location),
                      _buildNavItem(context, 'Live Detection', Icons.camera_alt_outlined, '/camera_detection', location),
                      _buildNavItem(context, 'ID Screening', Icons.badge_outlined, '/document_screening', location),
                      _buildNavItem(context, 'Detections', Icons.search, '/find_object', location),
                      _buildNavItem(context, 'Alerts', Icons.notifications_none, '/alerts', location),
                      _buildNavItem(context, 'History', Icons.history, '/history', location),
                      _buildNavItem(context, 'Analytics', Icons.analytics_outlined, '/statistics', location),
                      _buildNavItem(context, 'Settings', Icons.settings_outlined, '/settings', location),
                      _buildNavItem(context, 'About', Icons.info_outline, '/about', location),
                    ],
                  ),
                ),
                
                // Bottom Area (Health/Status)
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('System Secure', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain)),
                          Text('All services online', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String route, String currentLocation) {
    final bool isActive = currentLocation == route;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          context.go(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
