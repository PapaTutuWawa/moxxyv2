import "dart:io";

import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/filenotfound.dart";
import "package:moxxyv2/ui/widgets/chat/download.dart";
import "package:moxxyv2/ui/widgets/chat/downloadbutton.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";

import "package:flutter/material.dart";
import "package:open_file/open_file.dart";
import "package:get_it/get_it.dart";

class ImageBaseChatWidget extends StatelessWidget {
  final String? path;
  final BorderRadius radius;
  final Widget child;
  final Widget? extra;
  final MessageBubbleBottom bottom;

  const ImageBaseChatWidget(
    this.path,
    this.radius,
    this.child,
    this.bottom,
    {
      this.extra
    }
  );

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkResponse(
        onTap: () {
          if (path != null) {
            OpenFile.open(path);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: child
            ),
            Positioned(
              bottom: 0,
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(0),
                      Colors.black12,
                      Colors.black54
                    ]
                  )
                )
              )
            ),
            ...(extra != null ? [ extra! ] : []),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: bottom
              )
            ) 
          ]
        )
      )
    );
  }
}

class ImageChatWidget extends StatelessWidget {
  final Message message;
  final String timestamp;
  final BorderRadius radius;
  final double maxWidth;
  final Widget? extra;

  const ImageChatWidget(
    this.message,
    this.timestamp,
    this.radius,
    this.maxWidth,
    {
      this.extra,
      Key? key
    }
  ) : super(key: key);

  void _requestDownload() {
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      RequestDownloadCommand(message: message),
      awaitable: false
    );
  }
  
  Widget _buildNonDownloaded() {
    if (message.thumbnailData != null) {
      final thumbnailSize = getThumbnailSize(message, maxWidth);
      return BlurhashChatWidget(
        width: thumbnailSize.width.toInt(),
        height: thumbnailSize.height.toInt(),
        borderRadius: radius,
        thumbnailData: message.thumbnailData!,
        child: DownloadButton(
          onPressed: () => _requestDownload()
        )
      );
    }

    return FileChatWidget(
      message,
      timestamp,
      extra: ElevatedButton(
        onPressed: () => _requestDownload(),
        child: const Text("Download")
      )
    );
  }

  Widget _buildDownloading() {
    if (message.thumbnailData != null) {
      final thumbnailSize = getThumbnailSize(message, maxWidth);
      return BlurhashChatWidget(
        width: thumbnailSize.width.toInt(),
        height: thumbnailSize.height.toInt(),
        borderRadius: radius,
        thumbnailData: message.thumbnailData!,
        child: DownloadProgress(id: message.id)
      );
    }

    return FileChatWidget(
      message,
      timestamp
    );
  }

  Widget _buildImage() {
    final thumbnailSize = getThumbnailSize(message, maxWidth);
    
    return Image.file(
      File(message.mediaUrl!),
      errorBuilder: (context, error, trace) {
        if (message.thumbnailData != null) {
          return BlurhashChatWidget(
            width: thumbnailSize.width.toInt(),
            height: thumbnailSize.height.toInt(),
            borderRadius: radius,
            thumbnailData: message.thumbnailData!,
            child: const FileNotFound()
          );
        } else {
          return FileChatWidget(
            message,
            timestamp,
            extra: const FileNotFound()
          );
        }
      }
    );
  }
  
  Widget _innerBuild() {
    if (!message.isDownloading && message.mediaUrl != null) return _buildImage();
    if (message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
  
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkResponse(
        onTap: () {
          // => Is the file downloaded?
          if (!message.isDownloading && message.mediaUrl != null) {
            OpenFile.open(message.mediaUrl!);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: _innerBuild()
            ),
            Positioned(
              bottom: 0,
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(0),
                      Colors.black12,
                      Colors.black54
                    ]
                  )
                )
              )
            ),
            ...(extra != null ? [ extra! ] : []),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: MessageBubbleBottom(
                  message,
                  timestamp: timestamp,
                )
              )
            ) 
          ]
        )
      )
    );
  }
}
