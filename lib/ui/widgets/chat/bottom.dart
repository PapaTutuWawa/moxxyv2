import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';

class MessageBubbleBottom extends StatefulWidget {

  const MessageBubbleBottom(this.message, { Key? key }): super(key: key);
  final Message message;

  @override
  MessageBubbleBottomState createState() => MessageBubbleBottomState();
}

class MessageBubbleBottomState extends State<MessageBubbleBottom> {
  late String _timestampString;
  late Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    // Different name for now to prevent possible shadowing issues
    final _now = DateTime.now().millisecondsSinceEpoch;
    _timestampString = formatMessageTimestamp(widget.message.timestamp, _now);

    // Only start the timer if neccessary
    if (_now - widget.message.timestamp <= 15 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        setState(() {
          final now = DateTime.now().millisecondsSinceEpoch;
          _timestampString = formatMessageTimestamp(widget.message.timestamp, now);

          if (now - widget.message.timestamp > 15 * Duration.millisecondsPerMinute) {
            _updateTimer!.cancel();
          }
        });
      });
    } else {
      _updateTimer = null;
    }   
  }
  
  @override
  void dispose() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }
    
    super.dispose();
  }

  bool _showBlueCheckmarks() {
    return widget.message.sent &&
            widget.message.displayed as bool;
  }

  bool _showCheckmarks() {
    return widget.message.sent &&
            widget.message.received as bool &&
            !(widget.message.displayed as bool);
  }

  bool _showCheckmark() {
    return widget.message.sent &&
            widget.message.acked as bool &&
            !(widget.message.received as bool) &&
            !(widget.message.displayed as bool);
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            _timestampString,
            style: const TextStyle(
              fontSize: fontsizeSubbody,
              color: Color(0xffddfdfd),
            ),
          ),
        ),
        ..._showCheckmark() ? [
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(
                Icons.done,
                size: fontsizeSubbody * 2,
              ),
            ),
          ] : [],
        ..._showCheckmarks() ? [
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2,
              ),
            ),
          ] : [],
        ..._showBlueCheckmarks() ? [
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2,
                color: Colors.blue.shade700,
              ),
            ),
          ] : [],
      ],
    );
  }
}
