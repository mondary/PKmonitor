# Landing PK Monitor

**À déployer : uniquement `store/index.html`.** La page embarque sa police,
ses captures, ses icônes, son CSS, son JavaScript et son extrait vidéo réel.
Elle ne nécessite ni serveur applicatif, ni dépendance à installer, ni CDN.

Les liens de téléchargement ont un repli statique vers le DMG public vérifié.
Une requête optionnelle à l’API GitHub actualise le tag, le DMG et la taille.
Si l’API est indisponible, les liens et toute la page restent fonctionnels.
Au 24 septembre 2026, la version locale est 2026.09.39 et la dernière release
publique est 2026.09.32. La publication V39 est un chantier distinct.

## Modifier la page

- Texte, présentation et interactions : `index.template.html`.
- Métadonnées de la release de secours : `release.json`.
- Commande d’installation sans Homebrew : `install-command.sh`.
- Médias : `assets/`, `../assets/app-icons/`, `../videos/pkmonitor-landing.mp4`.

Puis lancer, depuis la racine du dépôt :

```sh
python3 store/landing/build.py
```

La vidéo est un extrait rapproché de 6 secondes de l’enregistrement CleanShot
existant du 14 septembre. Les démonstrations HTML portent la mention « données
d’exemple » ou « démonstration » ; elles ne surveillent pas l’ordinateur du visiteur.
Les anciens fichiers de présentation sont conservés.
