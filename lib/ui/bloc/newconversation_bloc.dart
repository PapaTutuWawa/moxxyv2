import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart' as conversation;
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';

part 'newconversation_bloc.freezed.dart';
part 'newconversation_event.dart';
part 'newconversation_state.dart';

class NewConversationBloc extends Bloc<NewConversationEvent, NewConversationState> {
  NewConversationBloc() : super(NewConversationState()) {
    on<NewConversationInitEvent>(_onInit);
    on<NewConversationAddedEvent>(_onAdded);
    on<NewConversationRosterItemRemovedEvent>(_onRosterItemRemoved);
    on<RosterPushedEvent>(_onRosterPushed);
  }

  Future<void> _onInit(NewConversationInitEvent event, Emitter<NewConversationState> emit) async {
    return emit(
      state.copyWith(
        roster: event.roster,
      ),
    );
  }

  Future<void> _onAdded(NewConversationAddedEvent event, Emitter<NewConversationState> emit) async {
    final conversations = GetIt.I.get<ConversationsBloc>();

    // Guard against an unneccessary roundtrip
    if (listContains(conversations.state.conversations, (Conversation c) => c.jid == event.jid)) {
      GetIt.I.get<conversation.ConversationBloc>().add(
        conversation.RequestedConversationEvent(
          event.jid,
          event.title,
          event.avatarUrl,
          removeUntilConversations: true,
        ),
      );
      return;
    }

    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      AddConversationCommand(
        title: event.title,
        jid: event.jid,
        avatarUrl: event.avatarUrl,
        lastMessageBody: '',
      ),
    );
    
    if (result is NoConversationModifiedEvent) {
      // Fall through
    } else if (result is ConversationUpdatedEvent) {
      conversations.add(ConversationsUpdatedEvent(result.conversation));
    } else if (result is ConversationAddedEvent) {
      conversations.add(ConversationsAddedEvent(result.conversation));
    }

    GetIt.I.get<conversation.ConversationBloc>().add(
      conversation.RequestedConversationEvent(
        event.jid,
        event.title,
        event.avatarUrl,
        removeUntilConversations: true,
      ),
    );
  }

  Future<void> _onRosterItemRemoved(NewConversationRosterItemRemovedEvent event, Emitter<NewConversationState> emit) async {
    return emit(
      state.copyWith(
        roster: state.roster.where(
          (item) => item.jid != event.jid,
        ).toList(),
      ),
    );
  }

  Future<void> _onRosterPushed(RosterPushedEvent event, Emitter<NewConversationState> emit) async {
    // TODO(Unknown): Should we guard against adding the same entries multiple times?
    final roster = List<RosterItem>.from(event.added);

    for (final item in state.roster) {
      final modified = firstWhereOrNull(
        event.modified,
        (RosterItem i) => i.id == item.id,
      );
      if (modified != null) {
        roster.add(modified);
      } else {
        roster.add(item);
      }
    }

    emit(state.copyWith(roster: roster));
  }
}
