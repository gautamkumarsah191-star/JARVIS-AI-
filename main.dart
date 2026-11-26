import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'models/chat_message.dart';
import 'services/ai_service.dart';
import 'services/voice_service.dart';
import 'widgets/reactor_core.dart';

void main() => runApp(const JarvisApp());

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.assistantName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030B18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF20CFFF),
          secondary: Color(0xFF00A8FF),
          surface: Color(0xFF0A1C31),
        ),
        useMaterial3: true,
      ),
      home: const JarvisHome(),
    );
  }
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _ai = AiService();
  final _voice = VoiceService();
  final List<ChatMessage> _messages = [];
  bool _busy = false;
  bool _voiceReady = false;
  bool _speakReplies = true;
  bool _hindiListening = false;
  String _status = 'SYSTEM INITIALIZING';

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      final ready = await _voice.initialize();
      if (mounted) {
        setState(() {
          _voiceReady = ready;
          _status = ready ? 'SYSTEM ONLINE' : 'VOICE SERVICE UNAVAILABLE';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'VOICE SERVICE UNAVAILABLE');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _voice.stopSpeaking();
    _voice.stopListening();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    _input.clear();

    setState(() {
      _busy = true;
      _status = 'PROCESSING REQUEST';
      _messages.add(ChatMessage(
        text: text,
        role: MessageRole.user,
        createdAt: DateTime.now(),
      ));
    });
    _scrollToLatest();

    try {
      final history = _messages.map((message) => {
        'role': message.role == MessageRole.user ? 'user' : 'assistant',
        'content': message.text,
      }).toList();
      final reply = await _ai.sendMessage(messages: history);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: reply,
          role: MessageRole.assistant,
          createdAt: DateTime.now(),
        ));
        _status = 'SYSTEM ONLINE';
      });
      _scrollToLatest();

      if (_speakReplies) {
        final containsHindi = RegExp(r'[\u0900-\u097F]').hasMatch(reply);
        await _voice.speak(reply, hindi: containsHindi);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Connection issue: $error\nPlease check the backend URL, internet connection, and private backend configuration.',
            role: MessageRole.assistant,
            createdAt: DateTime.now(),
          ));
          _status = 'CONNECTION ERROR';
        });
        _scrollToLatest();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _listen() async {
    if (!_voiceReady) {
      setState(() => _status = 'VOICE NOT AVAILABLE');
      return;
    }
    try {
      setState(() => _status = _hindiListening ? 'सुन रहा हूँ...' : 'LISTENING');
      final recognized = await _voice.listen(
        localeId: _hindiListening ? 'hi_IN' : 'en_IN',
      );
      if (!mounted) return;
      setState(() => _status = 'SYSTEM ONLINE');
      if (recognized != null && recognized.trim().isNotEmpty) {
        await _send(recognized);
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'MICROPHONE ERROR');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF06162A),
        title: const Row(children: [
          Icon(Icons.blur_circular, color: Color(0xFF20DFFF)),
          SizedBox(width: 10),
          Text('J.A.R.V.I.S', style: TextStyle(
            letterSpacing: 3, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            tooltip: _hindiListening ? 'Switch voice input to English' : 'Switch voice input to Hindi',
            onPressed: () => setState(() => _hindiListening = !_hindiListening),
            icon: Text(_hindiListening ? 'हि' : 'EN',
              style: const TextStyle(color: Color(0xFF8CEBFF), fontWeight: FontWeight.bold)),
          ),
          IconButton(
            tooltip: _speakReplies ? 'Mute replies' : 'Speak replies',
            onPressed: () => setState(() => _speakReplies = !_speakReplies),
            icon: Icon(_speakReplies ? Icons.volume_up : Icons.volume_off),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 8),
          Text('HELLO ${AppConfig.ownerName.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF8CEBFF), letterSpacing: 4, fontSize: 12)),
          const SizedBox(height: 5),
          Text(_status, style: const TextStyle(
            color: Color(0xFF4DBBDE), fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 4),
          const ReactorCore(),
          const Text('HOW CAN I HELP YOU?',
            style: TextStyle(color: Colors.white70, letterSpacing: 2)),
          const SizedBox(height: 8),
          Expanded(
            child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Your assistant is ready. Ask a question or tap the microphone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: _messages.length + (_busy ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_busy && index == _messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('JARVIS is thinking...',
                          style: TextStyle(color: Color(0xFF55DFFF))),
                      );
                    }
                    final message = _messages[index];
                    final isUser = message.role == MessageRole.user;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 310),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF073A60) : const Color(0xFF0A1C31),
                          border: Border.all(color: const Color(0xFF147DA8)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              IconButton.filledTonal(
                tooltip: 'Speak to JARVIS',
                onPressed: _busy ? null : _listen,
                icon: const Icon(Icons.mic),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask JARVIS...',
                    filled: true,
                    fillColor: const Color(0xFF0A1B30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF147DA8))),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.arrow_upward),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
