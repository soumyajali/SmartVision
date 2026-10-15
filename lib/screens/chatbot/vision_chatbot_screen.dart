import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/detection_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../services/speech_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class VisionChatbotScreen extends StatefulWidget {
  const VisionChatbotScreen({super.key});

  @override
  State<VisionChatbotScreen> createState() => _VisionChatbotScreenState();
}

class _VisionChatbotScreenState extends State<VisionChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "SmartVision's on-device scene assistant can answer questions about the latest local detection results. Start detection or analyze an image first.",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
    ),
  ];

  final List<String> _quickPrompts = [
    "What do you see in the scene?",
    "Are any configured hazards detected?",
    "How many objects are detected?",
    "How many people are detected?",
    "What objects are visible?",
    "Can you estimate object distances?",
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _handleSendMessage([String? prefilledText]) async {
    final query = (prefilledText ?? _textController.text).trim();
    if (query.isEmpty || _isTyping) return;

    if (prefilledText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    final detectionCtrl = context.read<DetectionController>();
    final results = detectionCtrl.currentResults;
    final counts = <String, int>{};
    for (final r in results) {
      counts[r.label] = (counts[r.label] ?? 0) + 1;
    }
    final response = _answerFromLocalScene(
      query,
      counts,
      results.where((item) => item.isHazard).map((item) => item.label).toSet(),
      detectionCtrl.isDetecting,
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  String _answerFromLocalScene(
    String query,
    Map<String, int> counts,
    Set<String> hazards,
    bool isDetecting,
  ) {
    final normalized = query.toLowerCase();
    if (normalized.contains('distance') || normalized.contains('far')) {
      return 'Object distance cannot be measured reliably from this single '
          'camera image. This app has no depth sensor or calibrated depth model.';
    }
    if (normalized.contains('hazard') || normalized.contains('danger')) {
      if (hazards.isEmpty) {
        return isDetecting
            ? 'No configured hazard classes were detected in the latest frame.'
            : 'No recent detection result is available. Run object detection first.';
      }
      return 'Configured hazard classes detected in the latest result: '
          '${hazards.join(', ')}.';
    }
    if (normalized.contains('how many') || normalized.contains('count')) {
      final requestedLabel = counts.keys
          .where((label) => normalized.contains(label.toLowerCase()))
          .firstOrNull;
      if (requestedLabel != null) {
        final count = counts[requestedLabel]!;
        return '$count $requestedLabel${count == 1 ? '' : 's'} detected in '
            'the latest result.';
      }
      final total = counts.values.fold<int>(0, (sum, count) => sum + count);
      return isDetecting || counts.isNotEmpty
          ? '$total object(s) across ${counts.length} class(es) in the latest result.'
          : 'No recent detection result is available. Run object detection first.';
    }
    if (counts.isEmpty) {
      return isDetecting
          ? 'No objects were detected in the latest frame.'
          : 'No recent detection result is available. Run object detection first.';
    }
    final summary = counts.entries
        .map((entry) =>
            '${entry.value} ${entry.key}${entry.value == 1 ? '' : 's'}')
        .join(', ');
    return 'Latest on-device detection: $summary. I can report detected '
        'classes, counts, and configured hazards; I do not have a local '
        'generative language model for open-ended questions.';
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text:
              "Chat history cleared. How can I assist you with your visual environment?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detectionCtrl = context.watch<DetectionController>();
    final activeDetections = detectionCtrl.currentResults;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppColors.neonAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vision Chatbot AI',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Multimodal Scene Understanding',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.mutedText),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Vision Context Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(
                  activeDetections.isNotEmpty
                      ? Icons.visibility
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: activeDetections.isNotEmpty
                      ? AppColors.neonAccent
                      : AppColors.mutedText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeDetections.isNotEmpty
                        ? 'Active Vision Context: ${activeDetections.map((d) => d.label).toSet().join(", ")} (${activeDetections.length} total)'
                        : 'No active objects detected in camera feed (using general AI knowledge)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: activeDetections.isNotEmpty
                          ? AppColors.neonAccent
                          : AppColors.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (detectionCtrl.hasActiveHazard)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1744)),
                    ),
                    child: const Text(
                      'HAZARD DETECTED',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8A80)),
                    ),
                  ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.neonAccent),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'SmartVision AI is analyzing scene...',
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.mutedText),
                  ),
                ],
              ),
            ),

          // Quick Prompt Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  backgroundColor: AppColors.cardBackground,
                  side: const BorderSide(color: AppColors.border),
                  label: Text(prompt,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.secondaryText)),
                  onPressed: () => _handleSendMessage(prompt),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                          color: AppColors.primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about what is seen...',
                        hintStyle: const TextStyle(
                            color: AppColors.mutedText, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.neonAccent),
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryViolet, AppColors.neonAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.black),
                      onPressed: () => _handleSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final speechService = context.read<SpeechService>();
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primaryViolet.withValues(alpha: 0.3)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser
                ? AppColors.primaryViolet.withValues(alpha: 0.6)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  msg.isUser ? Icons.person : Icons.auto_awesome,
                  size: 14,
                  color: msg.isUser
                      ? AppColors.brightViolet
                      : AppColors.neonAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  msg.isUser ? 'You' : 'SmartVision Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: msg.isUser
                        ? AppColors.brightViolet
                        : AppColors.neonAccent,
                  ),
                ),
                const Spacer(),
                Text(timeStr,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.mutedText)),
                if (!msg.isUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => speechService.speak(msg.text),
                    child: const Icon(Icons.volume_up_outlined,
                        size: 16, color: AppColors.mutedText),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              msg.text,
              style: const TextStyle(
                  color: AppColors.primaryText, fontSize: 13.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
