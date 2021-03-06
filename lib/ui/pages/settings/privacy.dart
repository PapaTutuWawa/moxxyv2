import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:moxxyv2/shared/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({ Key? key }): super(key: key);

  // ignore: implicit_dynamic_type
  static MaterialPageRoute get route => MaterialPageRoute(builder: (_) => const PrivacyPage());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Privacy'),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16),
          sections: [
            SettingsSection(
              title: 'General',
              tiles: [
                SettingsTile.switchTile(
                  title: 'Show contact requests',
                  subtitle: 'This will show people who added you to their contact list but sent no message yet',
                  subtitleMaxLines: 2,
                  switchValue: state.showSubscriptionRequests,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(showSubscriptionRequests: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: 'Make profile picture public',
                  subtitle: 'If enabled, everyone can see your profile picture. If disabled, only users on your contact list can see your profile picture.',
                  subtitleMaxLines: 3,
                  switchValue: state.isAvatarPublic,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(isAvatarPublic: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: 'Auto-accept subscription requests',
                  subtitle: 'If enabled, subscription requests will be automatically accepted if the user is in the contact list.',
                  subtitleMaxLines: 3,
                  switchValue: state.autoAcceptSubscriptionRequests,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(autoAcceptSubscriptionRequests: value),
                    ),
                  ),
                )
              ],
            ),
            SettingsSection(
              title: 'Conversation',
              tiles: [
                SettingsTile.switchTile(
                  title: 'Send chat markers',
                  subtitle: 'This will tell your conversation partner if you received or read a message',
                  subtitleMaxLines: 2,
                  switchValue: state.sendChatMarkers,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatMarkers: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: 'Send chat states',
                  subtitle: 'This will show your conversation partner if you are typing or looking at the chat',
                  subtitleMaxLines: 2,
                  switchValue: state.sendChatStates,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatStates: value),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
