import 'package:flutter/material.dart';

class SwipeController extends StatefulWidget {
  final List<Widget> pages;

  const SwipeController({super.key, required this.pages});

  @override
  State<SwipeController> createState() => _SwipeControllerState();
}

class _SwipeControllerState extends State<SwipeController> {
  final PageController _controller = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0, // only allow closing when on first page
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_controller.page != null && _controller.page! > 0) {
            _controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          children: widget.pages,
        ),
      ),
    );
  }
}
