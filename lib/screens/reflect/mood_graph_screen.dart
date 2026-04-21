import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodGraphScreen extends StatefulWidget {
  const MoodGraphScreen({super.key});

  @override
  State<MoodGraphScreen> createState() => _MoodGraphScreenState();
}

class _MoodGraphScreenState extends State<MoodGraphScreen> {

  // ✅ Fetch from daily_logs (where mood_slider saves data)
  Future<List<Map<String, dynamic>>> getData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_logs')   // ✅ correct collection
        .orderBy('moodSavedAt', descending: true)
        .limit(7)
        .get();

    return snap.docs.reversed.map((d) {
      final data = d.data();
      return {
        // ✅ Fixed: safely parse as num, default to 0
        "mood": (data['moodIndex'] is num)
            ? (data['moodIndex'] as num).toDouble()
            : double.tryParse(data['moodIndex']?.toString() ?? '0') ?? 0.0,
        "sleep": (data['sleepIndex'] is num)
            ? (data['sleepIndex'] as num).toDouble()
            : double.tryParse(data['sleepIndex']?.toString() ?? '0') ?? 0.0,
        "date": data['date'] ?? d.id,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Mood Graph")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getData(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text(
                "No mood data yet!\nSet your mood on the home screen.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ✅ MOOD GRAPH
                const Text(
                  "😊 Mood This Week",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 4,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.green.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              const labels = [
                                'VLow', 'Low', 'Okay', 'Good', 'Great'
                              ];
                              final i = value.toInt();
                              if (i >= 0 && i < labels.length) {
                                return Text(
                                  labels[i],
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < data.length) {
                                final date =
                                    data[i]['date']?.toString() ?? '';
                                final parts = date.split('-');
                                final label = parts.length >= 3
                                    ? '${parts[2]}/${parts[1]}'
                                    : 'Day ${i + 1}';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (i) {
                            return FlSpot(
                              i.toDouble(),
                              (data[i]["mood"] as double)
                                  .clamp(0.0, 4.0),
                            );
                          }),
                          isCurved: true,
                          barWidth: 4,
                          color: Colors.green,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.green,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ SLEEP GRAPH (separate)
                const Text(
                  "😴 Sleep This Week",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 4,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.purple.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 55,
                            getTitlesWidget: (value, meta) {
                              const labels = [
                                'Terrible',
                                'Poor',
                                'Fair',
                                'Good',
                                'Amazing'
                              ];
                              final i = value.toInt();
                              if (i >= 0 && i < labels.length) {
                                return Text(
                                  labels[i],
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < data.length) {
                                final date =
                                    data[i]['date']?.toString() ?? '';
                                final parts = date.split('-');
                                final label = parts.length >= 3
                                    ? '${parts[2]}/${parts[1]}'
                                    : 'Day ${i + 1}';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (i) {
                            return FlSpot(
                              i.toDouble(),
                              (data[i]["sleep"] as double)
                                  .clamp(0.0, 4.0),
                            );
                          }),
                          isCurved: true,
                          barWidth: 4,
                          color: Colors.purple,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.purple,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purple.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ Analysis
                _analysis(data),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _analysis(List<Map<String, dynamic>> data) {
    // ✅ Fixed: safe cast
    double avgMood = data
        .map((e) => (e["mood"] as double))
        .reduce((a, b) => a + b) /
        data.length;

    double avgSleep = data
        .map((e) => (e["sleep"] as double))
        .reduce((a, b) => a + b) /
        data.length;

    String moodText;
    Color moodColor;
    if (avgMood >= 3) {
      moodText = "🔥 Great Mood Week!";
      moodColor = Colors.green;
    } else if (avgMood >= 2) {
      moodText = "🙂 Stable Mood Week";
      moodColor = Colors.orange;
    } else {
      moodText = "⚠️ Low Mood Week";
      moodColor = Colors.red;
    }

    String sleepText;
    Color sleepColor;
    if (avgSleep >= 3) {
      sleepText = "😴 Great Sleep Week!";
      sleepColor = Colors.purple;
    } else if (avgSleep >= 2) {
      sleepText = "😐 Average Sleep Week";
      sleepColor = Colors.orange;
    } else {
      sleepText = "⚠️ Poor Sleep Week";
      sleepColor = Colors.red;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: moodColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: moodColor),
          ),
          child: Text(
            moodText,
            style: TextStyle(
              color: moodColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sleepColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sleepColor),
          ),
          child: Text(
            sleepText,
            style: TextStyle(
              color: sleepColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}