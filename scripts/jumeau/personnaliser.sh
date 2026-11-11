#!/usr/bin/env bash
# Personnalise la racine du jumeau (appelé par mmdebstrap, voir
# construire-image.sh). $1 = dossier racine. Variables : JUMEAU_DEPOT
# (racine du dépôt), JUMEAU_APPLI (bundle Flutter arm64, facultatif).
set -euo pipefail

r="$1"
depot="$JUMEAU_DEPOT"

# Nos scripts système, exactement comme sur la vraie box (sans les tests).
cp -a "$depot/systeme/etc/." "$r/etc/"
cp -a "$depot/systeme/usr/." "$r/usr/"

# Ce qui ne sert qu'au jumeau : le scénario et son service.
install -d "$r/usr/lib/tele/jumeau"
install -m 0755 "$depot/scripts/jumeau/invite/tele-jumeau" "$r/usr/lib/tele/jumeau/"
install -m 0644 "$depot/scripts/jumeau/invite/scenario.py" "$r/usr/lib/tele/jumeau/"
install -m 0644 "$depot/scripts/jumeau/invite/tele-jumeau.service" "$r/etc/systemd/system/"

if [[ -n "${JUMEAU_APPLI:-}" ]]; then
  install -d "$r/opt/tele/ui"
  cp -a "$JUMEAU_APPLI/." "$r/opt/tele/ui/"
fi

# Disques : racine sur vda, /data (caches, issue #45) sur vdb.
cat >"$r/etc/fstab" <<'EOF'
/dev/vda  /      ext4  defaults          0  1
/dev/vdb  /data  ext4  defaults,nofail   0  2
EOF
install -d "$r/data" "$r/var/log/tele"
echo tele-jumeau >"$r/etc/hostname"

# Console série sans mot de passe : le jumeau sert à déboguer.
chroot "$r" passwd -d root >/dev/null
install -d "$r/etc/systemd/system/serial-getty@ttyAMA0.service.d"
cat >"$r/etc/systemd/system/serial-getty@ttyAMA0.service.d/auto.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --keep-baud 115200,57600,38400,9600 %I $TERM
EOF

# Modules utiles dès le démarrage : partages 9p (médias, résultats) et zram.
cat >"$r/etc/modules-load.d/tele-jumeau.conf" <<'EOF'
9pnet_virtio
9p
zram
EOF

chroot "$r" systemctl enable tele-memoire.service tele-entretien.timer tele-jumeau.service
# Rien à attendre du réseau dans le jumeau.
chroot "$r" systemctl mask systemd-networkd-wait-online.service >/dev/null 2>&1 || true
