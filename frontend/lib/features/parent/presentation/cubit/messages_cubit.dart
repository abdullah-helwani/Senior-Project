import 'package:equatable/equatable.dart';
import 'package:first_try/features/parent/data/models/parent_extra_models.dart';
import 'package:first_try/features/parent/data/repos/parent_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ───────────────────────────────────────────────────────────────────

sealed class MessagesState extends Equatable {
  const MessagesState();
  @override
  List<Object?> get props => [];
}

class MessagesInitial extends MessagesState {
  const MessagesInitial();
}

class MessagesLoading extends MessagesState {
  const MessagesLoading();
}

class MessagesLoaded extends MessagesState {
  final List<MessageModel> inbox;
  final MessageModel? opened; // currently-viewed message (detail)
  final bool sending;

  const MessagesLoaded({
    required this.inbox,
    this.opened,
    this.sending = false,
  });

  MessagesLoaded copyWith({
    List<MessageModel>? inbox,
    MessageModel? opened,
    bool clearOpened = false,
    bool? sending,
  }) =>
      MessagesLoaded(
        inbox: inbox ?? this.inbox,
        opened: clearOpened ? null : (opened ?? this.opened),
        sending: sending ?? this.sending,
      );

  @override
  List<Object?> get props => [inbox, opened, sending];
}

class MessagesError extends MessagesState {
  final String message;
  const MessagesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class MessagesCubit extends Cubit<MessagesState> {
  final ParentRepo repo;

  MessagesCubit({required this.repo}) : super(const MessagesInitial());

  Future<void> loadInbox() async {
    emit(const MessagesLoading());
    try {
      final inbox = await repo.getMessages();
      emit(MessagesLoaded(inbox: inbox));
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }

  /// Open a specific message (fetches fresh so read_at is updated server-side).
  Future<void> open(int messageId) async {
    final s = state;
    final base = s is MessagesLoaded ? s : const MessagesLoaded(inbox: []);
    emit(base.copyWith(opened: null, clearOpened: true));
    try {
      final m = await repo.getMessage(messageId);
      // Reflect the read state in the inbox list too.
      final inbox = base.inbox
          .map((x) => x.id == m.id ? m : x)
          .toList();
      emit(base.copyWith(inbox: inbox, opened: m));
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }

  void closeOpened() {
    final s = state;
    if (s is MessagesLoaded) emit(s.copyWith(clearOpened: true));
  }

  Future<bool> send({
    required int teacherId,
    int? studentId,
    required String subject,
    required String body,
  }) async {
    final s = state;
    final base = s is MessagesLoaded ? s : const MessagesLoaded(inbox: []);
    emit(base.copyWith(sending: true));
    try {
      final created = await repo.sendMessage(
        teacherId: teacherId,
        studentId: studentId,
        subject: subject,
        body: body,
      );
      emit(base.copyWith(
        inbox: [created, ...base.inbox],
        sending: false,
      ));
      return true;
    } catch (e) {
      emit(base.copyWith(sending: false));
      emit(MessagesError(e.toString()));
      return false;
    }
  }
}
