import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/home/widget/home_function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class TireConditionCardWidget extends StatelessWidget {
  final HomeState controller = Get.find<HomeState>();

  TireConditionCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isConditionLoading.value) {
        return SizedBox(
          height: 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blueAccent,
                  size: 45,
                ),
                const SizedBox(height: 12),
                Text(
                  "${(controller.conditionLoadingPercent.value * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.hasConditionError.value) {
        return HomeFunction.buildInlineError(
          message: controller.conditionErrorMessage.value,
          onRetry: () => controller.retryFetch(
            type: 'condition',
            idSite: controller.currentSiteId,
          ),
        );
      }

      if (controller.mapRating.isEmpty) {
        // tampilkan pesan kosong
        return const SizedBox(
          height: 140,
          child: Center(
            child: Text(
              'No tire condition data.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      // kalau sudah ada data
      final tireRatings = controller.mapRating;
      int maxValue = tireRatings.values.isNotEmpty
          ? tireRatings.values.reduce((a, b) => a > b ? a : b)
          : 0;

      Color getBarColor(String rating) {
        switch (rating) {
          case 'A':
            return Colors.greenAccent.shade400;
          case 'B':
            return Colors.blueAccent.shade400;
          case 'C':
            return Colors.orangeAccent.shade400;
          case 'X':
            return Colors.redAccent.shade400;
          default:
            return Colors.grey.shade400;
        }
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double availableBarWidth = constraints.maxWidth - 20 - 8 - 8 - 30;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 🔹 biar menyesuaikan isi
              children: [
                Text(
                  "Tire Running Condition",
                  style: getWhiteTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...tireRatings.entries.map((entry) {
                  double barWidth = maxValue > 0
                      ? (entry.value / maxValue) * availableBarWidth
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            entry.key,
                            style: getWhiteTextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Container(
                                height: 8,
                                width: barWidth,
                                decoration: BoxDecoration(
                                  color: getBarColor(entry.key),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 28,
                          child: Text(
                            entry.value.toString(),
                            textAlign: TextAlign.right,
                            style: getWhiteTextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 75,
                    height: 26,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Detail",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}
