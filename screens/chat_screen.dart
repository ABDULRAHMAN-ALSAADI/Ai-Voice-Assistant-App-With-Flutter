import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'welcome_screen.dart';

class ChatScreen extends StatefulWidget {
  final String apiKey;
  final String baseUrl;

  const ChatScreen({
    super.key,
    required this.apiKey,
    required this.baseUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  static const platform = MethodChannel('voice_chat');
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _breathingController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breathingAnimation;
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _ttsInitialized = false;
  bool _hasAudioPermission = false;
  bool _isVoiceMode = true; // Start in voice mode like ChatGPT
  String _lastWords = '';
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    _animationController.repeat(reverse: true);
    _breathingController.repeat(reverse: true);
    
    _initializeVoiceFeatures();
  }

  Future<void> _initializeVoiceFeatures() async {
    if (!kIsWeb && Platform.isAndroid) {
      platform.setMethodCallHandler(_handleMethodCall);
      await _checkPermissions();
      await _initializeTts();
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechStart':
        setState(() {
          _isSpeaking = true;
        });
        print('🔊 AI started speaking');
        break;
        
      case 'onSpeechComplete':
        setState(() {
          _isSpeaking = false;
        });
        print('🔊 AI finished speaking');
        break;
        
      case 'onSpeechError':
        setState(() {
          _isSpeaking = false;
        });
        print('🔊 TTS Error: ${call.arguments}');
        break;
        
      case 'onListeningStart':
        setState(() {
          _isListening = true;
          _lastWords = '';
        });
        _pulseController.repeat(reverse: true);
        print('🎤 Started listening');
        break;
        
      case 'onListeningEnd':
        print('🎤 Speech recognition ended, but keeping listening state active');
        break;
        
      case 'onSpeechDetected':
        print('🎤 Speech detected');
        break;
        
      case 'onSoundLevelChange':
        setState(() {
          _soundLevel = call.arguments as double;
        });
        break;
        
      case 'onSpeechResult':
        final result = call.arguments as String;
        print('🎤 Final result received: "$result"');
        setState(() {
          _lastWords = result;
        });
        break;
        
      case 'onPartialSpeechResult':
        final result = call.arguments as String;
        print('🎤 Partial result: "$result"');
        setState(() {
          _lastWords = result;
        });
        break;
        
      case 'onListeningError':
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        print('🎤 Listening error: ${call.arguments}');
        break;
        
      case 'onPermissionResult':
        final granted = call.arguments as bool;
        setState(() {
          _hasAudioPermission = granted;
        });
        if (!granted) {
          _showErrorDialog('Microphone permission is required for voice input.');
        }
        break;
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final result = await platform.invokeMethod('checkPermissions');
      setState(() {
        _hasAudioPermission = result as bool;
      });
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await platform.invokeMethod('requestPermissions');
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _initializeTts() async {
    try {
      final result = await platform.invokeMethod('initializeTts');
      setState(() {
        _ttsInitialized = result as bool;
      });
      print('✅ TTS initialized successfully');
    } catch (e) {
      print('❌ TTS initialization failed: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsInitialized) {
      print('❌ TTS not initialized');
      return;
    }
    
    try {
      await platform.invokeMethod('speak', {'text': text});
      print('🔊 Speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    } catch (e) {
      print('❌ TTS speak error: $e');
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await platform.invokeMethod('stopSpeaking');
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_hasAudioPermission) {
      await _requestPermissions();
      return;
    }
    
    if (_isSpeaking) {
      await _stopSpeaking();
      print('🔊 Interrupted AI speech to listen to user');
    }
    
    try {
      await platform.invokeMethod('startListening');
    } catch (e) {
      print('Error starting listening: $e');
    }
  }

  Future<void> _stopListening() async {
    try {
      await platform.invokeMethod('stopListening');
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
      print('🎤 Manually stopped listening');
      
      if (_lastWords.trim().isNotEmpty) {
        print('🎤 DIRECT VOICE-TO-AI: "$_lastWords"');
        _sendVoiceMessageToAI(_lastWords.trim());
      } else {
        print('🎤 No voice input captured');
      }
    } catch (e) {
      print('Error stopping listening: $e');
    }
  }

  Future<void> _sendVoiceMessageToAI(String voiceText) async {
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    setState(() {
      _messages.add(ChatMessage(text: voiceText, isUser: true));
      _isLoading = true;
      _lastWords = '';
    });

    _scrollToBottom();

    try {
      final response = await _sendToAI(voiceText);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      
      if (_ttsInitialized && !kIsWeb && Platform.isAndroid) {
        await _speak(response);
      }
      
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_isSpeaking) {
      await _stopSpeaking();
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _textController.clear();
      _lastWords = '';
    });

    _scrollToBottom();

    try {
      final response = await _sendToAI(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      
      if (_ttsInitialized && !kIsWeb && Platform.isAndroid) {
        await _speak(response);
      }
      
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<String> _sendToAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse(widget.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiKey}',
        },
        body: jsonEncode({
          'message': message,
          'model': 'command-r-plus',
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'No response received';
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() async {
    if (_isSpeaking) {
      await _stopSpeaking();
    }
    if (_isListening) {
      await _stopListening();
    }
    
    setState(() {
      _messages.clear();
    });
  }

  void _logout() async {
    if (_isSpeaking) {
      await _stopSpeaking();
    }
    if (_isListening) {
      await _stopListening();
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key');
    await prefs.remove('base_url');
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        title: const Text(
          'Voice Feature Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool voiceSupported = !kIsWeb && Platform.isAndroid;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _isVoiceMode ? 'VOICE AI' : 'TEXT AI',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_outlined, color: Colors.white),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined, color: Colors.white),
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white24),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Icon(
                            _isVoiceMode ? Icons.mic_none_outlined : Icons.chat_bubble_outline,
                            color: Colors.white.withOpacity(0.4),
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _isVoiceMode ? 'Start a voice conversation' : 'Start a text conversation',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isVoiceMode 
                              ? 'Tap the microphone to speak with AI'
                              : 'Type your message to chat with AI',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return const ChatBubble(
                          text: 'Thinking...',
                          isUser: false,
                          isLoading: true,
                        );
                      }
                      return ChatBubble(
                        text: _messages[index].text,
                        isUser: _messages[index].isUser,
                        isSpeaking: !_messages[index].isUser && _isSpeaking && index == _messages.length - 1,
                      );
                    },
                  ),
          ),
          
          // Input Area - Voice Mode or Text Mode
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
              ),
            ),
            child: _isVoiceMode ? _buildVoiceInterface() : _buildTextInterface(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInterface() {
    final bool voiceSupported = !kIsWeb && Platform.isAndroid;
    
    return Column(
      children: [
        // Voice Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.only(bottom: 30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            _isSpeaking 
                ? '🔊 AI is speaking... Tap mic to interrupt'
                : _isListening
                    ? '🎤 Listening... Tap again to send'
                    : voiceSupported && _ttsInitialized && _hasAudioPermission
                        ? '🎤 Ready to listen • Tap microphone to start'
                        : '⚠️ Setting up voice features...',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Voice Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Switch to Text Mode Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isVoiceMode = false;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.keyboard_outlined,
                  color: Colors.white60,
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(width: 40),
            
            // Big Voice Button (Like ChatGPT)
            if (voiceSupported)
              AnimatedBuilder(
                animation: _isListening ? _pulseAnimation : _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : _breathingAnimation.value,
                    child: GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isListening 
                              ? const LinearGradient(
                                  colors: [Colors.white, Colors.grey],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : _isSpeaking
                                  ? LinearGradient(
                                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : _hasAudioPermission 
                                      ? LinearGradient(
                                          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                          border: Border.all(
                            color: _isListening 
                                ? Colors.black 
                                : _isSpeaking 
                                    ? Colors.orange
                                    : _hasAudioPermission 
                                        ? Colors.white30
                                        : Colors.red,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.white.withOpacity(0.4)
                                  : _isSpeaking
                                      ? Colors.orange.withOpacity(0.4)
                                      : Colors.white.withOpacity(0.1),
                              blurRadius: _isListening ? 25 : _isSpeaking ? 20 : 15,
                              spreadRadius: _isListening ? 5 : _isSpeaking ? 3 : 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening 
                              ? Icons.mic 
                              : _isSpeaking 
                                  ? Icons.volume_up
                                  : _hasAudioPermission 
                                      ? Icons.mic_none_outlined
                                      : Icons.mic_off,
                          color: _isListening 
                              ? Colors.black 
                              : _isSpeaking 
                                  ? Colors.white
                                  : _hasAudioPermission 
                                      ? Colors.white
                                      : Colors.red,
                          size: 50,
                        ),
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(width: 40),
            
            // Spacer to balance layout
            const SizedBox(width: 50),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Voice Hint
        Text(
          _isListening 
              ? 'Speak now...'
              : _isSpeaking
                  ? 'AI is responding...'
                  : 'Tap to start talking',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInterface() {
    return Column(
      children: [
        // Text Input Row
        Row(
          children: [
            // Switch to Voice Mode Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isVoiceMode = true;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.mic_none_outlined,
                  color: Colors.white60,
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(width: 15),
            
            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: _isSpeaking 
                        ? 'AI is speaking...'
                        : 'Type your message...',
                    hintStyle: TextStyle(
                      color: _isSpeaking ? Colors.orange.withOpacity(0.7) : Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w300,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            const SizedBox(width: 15),
            
            // Send Button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_outlined,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isLoading;
  final bool isSpeaking;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSpeaking ? Colors.orange : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isSpeaking 
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    blurRadius: isSpeaking ? 12 : 8,
                    spreadRadius: isSpeaking ? 2 : 1,
                  ),
                ],
              ),
              child: Icon(
                isSpeaking ? Icons.volume_up : Icons.psychology,
                size: 18,
                color: isSpeaking ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.white 
                    : isSpeaking
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: isUser 
                    ? null 
                    : Border.all(
                        color: isSpeaking ? Colors.orange.withOpacity(0.3) : Colors.white24
                      ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : isSpeaking
                        ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            color: isUser ? Colors.black : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        if (isSpeaking) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_up,
                                size: 12,
                                color: Colors.orange.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Speaking...',
                                style: TextStyle(
                                  color: Colors.orange.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}