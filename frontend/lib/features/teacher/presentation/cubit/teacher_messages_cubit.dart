import 'package:equatable/equatable.dart';
import 'package:first_try/features/teacher/data/models/teacher_extra_models.dart';
import 'package:first_try/features/teacher/data/repos/teacher_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TeacherMessagesState extends Equatable {
  const TeacherMessagesState();
  @override
  List<Object?> get props => [];
}

class TeacherMessagesInitial extends TeacherMessagesState {
  const TeacherMessagesInitial();
}

class TeacherMessagesLoading extends TeacherMessagesState {
  const TeacherMessagesLoading();
}

class TeacherMessagesLoaded extends TeacherMessagesState {
  final int unreadCount;
  final List<TeacherMessageModel> inbox;
  final List<TeacherMessageModel> sent;
  final TeacherMessageModel? opened;
  final bool sending;

  const TeacherMessagesLoaded({
    this.unreadCount = 0,
    this.inbox = const [],
    this.sent = const [],
    this.opened,
    this.sending = false,
  });

  TeacherMessagesLoaded copyWith({
    int? unreadCount,
    List<TeacherMessageModel>? inbox,
    List<TeacherMessageModel>? sent,
    TeacherMessageModel? opened,
    bool clearOpened = false,
    bool? sending,
  }) =>
      TeacherMessagesLoaded(
        unreadCount: unreadCount ?? this.unreadCount,
        inbox: inbox ?? this.inbox,
        sent: sent ?? this.sent,
        opened: clearOpened ? null : (opened ?? this.opened),
        sending: sending ?? this.sending,
      );

  @override
  List<Object?> get props => [unreadCount, inbox, sent, opened, sending];
}

class TeacherMessagesError extends TeacherMessagesState {
  final String message;
  const TeacherMessagesError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherMessagesCubit extends Cubit<TeacherMessagesState> {
  final TeacherRepo repo;

  TeacherMessagesCubit({required this.repo})
      : super(const TeacherMessagesInitial());

  Future<void> load() async {
    emit(const TeacherMessagesLoading());
    try {
      final results = await Future.wait([
        repo.getInbox(),
        repo.getSentMessages(),
      ]);
      final inbox = results[0] as TeacherInboxModel;
      final sent = results[1] as List<TeacherMessageModel>;
      emit(TeacherMessagesLoaded(
        unreadCount: inbox.unreadCount,
        inbox: inbox.messages,
        sent: sent,
      ));
    } catch (e) {
      emit(TeacherMessagesError(e.toString()));
    }
  }

  Future<void> open(int messageId) async {
    final s = state;
    final base = s is TeacherMessagesLoaded ? s : const TeacherMessagesLoaded();
    emit(base.copyWith(clearOpened: true));
    try {
      final m = await repo.getMessage(messageId);
      // Reflect read status in the inbox.
      final inbox = base.inbox.map((x) => x.id == m.id ? m : x).toList();
      final unread = inbox.where((x) => !x.isRead).length;
      emit(base.copyWith(opened: m, inbox: inbox, unreadCount: unread));
    } catch (e) {
      emit(TeacherMessagesError(e.toString()));
    }
  }

  void closeOpened() {
    final s = state;
    if (s is TeacherMessagesLoaded) emit(s.copyWith(clearOpened: true));
  }

  Future<bool> send({
    required int receiverUserId,
    int? studentId,
    String? subject,
    required String body,
  }) async {
    final s = state;
    final base = s is TeacherMessagesLoaded ? s : const TeacherMessagesLoaded();
    emit(base.copyWith(sending: true));
    try {
      final created = await repo.sendMessage(
        receiverUserId: receiverUserId,
        studentId: studentId,
        subject: subject,
        body: body,
      );
      emit(base.copyWith(
        sent: [created, ...base.sent],
        sending: false,
      ));
      return true;
    } catch (e) {
      emit(base.copyWith(sending: false));
      emit(TeacherMessagesError(e.toString()));
      return false;
    }
  }
}
