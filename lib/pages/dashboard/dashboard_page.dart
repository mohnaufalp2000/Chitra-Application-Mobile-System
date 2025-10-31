import 'package:camos/pages/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dashboard_state.dart';
import 'package:camos/core/styles/text_manager.dart';

class DashboardPage extends StatelessWidget {
  static const routeName = '/dashbord-page';
  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardState controller = Get.put(DashboardState());

    return Scaffold(
      extendBody: true, // 🔹 biar FAB overlap dengan nav bar transparan
      body: Obx(() {
        final pages = controller.pages;
        return pages[controller.currentIndex.value];
      }),

      // 🔹 Tombol tengah (AI Analyzer)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: controller.onScanPressed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(
                  LucideIcons.scanLine,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tire Damage \nAnalyzer (AI)',
              style: getBlackTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ).copyWith(
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation Redesign
      bottomNavigationBar: Obx(
        () => Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BottomAppBar(
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    icon: LucideIcons.home,
                    label: 'Home',
                    index: 0,
                    controller: controller,
                  ),
                  _buildNavItem(
                    icon: LucideIcons.clipboardList,
                    label: 'Inspection',
                    index: 1,
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required DashboardState controller,
  }) {
    final isActive = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changePage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.teal : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.teal : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
