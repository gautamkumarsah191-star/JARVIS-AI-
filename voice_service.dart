import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<bool> initialize() async {
    await _tts.setSpeechRate(0.44);
    await _tts.setPitch(0.82);
    await _tts.setVolume(1.0);
    return _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') &&
            _listenCompleter != null && !_listenCompleter!.isCompleted) {
          _listenCompleter!.complete(_latestWords);
        }
      },
      onError: (error) {
        if (_listenCompleter != null && !_listenCompleter!.isCompleted) {
          _listenCompleter!.completeError(
            Exception(error.errorMsg),
          );
        }
      },
    );
  }

  Completer<String?>? _listenCompleter;
  String? _latestWords;

  Future<String?> listen({String localeId = 'en_IN'}) async {
    if (!await _speech.isAvailable) {
      throw Exception('Speech recognition is unavailable on this device.');
    }
    if (_speech.isListening) await _speech.stop();

    _latestWords = null;
    _listenCompleter = Completer<String?>();
    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        _latestWords = result.recognizedWords;
        if (result.finalResult &&
            _listenCompleter != null && !_listenCompleter!.isCompleted) {
          _listenCompleter!.complete(_latestWords);
        }
      },
    );

    try {
      return await _listenCompleter!.future.timeout(
        const Duration(seconds: 28),
        onTimeout: () => _latestWords,
      );
    } finally {
      await _speech.stop();
      _listenCompleter = null;
    }
  }

  Future<void> speak(String text, {bool hindi = false}) async {
    await _tts.setLanguage(hindi ? 'hi-IN' : 'en-IN');
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
  Future<void> stopListening() => _speech.stop();
}
