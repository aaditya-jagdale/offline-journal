import 'package:flutter/material.dart';

void rightSlideTransition(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
  Function()? onComplete,
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
  ).then((_) {
    if (onComplete != null) {
      onComplete();
    }
  });
}

Future<T?> upSlideTransition<T>(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
  bool useRootNavigator = false,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
  );
}

void leftSlideTransition(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
  );
}

void downSlideTransition(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
  );
}

void scaleUpTransition(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return ScaleTransition(scale: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
  );
}

void fadeTransition(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return FadeTransition(opacity: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
  );
}

void clearAllAndPush(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  Navigator.pushAndRemoveUntil(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return FadeTransition(opacity: offsetAnimation, child: child);
      },
      transitionDuration: duration,
    ),
    (route) => false,
  );
}
