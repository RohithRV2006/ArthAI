import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:arth/ai_chat_provider.dart';
import 'package:arth/rich_ai_models.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _englishMode = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiChatProvider>().refreshForCurrentUser();
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;
    final provider = context.read<AiChatProvider>();

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final locale = provider.language == 'tamil'
        ? (_englishMode ? 'en_IN' : 'ta_IN')
        : 'en_IN';

    setState(() => _isListening = true);
    await _speech.listen(
      localeId: locale,
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _sendMessage(result.recognizedWords);
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(cancelOnError: true),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    final provider = context.read<AiChatProvider>();
    provider.sendMessage(text).then((_) {
      _scrollToBottom();
      final msgs = provider.messages;
      if (msgs.isNotEmpty && !msgs.last.isUser) {
        _tts.speak(msgs.last.text);
      }
    });
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
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiChatProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          drawer: _buildDrawer(provider),
          appBar: AppBar(
            title: const Text('Arth AI'),
            actions: [
              if (provider.language == 'tamil')
                GestureDetector(
                  onTap: () =>
                      setState(() => _englishMode = !_englishMode),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _englishMode
                          ? Colors.orange.shade100
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _englishMode ? 'தமிழ்' : 'English', // ✅ FIXED
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _englishMode
                            ? Colors.orange.shade800
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: provider.toggleLanguage,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                    Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    provider.loc.languageLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (provider.isLoadingHistory)
                LinearProgressIndicator(
                    color: Theme.of(context).colorScheme.primary),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.messages.length +
                      (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length) {
                      return const _TypingIndicator();
                    }
                    final msg = provider.messages[index];
                    return _RichChatBubble(
                      message: msg,
                      savedLabel: provider.loc.savedBadge,
                      onEdit: msg.isUser ? () {
                        final oldText = provider.editMessage(index);
                        _textController.text = oldText;
                      } : null,
                    );
                  },
                ),
              ),

              if (!provider.isLoading)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.quickPrompts.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                    itemBuilder: (context, i) => ActionChip(
                      label: Text(provider.quickPrompts[i],
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () =>
                          _sendMessage(provider.quickPrompts[i]),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              _InputBar(
                controller: _textController,
                isListening: _isListening,
                speechAvailable: _speechAvailable,
                isTamil: provider.language == 'tamil',
                englishMode: _englishMode,
                inputHint: provider.loc.inputHint,
                listeningHint: provider.loc.listeningHint,
                onSend: () => _sendMessage(_textController.text),
                onMicTap: _toggleListening,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(AiChatProvider provider) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    provider.startNewChat();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Chat'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                onChanged: provider.searchChats,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: provider.filteredSessions.isEmpty
                  ? Center(child: Text('No chats found', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                itemCount: provider.filteredSessions.length,
                itemBuilder: (context, index) {
                  final session = provider.filteredSessions[index];
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      provider.switchChat(session.id);
                      Navigator.pop(context);
                      _scrollToBottom();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RichChatBubble extends StatelessWidget {
  final RichChatMessage message;
  final String savedLabel;
  final VoidCallback? onEdit;

  const _RichChatBubble({
    required this.message,
    required this.savedLabel,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isUser && onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  color: Colors.grey.shade500,
                  onPressed: onEdit,
                ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      if (message.richResponse?.isDataSaved == true) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            savedLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser
                              ? colorScheme.onPrimary.withValues(alpha: 0.7)
                              : colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isUser && message.richResponse?.hasRichData == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RichDataCards(response: message.richResponse!),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _RichDataCards extends StatefulWidget {
  final RichAiResponse response;
  const _RichDataCards({required this.response});

  @override
  State<_RichDataCards> createState() => _RichDataCardsState();
}

class _RichDataCardsState extends State<_RichDataCards> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.response;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            margin: const EdgeInsets.only(left: 4, bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Hide details' : 'View financial details',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          if (r.hasProfile)
            _ProfileMiniCard(profile: r.userProfile!),
          if (r.hasFinancialHealth)
            _FinancialHealthCard(health: r.financialHealth!),
          if (r.hasBudgetHealth)
            _BudgetHealthMiniCard(health: r.budgetHealth!),
          if (r.hasGoals) _GoalsMiniCard(goals: r.goals),
          if (r.aiRecommendation.isNotEmpty)
            _RecommendationCard(
                text: r.aiRecommendation,
                items: r.recommendations),
        ],
      ],
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  final FinancialHealthModel health;
  const _FinancialHealthCard({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: health.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: health.statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(health.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Financial Health',
                style: TextStyle(fontWeight: FontWeight.bold, color: health.statusColor, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: health.statusColor, borderRadius: BorderRadius.circular(12)),
                child: Text('${health.score}/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: health.score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(health.statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HealthStat(label: 'Savings rate', value: '${health.savingsRate.toStringAsFixed(1)}%'),
              _HealthStat(label: 'Debt ratio', value: '${health.debtRatio.toStringAsFixed(1)}%'),
              _HealthStat(label: 'Net worth', value: '₹${health.netWorth.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  final String label;
  final String value;
  const _HealthStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _ProfileMiniCard extends StatelessWidget {
  final UserProfileSummary profile;
  const _ProfileMiniCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat2(label: 'Income', value: '₹${profile.income.toStringAsFixed(0)}', color: const Color(0xFF1D9E75)),
          _MiniStat2(label: 'Savings', value: '₹${profile.savings.toStringAsFixed(0)}', color: Colors.blue),
          _MiniStat2(label: 'EMI', value: '₹${profile.emi.toStringAsFixed(0)}', color: Colors.orange),
          _MiniStat2(label: 'Net worth', value: '₹${profile.netWorth.toStringAsFixed(0)}', color: Colors.purple),
        ],
      ),
    );
  }
}

class _MiniStat2 extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat2({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _BudgetHealthMiniCard extends StatelessWidget {
  final BudgetHealthModel health;
  const _BudgetHealthMiniCard({required this.health});

  Color get _color {
    if (health.score >= 80) return const Color(0xFF1D9E75);
    if (health.score >= 60) return Colors.blue;
    if (health.score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: _color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Health: ${health.status}', style: TextStyle(fontWeight: FontWeight.bold, color: _color)),
                if (health.warnings.isNotEmpty)
                  Text(health.warnings.first, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('${health.score}/100', style: TextStyle(fontWeight: FontWeight.bold, color: _color, fontSize: 14)),
        ],
      ),
    );
  }
}

class _GoalsMiniCard extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  const _GoalsMiniCard({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings, color: Colors.purple.shade700, size: 18),
              const SizedBox(width: 8),
              Text('Goals', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
            ],
          ),
          const SizedBox(height: 10),
          ...goals.take(3).map((g) {
            final progress = ((g['progress_percent'] ?? 0) as num).toDouble() / 100;
            final status = g['status']?.toString() ?? '';
            final color = status == 'Completed' ? const Color(0xFF1D9E75) : status == 'At Risk' ? Colors.red : Colors.blue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(g['goal_name']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(status, style: TextStyle(fontSize: 11, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String text;
  final List<String> items;
  const _RecommendationCard({required this.text, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 8),
              Text('AI Recommendations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.amber.shade900, height: 1.5)),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 200),
            SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
    _anim = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool speechAvailable;
  final bool isTamil;
  final bool englishMode;
  final String inputHint;
  final String listeningHint;
  final VoidCallback onSend;
  final VoidCallback onMicTap;

  const _InputBar({
    required this.controller,
    required this.isListening,
    required this.speechAvailable,
    required this.isTamil,
    required this.englishMode,
    required this.inputHint,
    required this.listeningHint,
    required this.onSend,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            if (speechAvailable)
              GestureDetector(
                onTap: onMicTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isListening
                        ? Theme.of(context).colorScheme.errorContainer
                        : englishMode && isTamil
                        ? Colors.orange.shade100
                        : Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isListening ? Icons.stop : Icons.mic,
                    color: isListening
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : englishMode && isTamil
                        ? Colors.orange.shade800
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: isListening ? listeningHint : inputHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}