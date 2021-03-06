import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

enum ConversationsOptions {
  settings
}

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({ Key? key }) : super(key: key);

  // ignore: implicit_dynamic_type
  static MaterialPageRoute get route => MaterialPageRoute(builder: (context) => const ConversationsPage());
  
  Widget _listWrapper(BuildContext context, ConversationsState state) {
    final maxTextWidth = MediaQuery.of(context).size.width * 0.6;

    if (state.conversations.isNotEmpty) {
      return ListView.builder(
        itemCount: state.conversations.length,
        itemBuilder: (_context, index) {
          final item = state.conversations[index];
          return Dismissible(
            key: ValueKey('conversation;$item'),
            onDismissed: (direction) => context.read<ConversationsBloc>().add(
              ConversationClosedEvent(item.jid),
            ),
            background: Container(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.delete),
                    Spacer(),
                    Icon(Icons.delete)
                  ],
                ),
              ),
            ),
            child: InkWell(
              onTap: () => GetIt.I.get<ConversationBloc>().add(
                RequestedConversationEvent(item.jid, item.title, item.avatarUrl),
              ),
              child: ConversationsListRow(
                item.avatarUrl,
                item.title,
                item.lastMessageBody,
                item.unreadCounter,
                maxTextWidth,
                item.lastChangeTimestamp,
                true,
                typingIndicator: item.chatState == ChatState.composing,
                key: ValueKey('conversationRow;${item.jid}'),
              ),
            ), 
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // TODO(Unknown): Maybe somehow render the svg
            child: Image.asset('assets/images/begin_chat.png'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('You have no open chats'),
          ),
          TextButton(
            child: const Text('Start a chat'),
            onPressed: () => Navigator.pushNamed(context, newConversationRoute),
          )
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      builder: (BuildContext context, ConversationsState state) => Scaffold(
        appBar: BorderlessTopbar.avatarAndName(
          TopbarAvatarAndName(
            TopbarTitleText(state.displayName as String),
            Hero(
              tag: 'self_profile_picture',
              child: Material(
                child: AvatarWrapper(
                  radius: 20,
                  avatarUrl: state.avatarUrl as String,
                  altIcon: Icons.person,
                ),
              ),
            ),
            () => GetIt.I.get<ProfileBloc>().add(
              ProfilePageRequestedEvent(
                true,
                jid: state.jid as String,
                avatarUrl: state.avatarUrl as String,
                displayName: state.displayName as String,
              ),
            ),
            showBackButton: false,
            extra: [
              PopupMenuButton(
                onSelected: (ConversationsOptions result) {
                  switch (result) {
                    case ConversationsOptions.settings: Navigator.pushNamed(context, settingsRoute);
                    break;
                  }
                },
                icon: const Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: ConversationsOptions.settings,
                    child: Text('Settings'),
                  )
                ],
              )
            ],
          ),
        ),
        body: _listWrapper(context, state),
        floatingActionButton: SpeedDial(
          icon: Icons.chat,
          curve: Curves.bounceInOut,
          backgroundColor: primaryColor,
          // TODO(Unknown): Theme dependent?
          foregroundColor: Colors.white,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.group),
              onTap: () => showNotImplementedDialog('groupchat', context),
              backgroundColor: primaryColor,
              // TODO(Unknown): Theme dependent?
              foregroundColor: Colors.white,
              label: 'Join groupchat',
            ),
            SpeedDialChild(
              child: const Icon(Icons.person_add),
              onTap: () => Navigator.pushNamed(context, newConversationRoute),
              backgroundColor: primaryColor,
              // TODO(Unknown): Theme dependent?
              foregroundColor: Colors.white,
              label: 'New chat',
            )
          ],
        ),
      ),
    );
  }
}
