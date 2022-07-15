import "package:moxxyv2/xmpp/stringxml.dart";

/// The state a negotiator is currently in
enum NegotiatorState {
  // Ready to negotiate the feature
  ready,
  // Feature negotiated; negotiator must not be used again
  done,
  // Cancel the current attempt but we are not done
  retryLater
}

class NegotiatorAttributes {
  final void Function(XMLNode nonza) sendNonza;

  const NegotiatorAttributes(this.sendNonza);
}

abstract class XmppFeatureNegotiatorBase {
  /// The priority regarding other negotiators. The higher, the earlier will the
  /// negotiator be used
  final int priority;

  /// If true, then a new stream header will be sent when the negotiator switches its
  /// state to done. If false, no stream header will be sent.
  final bool sendStreamHeaderWhenDone;

  /// The XMLNS the negotiator will negotiate
  final String negotiatingXmlns;

  /// The state the negotiator is currently in
  // TODO: Make private
  NegotiatorState state;
  
  late NegotiatorAttributes _attributes;

  XmppFeatureNegotiatorBase(this.priority, this.sendStreamHeaderWhenDone, this.negotiatingXmlns)
    : state = NegotiatorState.ready;

  /// Register the negotiator against a connection class by means of [attributes].
  void register(NegotiatorAttributes attributes) {
    _attributes = attributes;
  }
  
  /// Returns true if a feature in [feature], which are the children of the
  /// <stream:features /> nonza, can be negotiated. Otherwise, returns false.
  bool matchesFeature(List<XMLNode> features) {
    return features.contains((XMLNode feature) => feature.attributes["xmlns"] == negotiatingXmlns);
  }

  /// Called with the currently received nonza [nonza] when the negotiator is active.
  /// If the negotiator is just elected to be the next one, then [nonza] is equal to
  /// the <stream:features /> nonza.
  ///
  /// Returns the next state of the negotiator. If done or retryLater is selected, then
  /// negotiator won't be called again. If retryLater is returned, then the negotiator
  /// must switch some internal state to prevent getting matched immediately again.
  /// If ready is returned, then the negotiator indicates that it is not done with
  /// negotiation.
  Future<NegotiatorState> negotiate(XMLNode nonza);

  /// Reset the negotiator to a state that negotation can happen again.
  void reset() {
    state = NegotiatorState.ready;
  }
  
  NegotiatorAttributes get attributes => _attributes;
}