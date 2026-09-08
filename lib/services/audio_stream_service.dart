import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'socket_service.dart';

/// Diffuse le micro de la victime au repondant assigne pendant une
/// intervention acceptee : capture du PCM brut via [record], regroupe en
/// blocs d'environ 1s emballes en WAV (jouable directement par un <audio>
/// cote web, sans decodage manuel), envoyes au fil de l'eau via Socket.IO.
///
/// L'autorisation est verifiee cote serveur a l'ouverture du flux (voir
/// `alert:audio-start` dans le backend) : seule la victime elle-meme peut
/// demarrer, et seul le repondant assigne recoit l'audio.
class AudioStreamService {
  static const int sampleRate = 8000;
  static const int numChannels = 1;
  static const Duration chunkInterval = Duration(seconds: 1);

  final SocketService socketService;
  AudioStreamService(this.socketService);

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  Timer? _flushTimer;
  int? _currentAlertId;
  bool _active = false;

  bool get isActive => _active;

  Future<bool> start(int alertId) async {
    if (_active) return true;

    final socket = socketService.socket;
    if (socket == null) return false;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;

    final authorized = await _requestServerAuthorization(alertId);
    if (!authorized) return false;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    _currentAlertId = alertId;
    _active = true;
    _sub = stream.listen((chunk) => _pcmBuffer.add(chunk));
    _flushTimer = Timer.periodic(chunkInterval, (_) => _flush());
    return true;
  }

  Future<bool> _requestServerAuthorization(int alertId) {
    final completer = Completer<bool>();
    socketService.socket!.emitWithAck(
      'alert:audio-start',
      alertId,
      ack: (dynamic response) {
        final ok = response is Map && response['ok'] == true;
        if (!completer.isCompleted) completer.complete(ok);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );
  }

  void _flush() {
    if (!_active || _currentAlertId == null) return;
    final pcm = _pcmBuffer.takeBytes();
    if (pcm.isEmpty) return;

    final wav = _wrapPcmAsWav(pcm);
    socketService.emit('alert:audio-chunk', {
      'alertId': _currentAlertId,
      'data': base64Encode(wav),
      'mimeType': 'audio/wav',
    });
  }

  Future<void> stop() async {
    if (!_active) return;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Deja arrete (ex: permission revoquee en cours de route) : sans impact.
    }
    _flush();

    final alertId = _currentAlertId;
    _active = false;
    _currentAlertId = null;
    if (alertId != null) {
      socketService.emit('alert:audio-stop', alertId);
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _sub?.cancel();
    _recorder.dispose();
  }

  Uint8List _wrapPcmAsWav(Uint8List pcm) {
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final header = BytesBuilder();

    void writeString(String s) => header.add(s.codeUnits);
    void writeUint32(int v) => header.add([
      v & 0xff,
      (v >> 8) & 0xff,
      (v >> 16) & 0xff,
      (v >> 24) & 0xff,
    ]);
    void writeUint16(int v) => header.add([v & 0xff, (v >> 8) & 0xff]);

    writeString('RIFF');
    writeUint32(36 + pcm.length);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1); // PCM lineaire
    writeUint16(numChannels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(blockAlign);
    writeUint16(bitsPerSample);
    writeString('data');
    writeUint32(pcm.length);

    final result = BytesBuilder();
    result.add(header.takeBytes());
    result.add(pcm);
    return result.takeBytes();
  }
}
