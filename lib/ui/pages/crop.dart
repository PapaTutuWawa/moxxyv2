import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';

class CropPage extends StatelessWidget {

  CropPage({ Key? key }) : _controller = CropController(), super(key: key);
  final CropController _controller;
 
  // ignore: implicit_dynamic_type
  static MaterialPageRoute get route => MaterialPageRoute(builder: (_) => CropPage());
  
  Widget _buildImageBody(BuildContext context, CropState state) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Crop(
            image: state.image!,
            controller: _controller,
            onCropped: (image) {
              context.read<CropBloc>().add(ImageCroppedEvent(image));
            },
            aspectRatio: 1,
            withCircleUi: true,
            initialSize: 0.8,
            baseColor: Colors.black,
          ),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Material(
            color: const Color.fromRGBO(0, 0, 0, 0),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                size: 32,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: const Color.fromRGBO(0, 0, 0, 0),
                child: InkWell(
                  onTap: _controller.crop,
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLoadingBody() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CropBloc, CropState>(
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            context.read<CropBloc>().add(ResetImageEvent());
            return true;
          },
          child: SafeArea(
            child: state.image != null ? _buildImageBody(context, state) : _buildLoadingBody(),
          ),
        );
      },
    );
  }
}
