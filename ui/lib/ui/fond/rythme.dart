import 'dart:math' as math;

/// Le temps des fonds : tout ce qui bouge se referme sur la boucle.
///
/// Les fonds tournent sur une boucle de deux minutes ([t] va de 0 à 1). Pour
/// que la reprise ne se voie jamais, chaque mouvement est une fonction
/// périodique de `t` : un nombre entier de cycles, ou un bruit dont le
/// treillis se replie sur lui-même.
const tour = 2 * math.pi;

/// Tirage reproductible dans [0, 1[ pour l'entier [n].
double hasard(int n, [int graine = 0]) {
  final s = math.sin(n * 12.9898 + graine * 78.233 + 1.3) * 43758.5453;
  return s - s.floorToDouble();
}

/// Marche lisse de 0 à 1 entre [a] et [b].
double lisse(double a, double b, double x) {
  final u = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return u * u * (3 - 2 * u);
}

/// Bruit de gradient à une dimension, entre −1 et 1 environ, qui se répète
/// tous les [periode] pas : `bruit(t * n, n)` boucle sans couture sur `t`.
///
/// C'est lui qui donne les mouvements organiques (flânerie d'une luciole,
/// vacillement du foyer) là où une sinusoïde paraîtrait mécanique.
double bruit(double x, int periode, [int graine = 0]) {
  final i = x.floor();
  final f = x - i;
  final ga = hasard(i % periode, graine) * 2 - 1;
  final gb = hasard((i + 1) % periode, graine) * 2 - 1;
  final s = f * f * f * (f * (f * 6 - 15) + 10);
  return 2.2 * (ga * f * (1 - s) + gb * (f - 1) * s);
}

/// Éclat d'une luciole sur un cycle ([u] de 0 à 1) : elle s'allume vite,
/// s'éteint lentement, puis reste dans le noir.
double eclat(double u) {
  const montee = 0.04;
  if (u < montee) return lisse(0, montee, u);
  final d = u - montee;
  if (d > 0.56) return 0;
  return math.exp(-d / 0.13) * (1 - lisse(0.4, 0.56, d));
}

/// Mélange deux couleurs 0xRRVVBB.
int melange(int a, int b, double t) {
  final u = t.clamp(0.0, 1.0);
  int voie(int d) {
    final x = (a >> d) & 0xFF;
    final y = (b >> d) & 0xFF;
    return (x + (y - x) * u).round();
  }

  return (voie(16) << 16) | (voie(8) << 8) | voie(0);
}
