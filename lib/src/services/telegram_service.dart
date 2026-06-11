import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';
import '../models/alert.dart';

final telegramServiceProvider = Provider<TelegramService>((ref) {
  return TelegramService();
});

class TelegramService {
  String? _botToken;

  void setBotToken(String token) {
    _botToken = token;
  }

  Future<bool> sendAlert({
    required String chatId,
    required Alert alert,
    String? photoBase64,
    String? videoUrl,
    double? latitude,
    double? longitude,
  }) async {
    if (_botToken == null) return false;

    final message = _buildAlertMessage(alert, videoUrl, latitude, longitude);
    final url = Uri.parse('${AppConstants.telegramApiBase}$_botToken/sendMessage');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      if (photoBase64 != null && response.statusCode == 200) {
        await _sendPhoto(chatId, photoBase64);
      }

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _buildAlertMessage(
    Alert alert,
    String? videoUrl,
    double? latitude,
    double? longitude,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<b>⚠️ ${alert.threatType.label} DETECTED</b>');
    buffer.writeln('');
    buffer.writeln('📍 <b>Threat:</b> ${alert.threatType.label}');
    buffer.writeln('📊 <b>Confidence:</b> ${alert.confidenceLabel}');
    buffer.writeln('🕐 <b>Time:</b> ${_formatDateTime(alert.createdAt)}');

    if (videoUrl != null) {
      buffer.writeln('');
      buffer.writeln('🎥 <a href="$videoUrl">View Recording</a>');
    }

    if (latitude != null && longitude != null) {
      final mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
      buffer.writeln('📍 <a href="$mapsUrl">View Location</a>');
    }

    if (alert.threatType == ThreatType.gas) {
      buffer.writeln('');
      buffer.writeln('⚠️ <b>IMMEDIATE ACTIONS:</b>');
      buffer.writeln('1. Turn off cylinder valve');
      buffer.writeln('2. Open windows');
      buffer.writeln('3. DO NOT switch on lights');
      buffer.writeln('4. Evacuate immediately');
    }

    if (alert.threatType == ThreatType.earthquake) {
      buffer.writeln('');
      buffer.writeln('🔴 <b>DUCK, COVER, HOLD!</b>');
      buffer.writeln('You have ~10 seconds before S-wave arrives.');
    }

    if (alert.threatType == ThreatType.flood) {
      buffer.writeln('');
      buffer.writeln('💧 Check pipes, turn off main water valve if needed.');
    }

    return buffer.toString();
  }

  Future<bool> _sendPhoto(String chatId, String base64Photo) async {
    if (_botToken == null) return false;

    final url = Uri.parse('${AppConstants.telegramApiBase}$_botToken/sendPhoto');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'photo': base64Photo,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyToken() async {
    if (_botToken == null) return false;
    final url = Uri.parse('${AppConstants.telegramApiBase}$_botToken/getMe');
    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
