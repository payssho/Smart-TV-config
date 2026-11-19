import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Dessine toujours sur 1280 × 720 logiques puis met à l'échelle de l'écran
/// réel : le projecteur, les tests et un émulateur affichent la même page.
class Echelle extends StatelessWidget {
  const Echelle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Veilleuse.nuit,
      child: Center(
        child: FittedBox(
          child: SizedBox(
            width: Veilleuse.largeurEcran,
            height: Veilleuse.hauteurEcran,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(
                  Veilleuse.largeurEcran,
                  Veilleuse.hauteurEcran,
                ),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                textScaler: TextScaler.noScaling,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
