import 'package:flutter/material.dart';

import 'theme.dart';

/// Brique de base de la navigation à la croix : une surface qui prend le
/// focus, le montre de loin (halo ambre, légère avance) et s'active avec OK.
class Tuile extends StatefulWidget {
  const Tuile({
    super.key,
    required this.child,
    required this.onActive,
    this.onFocus,
    this.autofocus = false,
    this.largeur,
    this.hauteur,
    this.rayon = Veilleuse.rayonTuile,
    this.padding = const EdgeInsets.all(28),
    this.fond = Veilleuse.ardoise,
    this.libelleSemantique,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback onActive;
  final ValueChanged<bool>? onFocus;
  final bool autofocus;
  final double? largeur;
  final double? hauteur;
  final double rayon;
  final EdgeInsets padding;
  final Color fond;
  final String? libelleSemantique;
  final FocusNode? focusNode;

  @override
  State<Tuile> createState() => _TuileState();
}

class _TuileState extends State<Tuile> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final duree = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Veilleuse.dureeFocus;
    return Semantics(
      button: true,
      label: widget.libelleSemantique,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: SystemMouseCursors.basic,
        onFocusChange: (focus) {
          setState(() => _focus = focus);
          widget.onFocus?.call(focus);
          if (focus) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: duree,
              alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            );
          }
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onActive();
              return null;
            },
          ),
        },
        child: GestureDetector(
          // Clic ou toucher : pratique dans la prévisualisation, jamais requis.
          onTap: widget.onActive,
          child: AnimatedScale(
            scale: _focus ? 1.06 : 1,
            duration: duree,
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: duree,
              curve: Curves.easeOutCubic,
              width: widget.largeur,
              height: widget.hauteur,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _focus ? Veilleuse.ardoiseClaire : widget.fond,
                borderRadius: BorderRadius.circular(widget.rayon),
                border: Border.all(
                  color: _focus ? Veilleuse.ambre : Colors.transparent,
                  width: 4,
                ),
                boxShadow: _focus
                    ? [
                        BoxShadow(
                          color: Veilleuse.ambre.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ]
                    : const [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
