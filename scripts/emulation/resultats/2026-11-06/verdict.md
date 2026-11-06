Sur 4 Go, tout passe, même le pire cas après deux heures de YouTube avec le lecteur, le hub et une mise à jour en fond : il reste 1,8 Go libres.

Sur 2 Go, une soirée normale passe (930 Mo libres sous YouTube, 660 Mo dans le pire cas). Mais quand Chromium a dérivé de 600 Mo, la mémoire est pleine et le noyau tue l'onglet YouTube. L'interface, le lecteur et le hub survivent, parce que Chromium est désigné en premier pour l'OOM.

Conclusion : la HK1 4 Go est le bon choix. Une box 2 Go resterait utilisable à condition de recharger Chromium régulièrement et d'activer zram. L'interface pèse ici environ 420 Mo parce que le banc la dessine en logiciel ; sur la box, avec flutter-pi et le GPU, elle devrait peser bien moins.
