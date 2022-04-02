import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/service/data.dart";
import "package:moxxyv2/ui/widgets/chat/gradient.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";

import "package:flutter/material.dart";
import "package:path/path.dart" as pathlib;
import "package:get_it/get_it.dart";
import "package:video_compress/video_compress.dart";
import "package:open_file/open_file.dart";

class VideoChatWidget extends StatefulWidget {
  final Message message;
  final double maxWidth;
  final BorderRadius radius;

  const VideoChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    {
      Key? key
    }
  ) : super(key: key);

  // ignore: no_logic_in_create_state
  @override
  _VideoChatWidgetState createState() => _VideoChatWidgetState(
    message,
    maxWidth,
    radius,
  );
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  final BorderRadius radius;
  final double maxWidth;
  final Message message;

  _VideoChatWidgetState(
    this.message,
    this.maxWidth,
    this.radius,
  );

  /// Generate the thumbnail if needed.
  Future<bool> _thumbnailFuture() async {
    final thumbnail = GetIt.I.get<UIDataService>().getThumbnailPath(message);
    final thumbnailFile = File(thumbnail);
    if (await thumbnailFile.exists()) {
      return true;
    }

    // Thumbnail does not exist
    final sourceFile = File(message.mediaUrl!);
    if (await sourceFile.exists()) {
      final bytes = await VideoCompress.getByteThumbnail(
        sourceFile.path,
        quality: 75
      );
      if (bytes == null) return false;
      await thumbnailFile.writeAsBytes(bytes);

      return true;
    }

    // Source file also does not exist. Return "error".
    return false;
  }
  
  Widget _buildNonDownloaded() {
    // TODO
    if (message.thumbnailData != null) {}

    return FileChatWidget(
      message,
      extra: ElevatedButton(
        onPressed: () => requestMediaDownload(message),
        child: const Text("Download")
      )
    );
  }

  Widget _buildDownloading() {
    // TODO
    if (message.thumbnailData != null) {}

    return FileChatWidget(message);
  }

  Widget _buildVideo() {
    return FutureBuilder<bool>(
      future: _thumbnailFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data!) {
            final thumbnail = GetIt.I.get<UIDataService>().getThumbnailPath(message);
            return ImageBaseChatWidget(
              message.mediaUrl!,
              radius,
              Image.file(File(thumbnail)),
              MessageBubbleBottom(message),
              extra: const PlayButton()
            );
          } else {
            // TODO: Error
            return const Text("Error");
          }
        } else {
          return const CircularProgressIndicator();
        }
      }
    );
  }

  Widget _innerBuild() {
    if (!message.isDownloading && message.mediaUrl != null) return _buildVideo();
    if (message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
  
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkWell(
        onTap: () {
          OpenFile.open(message.mediaUrl!);
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: radius,
              child: _innerBuild()
            ),
            BottomGradient(radius),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: MessageBubbleBottom(message)
              )
            ) 
          ]
        )
      )
    );
  }
}
