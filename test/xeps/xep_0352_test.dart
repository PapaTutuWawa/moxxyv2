import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/attributes.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/reconnect.dart';
import 'package:moxxyv2/xmpp/settings.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0352.dart';
import 'package:test/test.dart';

import '../helpers/xmpp.dart';

class MockedCSINegotiator extends CSINegotiator {
  MockedCSINegotiator(this._isSupported);

  final bool _isSupported;
  
  @override
  bool get isSupported => _isSupported;
}

T? getSupportedCSINegotiator<T extends XmppFeatureNegotiatorBase>(String id) {
  if (id == csiNegotiator) {
    return MockedCSINegotiator(true) as T;
  }

  return null;
}

T? getUnsupportedCSINegotiator<T extends XmppFeatureNegotiatorBase>(String id) {
  if (id == csiNegotiator) {
    return MockedCSINegotiator(false) as T;
  }

  return null;
}

void main() {
  group('Test the XEP-0352 implementation', () {
      test('Test setting the CSI state when CSI is unsupported', () {
          var nonzaSent = false;
          final csi = CSIManager();
          csi.register(XmppManagerAttributes(
              sendStanza: (_, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async => XMLNode(tag: 'hallo'),
              sendEvent: (event) {},
              sendNonza: (nonza) {
                nonzaSent = true;
              },
              sendRawXml: (_) {},
              getConnectionSettings: () => ConnectionSettings(
                jid: JID.fromString('some.user@example.server'),
                password: 'password',
                useDirectTLS: true,
                allowPlainAuth: false,
              ),
              getManagerById: getManagerNullStub,
              getNegotiatorById: getUnsupportedCSINegotiator,
              isFeatureSupported: (_) => false,
              getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
              getSocket: () => StubTCPSocket(play: []),
              getConnection: () => XmppConnection(TestingReconnectionPolicy()),
            ),
          );

          csi.setActive();
          csi.setInactive();

          expect(nonzaSent, false, reason: 'Expected that no nonza is sent');
      });
      test('Test setting the CSI state when CSI is supported', () {
          final csi = CSIManager();
          csi.register(XmppManagerAttributes(
              sendStanza: (_, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async => XMLNode(tag: 'hallo'),
              sendEvent: (event) {},
              sendNonza: (nonza) {
                expect(nonza.attributes['xmlns'] == csiXmlns, true, reason: "Expected only nonzas with XMLNS '$csiXmlns'");
              },
              sendRawXml: (_) {},
              getConnectionSettings: () => ConnectionSettings(
                jid: JID.fromString('some.user@example.server'),
                password: 'password',
                useDirectTLS: true,
                allowPlainAuth: false,
              ),
              getManagerById: getManagerNullStub,
              getNegotiatorById: getSupportedCSINegotiator,
              isFeatureSupported: (_) => false,
              getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
              getSocket: () => StubTCPSocket(play: []),
              getConnection: () => XmppConnection(TestingReconnectionPolicy()),
          ),);

          csi.setActive();
          csi.setInactive();
      });
  });
}
