// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StepTrackerPage extends StatefulWidget {
  const StepTrackerPage({super.key});

  @override
  _StepTrackerPageState createState() => _StepTrackerPageState();
}

class _StepTrackerPageState extends State<StepTrackerPage> {
  final HealthFactory _health = HealthFactory();
  int _steps = 0;
  double _distance = 0.0; // Distance in meters
  final int _stepGoal = 10000; // User's step goal
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    bool isAuthorized = await _health.requestAuthorization(
      [HealthDataType.STEPS, HealthDataType.DISTANCE_WALKING_RUNNING],
    );

    if (isAuthorized) {
      List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        yesterday,
        now,
        [HealthDataType.STEPS, HealthDataType.DISTANCE_WALKING_RUNNING],
      );

      int totalSteps = 0;
      double totalDistance = 0.0;

      for (var point in data) {
        if (point.type == HealthDataType.STEPS) {
          totalSteps += point.value as int;
        } else if (point.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
          totalDistance += point.value as double; // Already in meters
        }
      }

      setState(() {
        _steps = totalSteps;
        _distance = totalDistance;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Permission denied to access health data.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_steps / _stepGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text("Step Tracker")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: AlwaysStoppedAnimation(progress),
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey[300],
                              color: Colors.blue,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "${(_steps / _stepGoal * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$_steps / $_stepGoal steps",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Animate(
                    effects: const [ShimmerEffect()],
                    child: const Icon(Icons.directions_run,
                        size: 100, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Distance: ${(_distance / 1000).toStringAsFixed(2)} km",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchHealthData,
                    child: const Text("Refresh"),
                  ),
                ],
              ),
            ),
    );
  }
}
