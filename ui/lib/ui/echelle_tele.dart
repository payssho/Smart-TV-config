import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Dessine toujours l'interface sur une surface de 1920 × 1080 logiques, puis
/// la met à l'échelle de l'écran réel. La prévisualisation web, les tests et
/// la télé affichent ainsi exactement la même mise en page.
class EchelleTele extends StatelessWidget {
  const EchelleTele({super.key, required this.child});

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
                // La taille du texte est fixée par le thème, pas par l'OS.
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
