import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../systeme/medias.dart';
import '../systeme/son.dart';
import '../ui/theme.dart';

/// Vidéo et image du feu : un vrai feu filmé (crédits dans
/// assets/CREDITS.md, CC BY 3.0).
abstract final class MediasFeu {
  static const video = 'assets/videos/feu.mp4';
  static const affiche = 'assets/images/feu-affiche.jpg';
  static const son = 'assets/sons/feu.mp3';
  static const credit = 'Vidéo : free video library, CC BY 3.0';
}

/// « Feu de cheminée » : un vrai feu filmé en plein écran, avec un vrai
/// crépitement enregistré. OK coupe ou remet le son, Retour quitte.
class EcranFeu extends StatefulWidget {
  const EcranFeu({super.key});

  static Route<void> route() => PageRouteBuilder(
    pageBuilder: (_, _, _) => const EcranFeu(),
    transitionDuration: Durations.extralong4,
    reverseTransitionDuration: Durations.long2,
    transitionsBuilder: (_, animation, _, enfant) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Easing.standard),
      child: enfant,
    ),
  );

  @override
  State<EcranFeu> createState() => _EcranFeuState();
}

class _EcranFeuState extends State<EcranFeu> {
  VideoPlayerController? _video;
  final _son = BoucleSonore(MediasFeu.son);
  bool _sonActif = true;
  bool _sonBloque = false;
  bool _indicationsVisibles = true;
  Timer? _masquer;

  @override
  void initState() {
    super.initState();
    if (Medias.actifs) _lancerVideo();
    _lancerSon();
    _programmerMasquage(const Duration(seconds: 5));
  }

  Future<void> _lancerVideo() async {
    // Muette : le son vient de la boucle enregistrée, plus longue que la
    // vidéo, ce qui évite d'entendre la reprise.
    final video = VideoPlayerController.asset(
      MediasFeu.video,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await video.initialize();
      await video.setVolume(0);
      await video.setLooping(true);
      await video.play();
      if (mounted) {
        setState(() => _video = video);
      } else {
        await video.dispose();
      }
    } catch (_) {
      await video.dispose();
    }
  }

  Future<void> _lancerSon() async {
    final joue = await _son.jouer();
    if (mounted) setState(() => _sonBloque = !joue && _son.disponible);
  }

  void _programmerMasquage(Duration apres) {
    _masquer?.cancel();
    _masquer = Timer(apres, () {
      if (mounted) setState(() => _indicationsVisibles = false);
    });
  }

  void _basculerSon() {
    if (_sonBloque && _sonActif) {
      _lancerSon();
      return;
    }
    setState(() {
      _sonActif = !_sonActif;
      _indicationsVisibles = true;
    });
    _sonActif ? _lancerSon() : _son.arreter();
    _programmerMasquage(const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _masquer?.cancel();
    _son.arreter();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final video = _video;
    final icone = !_son.disponible || !_sonActif || _sonBloque
        ? Icons.volume_off_rounded
        : Icons.volume_up_rounded;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _basculerSon();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _basculerSon,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // L'image fixe tient la place pendant que la vidéo charge.
                Image.asset(MediasFeu.affiche, fit: BoxFit.cover),
                if (video != null)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: video.value.size.width,
                      height: video.value.size.height,
                      child: VideoPlayer(video),
                    ),
                  ),
                // Vignette : la pièce s'efface, il ne reste que le foyer.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.25),
                      radius: 1.05,
                      colors: [Colors.transparent, Color(0xD9000000)],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: Veilleuse.margeSure.left,
                  right: Veilleuse.margeSure.right,
                  bottom: Veilleuse.margeSure.bottom,
                  child: AnimatedOpacity(
                    opacity: _indicationsVisibles || _sonBloque ? 1 : 0,
                    duration: Durations.long4,
                    curve: Easing.standard,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(icone, size: 44, color: Veilleuse.lin),
                        if (_sonBloque) ...[
                          const SizedBox(width: 16),
                          Text('Cliquez pour le son', style: textes.bodyLarge),
                        ],
                        const Spacer(),
                        Text(
                          MediasFeu.credit,
                          style: textes.bodyLarge?.copyWith(
                            fontSize: 20,
                            color: Veilleuse.brume.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
