import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/summary.dart';

class SharedMediaDisplay extends StatelessWidget {

  const SharedMediaDisplay(this.sharedMedia, this.jid, { Key? key }) : super(key: key);
  final List<SharedMedium> sharedMedia;
  final String jid;

  List<Widget> _renderItems() {
    final tmp = List<Widget>.empty(growable: true);

    final clampedStartIndex = sharedMedia.length >= 8 ? sharedMedia.length - 7 : 0;
    final clampedEndIndex = sharedMedia.length - 1;

    for (var i = clampedEndIndex; i >= clampedStartIndex; i--) {
      tmp.add(buildSharedMediaWidget(sharedMedia[i], jid));
    }

    if (sharedMedia.length >= 8) {
      tmp.add(SharedSummaryWidget(sharedMedia.length - 7));
    }
    
    return tmp;
  }
  
  @override
  Widget build(BuildContext context) {
    if (sharedMedia.isEmpty) return const SizedBox();

    final width = MediaQuery.of(context).size.width;
    // NOTE: Based on the formula width = 2padding + (n-1)5 + 75n,
    //       with n being the number of item to show. If we set n=4, then
    //       the padding will always be the same.
    final padding = 0.5 * (width - 15 - 300);
    
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text(
            'Shared Media',
            style: TextStyle(
              fontSize: 25,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8, left: padding, right: padding),
          child: Container(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _renderItems(),
            ),
          ),
        )
      ],
    );
  }
}
