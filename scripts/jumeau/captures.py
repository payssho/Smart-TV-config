#!/usr/bin/env python3
"""Fait les captures d'écran que le jumeau demande (voir scenario.py).

Le jumeau dépose capture-<profil>-<nom>.demande dans le dossier de
résultats ; on répond par une capture PNG de son écran 1080p via QMP
(screendump), puis on efface la demande.

Usage : captures.py <socket QMP> <dossier de résultats>
"""

import json
import os
import socket
import sys
import time


def qmp(chemin):
    for _ in range(300):
        try:
            s = socket.socket(socket.AF_UNIX)
            s.connect(chemin)
            break
        except OSError:
            time.sleep(0.2)
    else:
        sys.exit(f"QMP injoignable : {chemin}")
    f = s.makefile("rw")
    f.readline()  # message d'accueil

    def commande(nom, **arguments):
        f.write(json.dumps({"execute": nom, "arguments": arguments}) + "\n")
        f.flush()
        while True:
            reponse = json.loads(f.readline())
            if "return" in reponse or "error" in reponse:
                return reponse

    commande("qmp_capabilities")
    return commande


def main():
    chemin, dossier = sys.argv[1], sys.argv[2]
    commande = qmp(chemin)
    while True:
        for nom in os.listdir(dossier):
            if nom.startswith("capture-") and nom.endswith(".demande"):
                png = os.path.join(dossier, nom[: -len(".demande")] + ".png")
                reponse = commande("screendump", filename=png, format="png")
                if "error" in reponse:
                    print(f"capture ratée : {reponse['error']}", file=sys.stderr)
                os.remove(os.path.join(dossier, nom))
        time.sleep(0.5)


if __name__ == "__main__":
    try:
        main()
    except (BrokenPipeError, ConnectionResetError, json.JSONDecodeError):
        pass  # le jumeau s'est éteint
