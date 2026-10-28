import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_service.dart';

class AiTeacherScreen extends StatefulWidget {
  const AiTeacherScreen({super.key});

  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class _AiTeacherScreenState extends State<AiTeacherScreen> {
  PlatformFile? _attachedFile;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AiService? _aiService;
  bool _isLoading = false;
  
  final List<Message> _messages = [
    Message(
      text: 'Hello! I am your AI Teacher. What topic would you like to learn today?',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    try {
      _aiService = AiService();
    } catch (e) {
      _messages.add(Message(text: 'AI Service Notice: ${AiService.formatErrorMessage(e)}', isUser: false));
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedFile == null) return;
    if (_isLoading) return;

    PlatformFile? fileToSend = _attachedFile;

    setState(() {
      if (text.isNotEmpty) {
        _messages.add(Message(text: text, isUser: true));
      } else {
        _messages.add(Message(text: "Sent an image: ${fileToSend!.name}", isUser: true));
      }
      _attachedFile = null;
      _textController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    if (_aiService == null) {
      try {
        _aiService = AiService();
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add(Message(
              text: AiService.formatErrorMessage(e),
              isUser: false,
            ));
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return;
      }
    }

    try {
      Uint8List? imageBytes;
      String? mimeType;
      
      if (fileToSend != null && fileToSend.path != null) {
        imageBytes = await File(fileToSend.path!).readAsBytes();
        final ext = fileToSend.extension?.toLowerCase();
        mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';
      }

      final responseStream = _aiService!.sendMessageStream(
        text.isNotEmpty ? text : 'Please analyze the attached image.',
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
      
      if (mounted) {
        setState(() {
          _messages.add(Message(text: '...', isUser: false));
        });
        _scrollToBottom();
      }

      bool isFirstChunk = true;
      await for (final chunk in responseStream) {
        if (mounted) {
          setState(() {
            final lastIndex = _messages.length - 1;
            if (isFirstChunk) {
               _messages[lastIndex] = Message(
                text: chunk,
                isUser: false,
              );
              isFirstChunk = false;
            } else {
              _messages[lastIndex] = Message(
                text: _messages[lastIndex].text + chunk,
                isUser: false,
              );
            }
          });
          _scrollToBottom();
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorMsg = AiService.formatErrorMessage(e);
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0 && (_messages[lastIndex].text.isEmpty || _messages[lastIndex].text == '...')) {
            _messages[lastIndex] = Message(
              text: errorMsg,
              isUser: false,
            );
          } else {
             _messages.add(Message(
              text: errorMsg,
              isUser: false,
            ));
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessage(Message message, ColorScheme colorScheme) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 48), // Padding on left
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white, fontSize: 16),
                    h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: Colors.grey[800], fontSize: 16),
                    h1: TextStyle(color: Colors.grey[900], fontSize: 24, fontWeight: FontWeight.bold),
                    h2: TextStyle(color: Colors.grey[900], fontSize: 20, fontWeight: FontWeight.bold),
                    h3: TextStyle(color: Colors.grey[900], fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48), // Padding on right
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Teacher'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  _messages.clear();
                  _messages.add(
                    Message(
                      text: 'Hello! I am your AI Teacher. What topic would you like to learn today?',
                      isUser: false,
                    ),
                  );
                  _aiService?.clearHistory();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], colorScheme);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Thinking...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_attachedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, left: 48.0, right: 48.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.fileText, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachedFile!.name,
                                style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _attachedFile = null),
                              child: Icon(LucideIcons.x, size: 18, color: colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.paperclip, color: Colors.grey[600]),
                        onPressed: () async {
                          try {
                            FilePickerResult? result = await FilePicker.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null && context.mounted) {
                              setState(() {
                                _attachedFile = result.files.single;
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to pick file.')),
                              );
                            }
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Type your question...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.send, color: Colors.white),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
