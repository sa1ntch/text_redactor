import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/material_model.dart';
import '../services/spelling_service.dart';
import '../services/storage_service.dart';
import '../services/transcription_service.dart';
import '../widgets/editor_stats.dart';
import '../widgets/section_header.dart';
import '../widgets/spelling_text_controller.dart';
import '../widgets/workspace_page.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.storageService,
    this.materialId,
  });

  final StorageService storageService;
  final String? materialId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _deepgramApiKeyController = TextEditingController(
    text: const String.fromEnvironment(
      'DEEPGRAM_API_KEY',
      defaultValue: '58d99e1d956dace62be412f1002763dcb9547fad',
    ),
  );
  final SpellingTextController _textController = SpellingTextController();
  final SpellingService _spellingService = SpellingService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final List<SpellingIssue> _spellingIssues = [];
  String? _editingId;
  String? _fileName;
  PlatformFile? _audioFile;
  Timer? _spellingDebounce;
  String? _spellingError;
  String? _transcriptionError;
  int _spellingRequestId = 0;
  bool _loading = false;
  bool _checkingSpelling = false;
  bool _transcribing = false;

  @override
  void initState() {
    super.initState();
    _deepgramApiKeyController.addListener(_handleDeepgramApiKeyChanged);
    _textController.addListener(_handleTextChanged);
    _loadMaterial();
  }

  void _handleDeepgramApiKeyChanged() {
    setState(() {});
  }

  void _handleTextChanged() {
    setState(() {});
    _scheduleSpellingCheck();
  }

  void _scheduleSpellingCheck() {
    _spellingDebounce?.cancel();

    if (_textController.text.trim().isEmpty) {
      _setSpellingIssues([]);
      setState(() {
        _checkingSpelling = false;
        _spellingError = null;
      });
      return;
    }

    setState(() {
      _checkingSpelling = true;
      _spellingError = null;
    });

    _spellingDebounce = Timer(
      const Duration(milliseconds: 650),
      _checkSpelling,
    );
  }

  Future<void> _checkSpelling() async {
    final requestId = ++_spellingRequestId;
    final text = _textController.text;

    try {
      final issues = await _spellingService.check(text);
      if (!mounted || requestId != _spellingRequestId) {
        return;
      }

      setState(() {
        _setSpellingIssues(issues);
        _checkingSpelling = false;
        _spellingError = null;
      });
    } catch (error) {
      if (!mounted || requestId != _spellingRequestId) {
        return;
      }

      setState(() {
        _setSpellingIssues([]);
        _checkingSpelling = false;
        _spellingError = 'Не удалось проверить текст через Яндекс Спеллер.';
      });
    }
  }

  void _setSpellingIssues(List<SpellingIssue> issues) {
    _spellingIssues
      ..clear()
      ..addAll(issues);
    _textController.updateIssues(_spellingIssues);
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'flac',
        'mp3',
        'mp4',
        'mpeg',
        'mpga',
        'm4a',
        'ogg',
        'wav',
        'webm',
      ],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    setState(() {
      _audioFile = file;
      _fileName = file.name;
      _transcriptionError = null;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = 'Расшифровка ${_fileName!.split('.').first}';
      }
    });
  }

  Future<void> _transcribeAudio() async {
    final audioFile = _audioFile;
    if (audioFile == null) {
      _showMessage('Сначала выберите аудиофайл.');
      return;
    }

    setState(() {
      _transcribing = true;
      _transcriptionError = null;
    });

    try {
      final transcription = await _transcriptionService.transcribe(
        file: AudioTranscriptionFile(
          name: audioFile.name,
          size: audioFile.size,
          path: audioFile.path,
          bytes: audioFile.bytes,
        ),
        apiKey: _deepgramApiKeyController.text,
      );

      if (!mounted) {
        return;
      }

      final currentText = _textController.text.trim();
      setState(() {
        _textController.text = currentText.isEmpty
            ? transcription
            : '$currentText\n\n$transcription';
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
        _transcribing = false;
      });
      _showMessage('Текст транскрибации добавлен в материал.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _transcriptionError = error.toString();
        _transcribing = false;
      });
      _showMessage('Не удалось транскрибировать аудио.');
    }
  }

  Future<void> _loadMaterial() async {
    final materialId = widget.materialId;
    if (materialId == null) {
      return;
    }

    setState(() => _loading = true);
    final material = await widget.storageService.findMaterial(materialId);
    if (!mounted) {
      return;
    }

    if (material != null) {
      _editingId = material.id;
      _titleController.text = material.title;
      _textController.text = material.text;
      _scheduleSpellingCheck();
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _spellingDebounce?.cancel();
    _spellingService.close();
    _transcriptionService.close();
    _titleController.dispose();
    _deepgramApiKeyController.removeListener(_handleDeepgramApiKeyChanged);
    _deepgramApiKeyController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (title.isEmpty || text.isEmpty) {
      _showMessage('Заполните название и текст материала.');
      return;
    }

    final material = MaterialModel(
      id: _editingId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      text: text,
      updatedAt: DateTime.now(),
    );

    await widget.storageService.saveMaterial(material);
    if (!mounted) {
      return;
    }

    setState(() => _editingId = material.id);
    _showMessage('Материал сохранен.');
  }

  void _clear() {
    setState(() {
      _editingId = null;
      _audioFile = null;
      _fileName = null;
      _titleController.clear();
      _textController.clear();
      _setSpellingIssues([]);
      _spellingError = null;
      _transcriptionError = null;
      _checkingSpelling = false;
      _transcribing = false;
    });
  }

  Future<void> _copy() async {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      _showMessage('Нет текста для копирования.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('Текст скопирован.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: _editingId == null ? 'Новый материал' : 'Редактирование',
            description:
                'Создайте материал вручную или добавьте транскрибацию аудио через Deepgram. Русские ошибки проверяются через Яндекс Спеллер и подсвечиваются красным прямо в тексте.',
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const LinearProgressIndicator()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TranscriptionTool(
                  fileName: _fileName,
                  apiKeyController: _deepgramApiKeyController,
                  transcribing: _transcribing,
                  errorMessage: _transcriptionError,
                  onPickFile: _pickAudioFile,
                  onTranscribe: _transcribeAudio,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название материала',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  minLines: 12,
                  maxLines: 22,
                  spellCheckConfiguration:
                      const SpellCheckConfiguration.disabled(),
                  decoration: const InputDecoration(
                    labelText: 'Текст материала',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 230),
                      child: Icon(Icons.subject),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                EditorStats(text: _textController.text),
                const SizedBox(height: 12),
                _SpellingStatus(
                  issues: _spellingIssues,
                  checking: _checkingSpelling,
                  errorMessage: _spellingError,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Сохранить'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Копировать'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Очистить'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TranscriptionTool extends StatelessWidget {
  const _TranscriptionTool({
    required this.fileName,
    required this.apiKeyController,
    required this.transcribing,
    required this.errorMessage,
    required this.onPickFile,
    required this.onTranscribe,
  });

  final String? fileName;
  final TextEditingController apiKeyController;
  final bool transcribing;
  final String? errorMessage;
  final VoidCallback onPickFile;
  final VoidCallback onTranscribe;

  Future<void> _openDeepgramDocs() async {
    await launchUrl(
      TranscriptionService.attributionUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = this.errorMessage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.graphic_eq_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Транскрибация аудио',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Выберите аудиофайл и получите расшифровку через Deepgram.',
                        style: TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: apiKeyController,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Deepgram API key',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              TranscriptionService.describeApiKey(apiKeyController.text),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Выбрать аудио'),
                ),
                FilledButton.icon(
                  onPressed: transcribing ? null : onTranscribe,
                  icon: transcribing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_outlined),
                  label: Text(
                    transcribing ? 'Транскрибируем...' : 'Транскрибировать',
                  ),
                ),
                Text(
                  fileName == null
                      ? 'Файл не выбран'
                      : 'Выбран файл: $fileName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            InkWell(
              onTap: _openDeepgramDocs,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Color(0xFF245A92),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      TranscriptionService.attributionText,
                      style: const TextStyle(
                        color: Color(0xFF245A92),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpellingStatus extends StatelessWidget {
  const _SpellingStatus({
    required this.issues,
    required this.checking,
    required this.errorMessage,
  });

  final List<SpellingIssue> issues;
  final bool checking;
  final String? errorMessage;

  Future<void> _openYandexSpeller() async {
    await launchUrl(
      SpellingService.attributionUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = this.errorMessage;

    if (checking) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Проверяем русский текст через Яндекс Спеллер...'),
        ],
      );
    }

    if (errorMessage != null) {
      return _SpellerFrame(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Color(0xFFB45309)),
            const SizedBox(width: 10),
            Expanded(child: Text(errorMessage)),
          ],
        ),
      );
    }

    if (issues.isEmpty) {
      return _SpellerFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Проверка русского текста: ошибок не найдено.',
              style: TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _SpellerAttribution(onTap: _openYandexSpeller),
          ],
        ),
      );
    }

    return _SpellerFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Возможные ошибки подсвечены красным:',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final issue in issues)
                Chip(
                  avatar: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  label: Text('${issue.word} -> ${issue.suggestion}'),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _SpellerAttribution(onTap: _openYandexSpeller),
        ],
      ),
    );
  }
}

class _SpellerFrame extends StatelessWidget {
  const _SpellerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _SpellerAttribution extends StatelessWidget {
  const _SpellerAttribution({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 16, color: Color(0xFF245A92)),
            const SizedBox(width: 6),
            Text(
              SpellingService.attributionText,
              style: const TextStyle(
                color: Color(0xFF245A92),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
