import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class NewConversationPage extends StatelessWidget {
  const NewConversationPage({ Key? key }) : super(key: key);
 
  // ignore: implicit_dynamic_type
  static MaterialPageRoute get route => MaterialPageRoute(builder: (_) => const NewConversationPage());
  
  Widget _renderIconEntry(IconData icon, String text, void Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AvatarWrapper(
              radius: 35,
              altIcon: icon,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final maxTextWidth = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: BorderlessTopbar.simple('Start new chat'),
      body: BlocBuilder<NewConversationBloc, NewConversationState>(
        builder: (BuildContext context, NewConversationState state) => ListView.builder(
          itemCount: state.roster.length + 2,
          itemBuilder: (context, index) {
            switch(index) {
              case 0: return _renderIconEntry(
                Icons.person_add,
                'Add contact',
                () => Navigator.pushNamed(context, addContactRoute),
              );
              case 1: return _renderIconEntry(
                Icons.group_add,
                'Create groupchat',
                () => showNotImplementedDialog('groupchat', context),
              );
              default:
                final item = state.roster[index - 2];
                return Dismissible(
                  key: ValueKey('roster;${item.jid}'),
                  onDismissed: (_) => context.read<NewConversationBloc>().add(
                    NewConversationRosterItemRemovedEvent(item.jid),
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
                    onTap: () => context.read<NewConversationBloc>().add(
                      NewConversationAddedEvent(
                        item.jid,
                        item.title,
                        item.avatarUrl,
                      ),
                    ),
                    child: ConversationsListRow(item.avatarUrl, item.title, item.jid, 0, maxTextWidth, timestampNever, false),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
