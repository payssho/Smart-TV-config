import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Surface qui prend le focus à la croix, le montre de loin (bord ambre,
/// légère avance) et s'active avec OK (ADR 0009).
class Tuile extends StatefulWidget {
  const Tuile({
    super.key,
    required this.child,
    required this.onActive,
    this.onFocus,
    this.autofocus = false,
    this.focusNode,
    this.largeur,
    this.hauteur,
    this.padding = const EdgeInsets.all(16),
    this.fond = Veilleuse.ardoise,
    this.libelle,
  });

  final Widget child;
  final VoidCallback onActive;
  final ValueChanged<bool>? onFocus;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? largeur;
  final double? hauteur;
  final EdgeInsets padding;
  final Color fond;

  /// Nom lu par TalkBack et utilisé par les tests.
  final String? libelle;

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
      label: widget.libelle,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
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
          onTap: widget.onActive,
          child: AnimatedScale(
            scale: _focus ? 1.06 : 1,
            duration: duree,
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: duree,
              width: widget.largeur,
              height: widget.hauteur,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _focus ? Veilleuse.ardoiseClaire : widget.fond,
                borderRadius: BorderRadius.circular(Veilleuse.rayonTuile),
                border: Border.all(
                  color: _focus ? Veilleuse.ambre : Colors.transparent,
                  width: 3,
                ),
                boxShadow: _focus
                    ? [
                        BoxShadow(
                          color: Veilleuse.ambre.withValues(alpha: 0.28),
                          blurRadius: 24,
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
