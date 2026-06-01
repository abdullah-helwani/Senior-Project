import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:first_try/core/api/api_interceptors.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/core/utils/download_file.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:flutter/material.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kBloomLevels = {
  'remember':  'Remember',
  'understand': 'Understand',
  'apply':     'Apply',
  'analyze':   'Analyze',
  'evaluate':  'Evaluate',
  'create':    'Create',
};

const _purple = Color(0xFF6366F1);

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherQuestionGeneratorScreen extends StatefulWidget {
  const TeacherQuestionGeneratorScreen({super.key});

  @override
  State<TeacherQuestionGeneratorScreen> createState() =>
      _TeacherQuestionGeneratorScreenState();
}

class _TeacherQuestionGeneratorScreenState
    extends State<TeacherQuestionGeneratorScreen>
    with SingleTickerProviderStateMixin {
  // ── Tabs ────────────────────────────────────────────────────────────────────
  late final TabController _tabs;

  // ── Shared form values ──────────────────────────────────────────────────────
  int _mcqCount         = 5;
  int _trueFalseCount   = 3;
  int _shortAnswerCount = 2;
  int _fillBlankCount   = 2;
  int _essayCount       = 1;
  String _difficulty    = 'medium';
  String _language      = 'auto';
  String _title         = 'Exam Questions';
  bool _includeAnswers  = true;
  final Set<String> _bloomLevels = {'remember', 'understand', 'apply'};

  int get _totalQuestions =>
      _mcqCount + _trueFalseCount + _shortAnswerCount + _fillBlankCount + _essayCount;

  // ── Curriculum-book tab state ────────────────────────────────────────────────
  bool _booksLoading = false;
  List<Map<String, dynamic>> _allBooks = [];
  String? _selectedGrade;
  String? _selectedBook;       // book id
  String? _selectedSubject;    // display label
  bool _chaptersLoading = false;
  List<Map<String, dynamic>> _chapters = [];
  final Set<int> _selectedChapters = {};

  // Generation result (JSON questions list)
  bool _generating = false;
  List<Map<String, dynamic>>? _generatedQuestions;
  Map<String, dynamic>? _quality;
  bool _exporting = false;

  // ── PDF-upload tab state ─────────────────────────────────────────────────────
  PlatformFile? _pickedFile;
  final _pageStartCtrl = TextEditingController();
  final _pageEndCtrl   = TextEditingController();
  bool _pdfLoading = false;
  double _pdfProgress = 0;
  String _pdfStatus = '';

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadBooks();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pageStartCtrl.dispose();
    _pageEndCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout:    const Duration(minutes: 60),
      receiveTimeout: const Duration(minutes: 60),
    ));
    dio.interceptors.add(ApiInterceptor());
    return dio;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Book / chapter loading ────────────────────────────────────────────────────

  Future<void> _loadBooks() async {
    setState(() => _booksLoading = true);
    try {
      final teacherId = context.currentRoleId;
      final res = await _buildDio().get<Map<String, dynamic>>(
        AppUrl.teacherQgBooks(teacherId),
      );
      final raw = (res.data?['books'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() => _allBooks = raw);
    } catch (_) {
      // Service may not be running yet — fail silently, user sees empty dropdowns
    } finally {
      setState(() => _booksLoading = false);
    }
  }

  List<String> get _grades {
    final seen = <String>{};
    final out  = <String>[];
    for (final b in _allBooks) {
      final g = b['grade']?.toString() ?? '';
      if (g.isNotEmpty && seen.add(g)) out.add(g);
    }
    out.sort();
    return out;
  }

  List<Map<String, dynamic>> get _booksForGrade =>
      _selectedGrade == null
          ? []
          : _allBooks.where((b) => b['grade']?.toString() == _selectedGrade).toList();

  Future<void> _loadChapters(String book) async {
    setState(() {
      _chaptersLoading = true;
      _chapters.clear();
      _selectedChapters.clear();
    });
    try {
      final teacherId = context.currentRoleId;
      final res = await _buildDio().get<Map<String, dynamic>>(
        AppUrl.teacherQgChapters(teacherId, book),
      );
      final raw = (res.data?['chapters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() => _chapters = raw);
    } catch (e) {
      _showSnack('Could not load chapters: $e');
    } finally {
      setState(() => _chaptersLoading = false);
    }
  }

  // ── Curriculum generate ───────────────────────────────────────────────────────

  Future<void> _generateFromBook() async {
    if (_selectedBook == null) {
      _showSnack('Select a book first.');
      return;
    }
    if (_bloomLevels.isEmpty) {
      _showSnack('Select at least one Bloom\'s level.');
      return;
    }

    setState(() {
      _generating        = true;
      _generatedQuestions = null;
      _quality           = null;
    });

    try {
      final teacherId = context.currentRoleId;
      // Only include question types with count > 0 — the Python service uses
      // max(1, count) internally, so a 0 would still produce 1 question.
      final counts = <String, int>{
        if (_mcqCount         > 0) 'mcq':          _mcqCount,
        if (_trueFalseCount   > 0) 'true_false':   _trueFalseCount,
        if (_shortAnswerCount > 0) 'short_answer': _shortAnswerCount,
        if (_fillBlankCount   > 0) 'fill_blank':   _fillBlankCount,
        if (_essayCount       > 0) 'essay':        _essayCount,
      };
      if (counts.isEmpty) {
        _showSnack('Set at least one question count.');
        setState(() => _generating = false);
        return;
      }
      final payload = <String, dynamic>{
        'document_id':     _selectedBook,
        if (_selectedChapters.isNotEmpty) 'chapters': _selectedChapters.toList(),
        'question_counts': counts,
        'bloom_levels': _bloomLevels.toList(),
        'difficulty':   _difficulty,
        'language':     _language,
        'evaluate':     true,
      };

      final res = await _buildDio().post<Map<String, dynamic>>(
        AppUrl.teacherQgGenerate(teacherId),
        data: payload,
      );

      final questions = (res.data?['questions'] as List?)
          ?.cast<Map<String, dynamic>>() ?? [];
      final quality = res.data?['quality'] as Map<String, dynamic>?;

      setState(() {
        _generatedQuestions = questions;
        _quality            = quality;
      });
    } on DioException catch (e) {
      _showSnack(_dioMsg(e, 'Generation failed.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _exportDocx() async {
    if (_generatedQuestions == null || _generatedQuestions!.isEmpty) return;

    setState(() => _exporting = true);
    try {
      final teacherId = context.currentRoleId;
      final payload   = {
        'questions':       _generatedQuestions,
        'title':           _title,
        'document_id':     _selectedBook ?? '',
        'difficulty':      _difficulty,
        'language':        _language,
        'include_answers': _includeAnswers,
      };

      final res = await _buildDio().post<List<int>>(
        AppUrl.teacherQgExport(teacherId),
        data:    payload,
        options: Options(responseType: ResponseType.bytes),
      );

      if (res.statusCode == 200 && res.data != null) {
        final filename = '${_safeTitle()}_${DateTime.now().millisecondsSinceEpoch}.docx';
        await downloadFile(res.data!, filename);
        if (mounted) _showSnack('Download started: $filename');
      } else {
        _showSnack('Export failed (status ${res.statusCode}).');
      }
    } on DioException catch (e) {
      _showSnack(_dioMsg(e, 'Export failed.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      setState(() => _exporting = false);
    }
  }

  // ── PDF-upload generate ───────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _generateFromPdf() async {
    if (_pickedFile == null) return;
    if (_totalQuestions == 0) {
      _showSnack('Set at least one question count.');
      return;
    }

    setState(() {
      _pdfLoading  = true;
      _pdfProgress = 0;
      _pdfStatus   = 'Uploading PDF…';
    });

    try {
      final teacherId = context.currentRoleId;
      final dio       = _buildDio();
      final pageStart = int.tryParse(_pageStartCtrl.text.trim());
      final pageEnd   = int.tryParse(_pageEndCtrl.text.trim());

      final formData = FormData.fromMap({
        'pdf': MultipartFile.fromBytes(_pickedFile!.bytes!, filename: _pickedFile!.name),
        if (pageStart != null) 'page_start': pageStart.toString(),
        if (pageEnd   != null) 'page_end':   pageEnd.toString(),
        'mcq_count':          _mcqCount.toString(),
        'true_false_count':   _trueFalseCount.toString(),
        'short_answer_count': _shortAnswerCount.toString(),
        'fill_blank_count':   _fillBlankCount.toString(),
        'essay_count':        _essayCount.toString(),
        'difficulty':         _difficulty,
        'language':           _language,
        'title':              _title,
        'bloom_levels':       _bloomLevels.join(','),
        'include_answers':    _includeAnswers ? 'true' : 'false',
        'output':             'docx',
      });

      setState(() => _pdfStatus = 'Generating questions (this may take a few minutes)…');

      final res = await dio.post<List<int>>(
        AppUrl.teacherGenerateExam(teacherId),
        data:    formData,
        options: Options(responseType: ResponseType.bytes),
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _pdfProgress = sent / total * 0.1;
              _pdfStatus   = 'Uploading… ${(sent / 1024 / 1024).toStringAsFixed(1)} MB';
            });
          }
        },
        onReceiveProgress: (received, total) {
          setState(() {
            _pdfProgress = 0.1 + (total > 0 ? received / total * 0.9 : 0);
            _pdfStatus   = 'Receiving file…';
          });
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        setState(() => _pdfStatus = 'Saving file…');
        final filename = '${_safeTitle()}_${DateTime.now().millisecondsSinceEpoch}.docx';
        await downloadFile(res.data!, filename);
        if (mounted) _showSnack('Download started: $filename');
      } else {
        _showSnack('Generation failed (status ${res.statusCode}).');
      }
    } on DioException catch (e) {
      _showSnack(_dioMsg(e, 'Generation failed.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      setState(() {
        _pdfLoading  = false;
        _pdfProgress = 0;
        _pdfStatus   = '';
      });
    }
  }

  // ── Utilities ────────────────────────────────────────────────────────────────

  String _safeTitle() =>
      _title.replaceAll(RegExp(r'[^\w\s]'), '').trim().replaceAll(' ', '_').isNotEmpty
          ? _title.replaceAll(RegExp(r'[^\w\s]'), '').trim().replaceAll(' ', '_')
          : 'exam';

  String _dioMsg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is List<int> && data.isNotEmpty) {
      try {
        final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
        return json['message'] ?? json['detail'] ?? fallback;
      } catch (_) {}
    } else if (data is Map) {
      return (data['message'] ?? data['detail'] ?? fallback).toString();
    }
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Request timed out. The model may still be loading — try again in a minute.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check that Laravel and the Python service are running.';
    }
    return 'Request failed (${e.message}).';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Question Generator'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Curriculum Book'),
            Tab(icon: Icon(Icons.upload_file_rounded), text: 'Upload PDF'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCurriculumTab(),
          _buildPdfTab(),
        ],
      ),
    );
  }

  // ── Curriculum tab ────────────────────────────────────────────────────────────

  Widget _buildCurriculumTab() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBanner(
            icon: Icons.menu_book_rounded,
            text: '23+ indexed Syrian curriculum books — no file upload needed.',
            color: _purple,
          ),
          const SizedBox(height: 16),

          // ── 1. Book selection ──────────────────────────────────────────────
          _SectionCard(
            title: '1. Select Book',
            child: _booksLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Grade
                      _DropdownRow(
                        label: 'Grade',
                        value: _selectedGrade,
                        hint: 'Choose grade',
                        items: _grades
                            .map((g) => DropdownMenuItem(value: g, child: Text('Grade $g')))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedGrade    = v;
                          _selectedBook     = null;
                          _selectedSubject  = null;
                          _chapters.clear();
                          _selectedChapters.clear();
                          _generatedQuestions = null;
                        }),
                      ),
                      const SizedBox(height: 10),
                      // Subject
                      _DropdownRow(
                        label: 'Subject',
                        value: _selectedBook,
                        hint: 'Choose subject',
                        items: _booksForGrade
                            .map((b) => DropdownMenuItem(
                                  value: b['book']?.toString(),
                                  child: Text(b['subject']?.toString() ?? b['book']?.toString() ?? ''),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final book = _booksForGrade.firstWhere((b) => b['book'] == v, orElse: () => {});
                          setState(() {
                            _selectedBook    = v;
                            _selectedSubject = book['subject']?.toString();
                            _selectedChapters.clear();
                            _generatedQuestions = null;
                          });
                          _loadChapters(v);
                        },
                      ),
                      if (_allBooks.isEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry loading books'),
                          onPressed: _loadBooks,
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // ── 2. Chapters ────────────────────────────────────────────────────
          if (_selectedBook != null)
            _SectionCard(
              title: '2. Chapters  (leave all unchecked = entire book)',
              child: _chaptersLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator()))
                  : _chapters.isEmpty
                      ? Text('No chapters found for this book.',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
                      : Column(
                          children: _chapters.map((ch) {
                            final idx = ch['index'] as int? ?? 0;
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                ch['title']?.toString() ?? 'Chapter $idx',
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                'pp. ${ch['start_page']}–${ch['end_page']}',
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                              value: _selectedChapters.contains(idx),
                              activeColor: _purple,
                              onChanged: (on) => setState(() {
                                if (on == true) {
                                  _selectedChapters.add(idx);
                                } else {
                                  _selectedChapters.remove(idx);
                                }
                              }),
                            );
                          }).toList(),
                        ),
            ),

          if (_selectedBook != null) const SizedBox(height: 12),

          // ── 3. Question counts ─────────────────────────────────────────────
          _buildQuestionCountsCard(step: _selectedBook != null ? '3' : '2'),
          const SizedBox(height: 12),

          // ── 4. Settings ────────────────────────────────────────────────────
          _buildSettingsCard(step: _selectedBook != null ? '4' : '3'),
          const SizedBox(height: 20),

          // ── Generate button ────────────────────────────────────────────────
          if (_generating)
            Column(children: [
              const LinearProgressIndicator(color: _purple),
              const SizedBox(height: 8),
              Text('Generating questions… this may take a few minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 16),
            ]),

          FilledButton.icon(
            onPressed: (_generating || _selectedBook == null || _totalQuestions == 0)
                ? null
                : _generateFromBook,
            icon: _generating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_generating ? 'Generating…' : 'Generate Questions'),
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          // ── Preview + export ───────────────────────────────────────────────
          if (_generatedQuestions != null) ...[
            const SizedBox(height: 20),
            _QualityBanner(quality: _quality),
            const SizedBox(height: 12),
            _QuestionPreview(questions: _generatedQuestions!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _exporting ? null : _exportDocx,
              icon: _exporting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_rounded),
              label: Text(_exporting ? 'Exporting…' : 'Download as Word (.docx)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── PDF tab ───────────────────────────────────────────────────────────────────

  Widget _buildPdfTab() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoBanner(
            icon: Icons.info_outline_rounded,
            text: 'Use this tab for PDFs NOT in the curriculum index. '
                'Requires Ollama running with the smartschool model.',
            color: _purple,
          ),
          const SizedBox(height: 16),

          // ── PDF picker ─────────────────────────────────────────────────────
          _SectionCard(
            title: '1. Upload PDF',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _pdfLoading ? null : _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_pickedFile == null ? 'Choose PDF file' : _pickedFile!.name),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                if (_pickedFile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text(
                  'Page Range  (optional — leave blank to use the whole PDF)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pageStartCtrl,
                        enabled: !_pdfLoading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'From page',
                          hintText: '1',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.first_page_rounded, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _pageEndCtrl,
                        enabled: !_pdfLoading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'To page',
                          hintText: 'Last',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.last_page_rounded, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildQuestionCountsCard(step: '2'),
          const SizedBox(height: 12),
          _buildSettingsCard(step: '3'),
          const SizedBox(height: 20),

          if (_pdfLoading) ...[
            LinearProgressIndicator(
              value: _pdfProgress > 0 ? _pdfProgress : null,
              color: _purple,
              backgroundColor: _purple.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(_pdfStatus,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 16),
          ],

          FilledButton.icon(
            onPressed: (_pdfLoading || _pickedFile == null || _totalQuestions == 0)
                ? null
                : _generateFromPdf,
            icon: _pdfLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded),
            label: Text(_pdfLoading
                ? 'Generating… please wait'
                : 'Generate & Download (.docx)'),
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Shared sub-sections ────────────────────────────────────────────────────

  Widget _buildQuestionCountsCard({required String step}) => _SectionCard(
        title: '$step. Question Types  (Total: $_totalQuestions)',
        child: Column(
          children: [
            _CountRow(label: 'Multiple Choice (MCQ)',    value: _mcqCount,
                onChanged: (v) => setState(() => _mcqCount = v)),
            _CountRow(label: 'True / False',             value: _trueFalseCount,
                onChanged: (v) => setState(() => _trueFalseCount = v)),
            _CountRow(label: 'Short Answer',             value: _shortAnswerCount,
                onChanged: (v) => setState(() => _shortAnswerCount = v)),
            _CountRow(label: 'Fill in the Blank',        value: _fillBlankCount,
                onChanged: (v) => setState(() => _fillBlankCount = v)),
            _CountRow(label: 'Essay',                    value: _essayCount,
                onChanged: (v) => setState(() => _essayCount = v), max: 20),
          ],
        ),
      );

  Widget _buildSettingsCard({required String step}) {
    final cs = Theme.of(context).colorScheme;
    return _SectionCard(
      title: '$step. Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DropdownRow(
            label: 'Difficulty',
            value: _difficulty,
            items: const [
              DropdownMenuItem(value: 'easy',   child: Text('Easy')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'hard',   child: Text('Hard')),
            ],
            onChanged: (v) => setState(() => _difficulty = v!),
          ),
          const SizedBox(height: 8),
          _DropdownRow(
            label: 'Language',
            value: _language,
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Auto Detect')),
              DropdownMenuItem(value: 'ar',   child: Text('Arabic')),
              DropdownMenuItem(value: 'en',   child: Text('English')),
            ],
            onChanged: (v) => setState(() => _language = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Exam Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            controller: TextEditingController(text: _title),
            onChanged: (v) => _title = v.isEmpty ? 'Exam Questions' : v,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text("Bloom's Taxonomy Levels",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _kBloomLevels.entries.map((e) {
              final selected = _bloomLevels.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (on) => setState(() {
                  if (on) {
                    _bloomLevels.add(e.key);
                  } else if (_bloomLevels.length > 1) {
                    _bloomLevels.remove(e.key);
                  }
                }),
                selectedColor: _purple.withValues(alpha: 0.18),
                checkmarkColor: _purple,
                labelStyle: TextStyle(
                  color:      selected ? _purple : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include Answer Key'),
            subtitle: const Text('Appends answers at the end of the Word file'),
            value: _includeAnswers,
            onChanged: (v) => setState(() => _includeAnswers = v),
            activeColor: _purple,
          ),
        ],
      ),
    );
  }
}

// ── Quality banner ────────────────────────────────────────────────────────────

class _QualityBanner extends StatelessWidget {
  final Map<String, dynamic>? quality;
  const _QualityBanner({required this.quality});

  @override
  Widget build(BuildContext context) {
    if (quality == null) return const SizedBox.shrink();
    final score    = quality!['average_score'];
    final passRate = quality!['pass_rate'];
    final grade    = quality!['overall_grade'] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quality: $grade  •  avg ${score?.toStringAsFixed(1) ?? "—"} / 100'
              '  •  pass rate ${passRate?.toStringAsFixed(0) ?? "—"}%',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question preview ──────────────────────────────────────────────────────────

class _QuestionPreview extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  const _QuestionPreview({required this.questions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${questions.length} question(s) generated',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...questions.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final type = q['type']?.toString().toUpperCase() ?? '';
            final text = q['question']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(type,
                        style: const TextStyle(
                            fontSize: 10, color: _purple, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${i + 1}. $text',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (questions.length > 5)
            Text('… and ${questions.length - 5} more',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int max;
  const _CountRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 50,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(
            width: 32,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            hint: hint != null ? Text(hint!) : null,
            items: items,
            onChanged: onChanged,
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
