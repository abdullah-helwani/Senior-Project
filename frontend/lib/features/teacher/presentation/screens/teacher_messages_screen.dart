import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/shared/empty_state.dart';
import 'package:first_try/core/widgets/shared/error_view.dart';
import 'package:first_try/core/widgets/shared/loading_view.dart';
import 'package:first_try/core/widgets/shared/skeletons.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/auth/current_user.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/presentation/cubit/teacher_messages_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TeacherMessagesScreen extends StatefulWidget {
  const TeacherMessagesScreen({super.key});

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    context.read<TeacherMessagesCubit>().load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            BlocBuilder<TeacherMessagesCubit, TeacherMessagesState>(
              builder: (context, state) {
                final unread =
                    state is TeacherMessagesLoaded ? state.unreadCount : 0;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Inbox'),
                      if (unread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.error,
                            borderRadius: Radii.pillRadius,
                          ),
                          child: Text(
                            '$unread',
                            style: TextStyle(
                                color: cs.onError,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Sent'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompose(context),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Compose'),
      ),
      body: BlocBuilder<TeacherMessagesCubit, TeacherMessagesState>(
        builder: (context, state) {
          if (state is TeacherMessagesLoading ||
              state is TeacherMessagesInitial) {
            return const CardListSkeleton(showFilter: true);
          }
          if (state is TeacherMessagesError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<TeacherMessagesCubit>().load(),
            );
          }
          if (state is! TeacherMessagesLoaded) return const SizedBox.shrink();

          return TabBarView(
            controller: _tab,
            children: [
              _MessageList(messages: state.inbox, isInbox: true),
              _MessageList(messages: state.sent, isInbox: false),
            ],
          );
        },
      ),
    );
  }

  void _showCompose(BuildContext context) {
    final cubit = context.read<TeacherMessagesCubit>();
    showAppBottomSheet<void>(
      context: context,
      title: 'New Message',
      subtitle: 'Send a message to a parent.',
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: const _ComposeSheet(),
      ),
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<TeacherMessageModel> messages;
  final bool isInbox;
  const _MessageList({required this.messages, required this.isInbox});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.mail_outline_rounded,
        title: isInbox ? 'No messages' : 'No sent messages',
        subtitle: isInbox
            ? "You'll see messages from parents here."
            : 'Your sent messages will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<TeacherMessagesCubit>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) =>
            _MessageTile(message: messages[i], isInbox: isInbox),
      ),
    );
  }
}

// ── Message tile ──────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final TeacherMessageModel message;
  final bool isInbox;
  const _MessageTile({required this.message, required this.isInbox});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showUnread = isInbox && !message.isRead;
    final other = isInbox
        ? (message.senderName ?? 'Unknown')
        : (message.receiverName ?? 'Unknown');

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: showUnread ? cs.primary : cs.primaryContainer,
          child: Text(
            other.isNotEmpty ? other[0].toUpperCase() : '?',
            style: TextStyle(
                color: showUnread ? cs.onPrimary : cs.onPrimaryContainer,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(other,
                      style: TextStyle(
                        fontWeight:
                            showUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      )),
                ),
                if (!isInbox && message.isRead)
                  Icon(Icons.done_all_rounded,
                      size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(_fmt(message.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 2),
              if (message.subject != null)
                Text(message.subject!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              Text(message.body,
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (message.studentName != null) ...[
                const SizedBox(height: 4),
                Text('Re: ${message.studentName}',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        if (showUnread)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, left: 6),
            decoration: BoxDecoration(
                color: cs.primary, shape: BoxShape.circle),
          ),
      ],
    );

    return showUnread
        ? AppCard.filled(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(14),
            onTap: () => _open(context),
            child: content,
          )
        : AppCard.surface(
            padding: const EdgeInsets.all(14),
            onTap: () => _open(context),
            child: content,
          );
  }

  void _open(BuildContext context) {
    final cubit = context.read<TeacherMessagesCubit>();
    cubit.open(message.id);
    showAppBottomSheet<void>(
      context: context,
      title: message.subject ?? 'Message',
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _MessageDetailSheet(),
      ),
    ).then((_) => cubit.closeOpened());
  }

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Message detail sheet ──────────────────────────────────────────────────────

class _MessageDetailSheet extends StatelessWidget {
  const _MessageDetailSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherMessagesCubit, TeacherMessagesState>(
      builder: (context, state) {
        if (state is! TeacherMessagesLoaded || state.opened == null) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: LoadingView(),
          );
        }
        final m = state.opened!;
        final cs = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('From: ',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                Text(m.senderName ?? '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              Row(children: [
                Text('To: ',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                Text(m.receiverName ?? '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              if (m.studentName != null) ...[
                const SizedBox(height: 4),
                Text('Re: ${m.studentName}',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 4),
              Text(_fmtFull(m.createdAt),
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const Divider(height: 24),
              Text(m.body,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
              if (m.readAt != null) ...[
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.done_all_rounded,
                      size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text('Read ${_fmtFull(m.readAt!)}',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  String _fmtFull(String iso) {
    try {
      return DateFormat('d MMM y, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Compose sheet ─────────────────────────────────────────────────────────────

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _receiverCtrl = TextEditingController();
  final _studentCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _receiverCtrl.dispose();
    _studentCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final _ = context.currentUserId;
    return BlocBuilder<TeacherMessagesCubit, TeacherMessagesState>(
      builder: (context, state) {
        final sending = state is TeacherMessagesLoaded && state.sending;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _receiverCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Parent user ID *',
                  helperText: 'Numeric user_id of the recipient parent',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _studentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Student ID (optional)',
                  prefixIcon: Icon(Icons.child_care_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject (optional)',
                  prefixIcon: Icon(Icons.subject_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bodyCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 72),
                    child: Icon(Icons.message_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                label: 'Send',
                icon: Icons.send_rounded,
                fullWidth: true,
                size: AppButtonSize.lg,
                loading: sending,
                onPressed: sending ? null : () => _submit(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final receiver = int.tryParse(_receiverCtrl.text.trim());
    final body = _bodyCtrl.text.trim();
    if (receiver == null || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Recipient user ID and message are required.')),
      );
      return;
    }
    final ok = await context.read<TeacherMessagesCubit>().send(
          receiverUserId: receiver,
          studentId: int.tryParse(_studentCtrl.text.trim()),
          subject: _subjectCtrl.text.trim().isEmpty
              ? null
              : _subjectCtrl.text.trim(),
          body: body,
        );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent.')),
      );
    }
  }
}
