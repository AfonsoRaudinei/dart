import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MapMetrics {
  static const String _kKeySnapshot = 'metrics_snapshot';
  static const String _kKeyLatencyWindow = 'metrics_latency_window';
  static const String _kKeyRetryWindow = 'metrics_retry_window';
  static const int _kWindowSize = 100;

  // Sync Counters
  static int _syncAttempts = 0;
  static int _syncSuccesses = 0;
  static int _syncFailures = 0;

  // Retry Stats (Last 100 events)
  static final List<int> _retryCounts = [];

  // Latency Stats (Last 100 events)
  static final List<int> _latenciesMs = [];

  static bool _initialized = false;

  /// Loads persisted metrics from disk (called on app start)
  static Future<void> loadMetrics() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Snapshot
      final snapshotJson = prefs.getString(_kKeySnapshot);
      if (snapshotJson != null) {
        final data = jsonDecode(snapshotJson);
        _syncAttempts = data['attempts'] ?? 0;
        _syncSuccesses = data['successes'] ?? 0;
        _syncFailures = data['failures'] ?? 0;
      }

      // Load Windows
      final latencyList = prefs.getStringList(_kKeyLatencyWindow);
      if (latencyList != null) {
        _latenciesMs.clear();
        _latenciesMs.addAll(latencyList.map((e) => int.tryParse(e) ?? 0));
      }

      final retryList = prefs.getStringList(_kKeyRetryWindow);
      if (retryList != null) {
        _retryCounts.clear();
        _retryCounts.addAll(retryList.map((e) => int.tryParse(e) ?? 0));
      }

      _initialized = true;
      if (kDebugMode || kProfileMode) {
        developer.log('Metrics loaded from disk.', name: 'MapObservability');
      }
    } catch (e) {
      if (kDebugMode || kProfileMode) {
        developer.log('Failed to load metrics: $e', name: 'MapObservability');
      }
    }
  }

  /// Persists current aggregated metrics to disk (called on cycle end)
  static Future<void> persistMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Snapshot
      final snapshot = {
        'attempts': _syncAttempts,
        'successes': _syncSuccesses,
        'failures': _syncFailures,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_kKeySnapshot, jsonEncode(snapshot));

      // Rolling Windows
      final latencyToSave = _latenciesMs
          .take(_kWindowSize)
          .map((e) => e.toString())
          .toList();
      await prefs.setStringList(_kKeyLatencyWindow, latencyToSave);

      final retryToSave = _retryCounts
          .take(_kWindowSize)
          .map((e) => e.toString())
          .toList();
      await prefs.setStringList(_kKeyRetryWindow, retryToSave);

      if (kDebugMode || kProfileMode) {
        developer.log('Metrics persisted to disk.', name: 'MapObservability');
      }
    } catch (e) {
      if (kDebugMode || kProfileMode) {
        developer.log(
          'Failed to persist metrics: $e',
          name: 'MapObservability',
        );
      }
    }
  }

  /// Records the start of a sync operation (or item attempt)
  static void recordSyncAttempt() {
    _syncAttempts++;
  }

  /// Records the result of a sync operation for a single item
  static void recordSyncResult({
    required bool success,
    required int latencyMs,
  }) {
    if (success) {
      _syncSuccesses++;
    } else {
      _syncFailures++;
    }

    _latenciesMs.add(latencyMs);
    if (_latenciesMs.length > _kWindowSize) {
      _latenciesMs.removeAt(0);
    }
  }

  /// Records a retry event (the count being attempted)
  static void recordRetry(int retryCount) {
    // Only record actual retries
    if (retryCount > 0) {
      _retryCounts.add(retryCount);
      if (_retryCounts.length > _kWindowSize) {
        _retryCounts.removeAt(0);
      }
    }
  }

  /// Aggregates and logs metrics to the console (Debug/Profile only)
  static void logMetrics() {
    if (!kDebugMode && !kProfileMode) return;

    final totalOps = _syncSuccesses + _syncFailures;
    final successRate = totalOps > 0
        ? ((_syncSuccesses / totalOps) * 100).toStringAsFixed(1)
        : '0.0';

    // Calculate Latency P95 & Avg
    double avgLatency = 0;
    int p95Latency = 0;

    if (_latenciesMs.isNotEmpty) {
      final sum = _latenciesMs.fold(
        0,
        (previous, current) => previous + current,
      );
      avgLatency = sum / _latenciesMs.length;

      final sortedLatencies = List<int>.from(_latenciesMs)..sort();
      // index for P95: ceil(0.95 * N) - 1 (0-based)
      // Example: 100 items -> 95th item (index 94)
      final index = (0.95 * sortedLatencies.length).ceil() - 1;
      p95Latency = sortedLatencies[index.clamp(0, sortedLatencies.length - 1)];
    }

    // Calculate Retry P95
    int p95Retry = 0;
    if (_retryCounts.isNotEmpty) {
      final sortedRetries = List<int>.from(_retryCounts)..sort();
      final index = (0.95 * sortedRetries.length).ceil() - 1;
      p95Retry = sortedRetries[index.clamp(0, sortedRetries.length - 1)];
    }

    final buffer = StringBuffer();
    buffer.writeln('--- [Observability] Map Sync Metrics ---');
    buffer.writeln('Total Attempts: $_syncAttempts');
    buffer.writeln(
      'Ops Finalized: $totalOps (OK: $_syncSuccesses | KO: $_syncFailures)',
    );
    buffer.writeln('Success Rate: $successRate%');
    buffer.writeln(
      'Avg Latency: ${avgLatency.toStringAsFixed(1)}ms | P95 Latency: ${p95Latency}ms',
    );
    buffer.writeln(
      'Retries Recorded: ${_retryCounts.length} | Retry Count P95: $p95Retry',
    );
    buffer.writeln('----------------------------------------');

    developer.log(buffer.toString(), name: 'MapObservability');
  }
}
