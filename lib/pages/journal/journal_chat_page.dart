import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_sejour/models/journal_message.dart';
import 'package:projet_sejour/services/journal_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

class JournalChatPage extends StatefulWidget {
  final String dateStr;
  const JournalChatPage({super.key, required this.dateStr});

  @override
  State<JournalChatPage> createState() => _JournalChatPageState();
}

class _JournalChatPageState extends State<JournalChatPage> {
  final JournalService _journalService = JournalService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  String? _audioPath;

  bool _isUploading = false;
  String _uploadStatus = '';
  late Stream<List<JournalMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _messagesStream = _journalService.getMessagesForDate(widget.dateStr);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    _textController.clear();
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Sending...';
    });
    try {
      await _journalService.sendTextMessage(text, widget.dateStr);
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send text: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _isUploading = true;
          _uploadStatus = 'Uploading photo...';
        });
        await _journalService.sendMediaMessage(File(image.path), MessageType.image, widget.dateStr);
        _scrollToBottom();
      }
    } catch (e) {
      String errorMessage = e.toString();
      String userFriendlyMessage = 'Failed to upload image. $e';
      
      if (errorMessage.contains('unauthorized')) {
        userFriendlyMessage = 'Permission Denied! Please ensure your Firebase Storage rules allow writes.';
      } else if (errorMessage.contains('retry-limit-exceeded')) {
        userFriendlyMessage = 'Upload timed out. Please check your internet connection.';
      } else if (errorMessage.contains('object-not-found')) {
        userFriendlyMessage = 'Upload failed: storage object not found.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            action: SnackBarAction(label: 'Details', onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Error Details'),
                  content: Text(errorMessage),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                )
              );
            }),
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        _audioPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(),
          path: _audioPath!,
        );
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        // Start a timer for duration feedback
        _startTimer();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required.')));
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRecording) {
        timer.cancel();
      } else {
        setState(() => _recordDuration++);
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
      
      if (path != null) {
        setState(() {
          _isUploading = true;
          _uploadStatus = 'Uploading audio...';
        });
        await _journalService.sendMediaMessage(File(path), MessageType.audio, widget.dateStr);
        _scrollToBottom();
      }
    } catch (e) {
      String errorMessage = e.toString();
      String userFriendlyMessage = 'Failed to upload audio. $e';
      
      if (errorMessage.contains('unauthorized')) {
        userFriendlyMessage = 'Permission Denied! Please ensure your Firebase Storage rules allow writes.';
      } else if (errorMessage.contains('retry-limit-exceeded')) {
        userFriendlyMessage = 'Upload timed out. Please check your internet connection.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            action: SnackBarAction(label: 'Details', onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Error Details'),
                  content: Text(errorMessage),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                )
              );
            }),
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = DateFormat('MMMM d, yyyy').format(DateTime.parse(widget.dateStr));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Journey Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(displayDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<JournalMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text('Oops! Something went wrong.', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Your canvas for $displayDate', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Save thoughts, photos, and voice memos here.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  );
                }

                // Autoscroll after build if mostly at bottom
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                     _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          if (_isUploading)
             Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(_uploadStatus, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(JournalMessage msg) {
    Widget contentWidget;
    switch (msg.type) {
      case MessageType.text:
        contentWidget = Text(msg.content, style: const TextStyle(fontSize: 16));
        break;
      case MessageType.image:
        contentWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: msg.content,
            placeholder: (context, url) => const SizedBox(height: 150, width: 200, child: Center(child: CircularProgressIndicator())),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
            fit: BoxFit.cover,
          ),
        );
        break;
      case MessageType.audio:
        contentWidget = _AudioPlayerBubble(url: msg.content);
        break;
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            contentWidget,
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.locationName != null) ...[
                  const Icon(Icons.location_on_rounded, size: 10, color: Colors.black54),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      msg.locationName!,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  DateFormat('h:mm a').format(msg.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded),
              color: colorScheme.primary,
              onPressed: () {
                _showImageSourceDialog();
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _isRecording 
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.red, size: 10),
                                const SizedBox(width: 8),
                                Text(
                                  "Recording... ${(_recordDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}",
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : TextField(
                            controller: _textController,
                            maxLines: 5,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Log a memory...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, child) {
                        return IconButton(
                          icon: Icon(
                            value.text.trim().isNotEmpty ? Icons.send_rounded : Icons.mic_rounded,
                            color: value.text.trim().isNotEmpty ? colorScheme.primary : (_isRecording ? Colors.redAccent : Colors.grey[600]),
                          ),
                          onPressed: value.text.trim().isNotEmpty ? _sendText : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Standalone record button if text is empty
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, child) {
                if (value.text.trim().isNotEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  onLongPressCancel: () => _stopRecording(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.redAccent : colorScheme.primary,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AudioPlayerBubble extends StatefulWidget {
  final String url;
  const _AudioPlayerBubble({required this.url});

  @override
  State<_AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<_AudioPlayerBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSourceUrl(widget.url);
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.primary),
          onPressed: _togglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Container(
          height: 4,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(_position),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
