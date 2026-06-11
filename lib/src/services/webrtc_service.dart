import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
import '../core/constants.dart';

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService();
});

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isConnected = false;
  Function(String)? _onDataChannelMessage;
  Function(MediaStream)? _onRemoteStream;

  bool get isConnected => _isConnected;
  MediaStream? get remoteStream => _remoteStream;

  Future<void> initialize() async {
    final config = {
      'iceServers': [
        {'urls': AppConstants.stunServer},
      ],
    };
    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      _sendSignalingMessage({
        'type': 'candidate',
        'candidate': candidate.toMap(),
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteStream = event.streams[0];
        _onRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      channel.onMessage = (message) {
        _onDataChannelMessage?.call(message);
      };
    };
  }

  Future<MediaStream?> startLocalStream() async {
    final constraints = {
      'video': {
        'facingMode': 'environment',
        'width': 640,
        'height': 480,
      },
      'audio': true,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
    return _localStream;
  }

  Future<void> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignalingMessage({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offer) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], 'offer'),
    );
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    _sendSignalingMessage({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  Future<void> handleAnswer(Map<String, dynamic> answer) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], 'answer'),
    );
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidate) async {
    if (candidate['candidate'] != null) {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidate['candidate']['candidate'],
          candidate['candidate']['sdpMid'],
          candidate['candidate']['sdpMLineIndex'],
        ),
      );
    }
  }

  void _sendSignalingMessage(Map<String, dynamic> message) {
    // Signaling is handled through Supabase Realtime channel
    // The provider will subscribe to this
    _onDataChannelMessage?.call(jsonEncode(message));
  }

  void onDataChannelMessage(Function(String) callback) {
    _onDataChannelMessage = callback;
  }

  void onRemoteStream(Function(MediaStream) callback) {
    _onRemoteStream = callback;
  }

  void sendMessage(String message) {
    // Send alert via data channel
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }

  void dispose() {
    disconnect();
  }
}
