import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../core/constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  Future<String> saveVideoLocally(String data) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/clip_$timestamp.mp4';
    final file = File(path);
    await file.writeAsBytes(base64Decode(data));
    return path;
  }

  Future<void> deleteOldClips() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    final cutoff = DateTime.now().subtract(
      const Duration(days: AppConstants.videoClipRetentionDays),
    );

    for (final file in files) {
      if (file is File) {
        final stat = file.statSync();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
        }
      }
    }
  }

  Future<String?> uploadToCloud(String localPath, String userId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return null;

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await Supabase.instance.client.storage
          .from('videos')
          .upload(fileName, localPath);
      return Supabase.instance.client.storage.from('videos').getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  Future<void> cleanupExpiredCloudFiles() async {
    try {
      const thirtyDaysAgo = Duration(days: AppConstants.cloudRetentionDays);
      final cutoff = DateTime.now().subtract(thirtyDaysAgo);

      final buckets = ['videos', 'photos'];
      for (final bucket in buckets) {
        final files = await Supabase.instance.client.storage
            .from(bucket)
            .list();
        for (final file in files) {
          if (file.createdAt != null && file.createdAt!.isBefore(cutoff)) {
            await Supabase.instance.client.storage
                .from(bucket)
                .remove([file.name]);
          }
        }
      }
    } catch (_) {}
  }
}
