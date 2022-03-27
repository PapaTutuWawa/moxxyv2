import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/blocking.dart";
import "package:moxxyv2/service/avatars.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";
import "package:permission_handler/permission_handler.dart";

Future<void> performLoginHandler(LoginCommand command, { dynamic extra }) async {
  final id = extra as String;

  GetIt.I.get<Logger>().fine("Performing login");
  final result = await GetIt.I.get<XmppService>().connectAwaitable(
    ConnectionSettings(
      jid: JID.fromString(command.jid),
      password: command.password,
      useDirectTLS: command.useDirectTLS,
      allowPlainAuth: false
    ), true
  );

  if (result.success) {
    final settings = GetIt.I.get<XmppConnection>().getConnectionSettings();
    sendEvent(
      LoginSuccessfulEvent(
        jid: settings.jid.toString(),
        displayName: settings.jid.local
      ),
      id:id
    );
  } else {
    sendEvent(
      LoginFailureEvent(
        reason: result.reason!
      ),
      id: id
    );
  }
}

Future<void> performPreStart(PerformPreStartCommand command, { dynamic extra }) async {
  final id = extra as String;
  
  final xmpp = GetIt.I.get<XmppService>();
  final account = await xmpp.getAccountData();
  final settings = await xmpp.getConnectionSettings();
  final state = await xmpp.getXmppState();
  final preferences = await GetIt.I.get<PreferencesService>().getPreferences();


  GetIt.I.get<Logger>().finest("account != null: " + (account != null).toString());
  GetIt.I.get<Logger>().finest("settings != null: " + (settings != null).toString());

  if (account!= null && settings != null) {
    await GetIt.I.get<RosterService>().loadRosterFromDatabase();

    // Check some permissions
    final storagePerm = await Permission.storage.status;
    final List<int> permissions = List.empty(growable: true);
    if (storagePerm.isDenied /*&& !state.askedStoragePermission*/) {
      permissions.add(Permission.storage.value);

      await xmpp.modifyXmppState((state) => state.copyWith(
          askedStoragePermission: true
      ));
    }
    
    sendEvent(
      PreStartDoneEvent(
        state: "logged_in",
        jid: account.jid,
        displayName: account.displayName,
        avatarUrl: state.avatarUrl,
        permissionsToRequest: permissions,
        preferences: preferences,
        conversations: await GetIt.I.get<DatabaseService>().loadConversations(),
        roster: await GetIt.I.get<RosterService>().loadRosterFromDatabase()
      ),
      id: id
    );
  } else {
    sendEvent(
      PreStartDoneEvent(
        state: "not_logged_in",
        permissionsToRequest: List<int>.empty(),
        preferences: preferences
      ),
      id: id
    );
  }
}

Future<void> performAddConversation(AddConversationCommand command, { dynamic extra }) async {
  final id = extra as String;

  final db = GetIt.I.get<DatabaseService>();
  final conversation = await db.getConversationByJid(command.jid);
  if (conversation != null) {
    if (!conversation.open) {
      // Re-open the conversation
      final updatedConversation = await db.updateConversation(
        id: conversation.id,
        open: true
      );

      sendEvent(
        ConversationAddedEvent(
          conversation: updatedConversation
        ),
        id: id
      );
      return;
    }

    sendEvent(
      NoConversationModifiedEvent(),
      id: id
    );
    return;
  } else {
    final conversation = await db.addConversationFromData(
      command.title,
      command.lastMessageBody,
      command.avatarUrl,
      command.jid,
      0,
      -1,
      const [],
      true
    );

    sendEvent(
      ConversationAddedEvent(
        conversation: conversation
      ),
      id: id
    );
  }
}

Future<void> performGetMessagesForJid(GetMessagesForJidCommand command, { dynamic extra }) async {
  final id = extra as String;

  sendEvent(
    MessagesResultEvent(
      messages: await GetIt.I.get<DatabaseService>().getMessagesForJid(command.jid)
    ),
    id: id
  );
}

Future<void> performSetOpenConversation(SetOpenConversationCommand command, { dynamic extra }) async {
  GetIt.I.get<XmppService>().setCurrentlyOpenedChatJid(command.jid ?? "");
}

Future<void> performSendMessage(SendMessageCommand command, { dynamic extra }) async {
  GetIt.I.get<XmppService>().sendMessage(
    body: command.body,
    jid: command.jid,
    quotedMessage: command.quotedMessage,
    commandId: extra as String
  );
}

Future<void> performBlockJid(BlockJidCommand command, { dynamic extra }) async {
  GetIt.I.get<BlocklistService>().blockJid(command.jid);
}

Future<void> performUnblockJid(UnblockJidCommand command, { dynamic extra }) async {
  GetIt.I.get<BlocklistService>().unblockJid(command.jid);
}

Future<void> performUnblockAll(UnblockAllCommand command, { dynamic extra }) async {
  GetIt.I.get<BlocklistService>().unblockAll();
}

Future<void> performSetCSIState(SetCSIStateCommand command, { dynamic extra }) async {
  final csi = GetIt.I.get<XmppConnection>().getManagerById(csiManager)!;
  if (command.active) {
    csi.setActive();
  } else {
    csi.setInactive();
  }
}

Future<void> performSetPreferences(SetPreferencesCommand command, { dynamic extra }) async {
  GetIt.I.get<PreferencesService>().modifyPreferences((_) => command.preferences);
}

Future<void> performAddContact(AddContactCommand command, { dynamic extra }) async {
  final id = extra as String;

  final jid = command.jid;
  final roster = GetIt.I.get<RosterService>();
  if (await roster.isInRoster(jid)) {
    sendEvent(AddContactResultEvent(conversation: null, added: false), id: id);
    return;
  }

  final db = GetIt.I.get<DatabaseService>();
  final conversation = await db.getConversationByJid(jid);
  if (conversation != null) {
    final c = await db.updateConversation(id: conversation.id, open: true);

    sendEvent(
      AddContactResultEvent(conversation: c, added: false),
      id: id
    );
  } else {            
    final c = await db.addConversationFromData(
      jid.split("@")[0],
      "",
      "",
      jid,
      0,
      -1,
      [],
      true
    );
    sendEvent(
      AddContactResultEvent(conversation: c, added: true),
      id: id
    );
  }

  roster.addToRosterWrapper("", jid, jid.split("@")[0]);
  
  // Try to figure out an avatar
  await GetIt.I.get<AvatarService>().subscribeJid(jid);
  GetIt.I.get<AvatarService>().fetchAndUpdateAvatarForJid(jid);
}
