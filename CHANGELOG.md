# Changelog

Historique des évolutions de PKMonitor.

---

## TODO — Roadmap

Statut : `2026.09.05` (prototype fonctionnel)

### Prochaines étapes
- [x] Mesures CPU, RAM et réseau locales
- [x] Sparkline à 200 ms avec icônes d'applications
- [x] Popover de détail et menu contextuel
- [ ] Mesure GPU native fiable
- [ ] Alertes réseau et distribution signée

---

## Releases

### [2026.09.05] - 2026-09-03
#### Changed
- Valeur numérique dessinée dans l'image avec largeur fixe réservée
- Position de la valeur paramétrable (gauche ou droite)
- Libellé de métrique plus grand et plus lisible

### [2026.09.04] - 2026-09-03
#### Added
- Fenêtre Réglages avec sections Général, Apparence et À propos
- Options persistantes de fréquence, historique, top d'applications et survol
- Options de largeur de courbe, épaisseur, taille d'icône et thème
- Contrôle du lancement à la connexion depuis les réglages

### [2026.09.03] - 2026-09-03
#### Changed
- Détection fiable du survol de la barre des menus
- Défilement des cinq applications les plus consommatrices sur la sparkline

### [2026.09.02] - 2026-09-03
#### Added
- Affichage du détail au survol sous la barre des menus
- Ouverture de Moniteur d'activité filtré par PID
- Arrêt confirmé d'un processus depuis le détail

#### Changed
- Remplacement du popover à encoche par un panneau flottant arrondi

### [2026.09.01] - 2026-09-03
#### Added
- Application macOS native dans la barre des menus
- Modes Auto, CPU, GPU, RAM et Network
- Sparkline dynamique avec pictogrammes mobiles
- Détail des applications dominantes au clic
- Lancement à la connexion et build du bundle `.app`
