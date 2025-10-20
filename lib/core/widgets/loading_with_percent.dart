import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingWithPercent extends StatefulWidget {
  const LoadingWithPercent({Key? key}) : super(key: key);

  @override
  State<LoadingWithPercent> createState() => _LoadingWithPercentState();
}

class _LoadingWithPercentState extends State<LoadingWithPercent> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (progress < 100) {
        setState(() {
          progress += 2; // naik 2% setiap 100ms
        });
        _simulateLoading();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
