# Changelog

Historique des évolutions de PKMonitor.

---

## TODO — Roadmap

Statut : `2026.09.14` (prototype fonctionnel)

### Prochaines étapes
- [x] Mesures CPU, RAM et réseau locales
- [x] Sparkline à 200 ms avec icônes d'applications
- [x] Popover de détail et menu contextuel
- [ ] Mesure GPU native fiable
- [ ] Alertes réseau et distribution signée
- [ ] Déport d'icônes tierces dans la seconde barre (type Bartender/Ice : permission Accessibilité + APIs privées, restauration des positions à la sortie)

---

## Releases

### [2026.09.14] - 2026-09-04
#### Added
- Emplacement de l'icône au choix : menu barre ou « Second Bar », une pilule dynamique dessinée juste sous la barre système, à droite (style Bartender, limitée à PKMonitor)
- Seconde barre personnalisable : 4 modes de fond (None, Tint, Hover = blur au survol, Blur permanent), couleur de fond libre (ColorPicker avec opacité), marges réglables sur les 4 côtés (la taille de la pilule s'y adapte), contenu clair/sombre/auto
#### Fixed
- Lisibilité de la seconde barre : le contenu suivait une apparence fixe (texte noir sur fond sombre) ; il suit désormais le système ou le réglage dédié
- `appBundlePath` renvoyait un slash final, cassant la détection du PID principal des applications
- Self-test remis en ordre (unités françaises, comparaison flottante tolérante)

### [2026.09.13] - 2026-09-03
#### Changed
- Réglages restructurés en 5 sections : General, Sparkline, Gauges, Panel, About
- Valeurs absolues affichées dans le panneau de détail (cores, Go)
- Aperçu visuel des jauges et de la disposition dans les réglages

### [2026.09.12] - 2026-09-03
#### Added
- Valeurs absolues pour CPU (cores), RAM (Go utilisés) et réseau (débit)
- Option pour afficher/masquer les valeurs absolues
- Couleurs sur le détail réseau (bleu download, orange upload)
- Détail réseau affiché verticalement

### [2026.09.11] - 2026-09-03
#### Changed
- Le panneau reste ouvert après un arrêt ou force kill
- README FR/EN restructurés selon la convention PK

### [2026.09.10] - 2026-09-03
#### Added
- Bouton force kill (SIGKILL) pour les processus qui ne quittent pas
- Jauge réseau splitée download/upload
- Option de bordure sur les icônes d'applications

### [2026.09.09] - 2026-09-03
#### Added
- Position des jauges paramétrable (gauche/droite)
- Libellés des jauges affichables/masquables
- Position du libellé vertical paramétrable (gauche/droite)
- Libellé vertical affichable/masquable

### [2026.09.08] - 2026-09-03
#### Added
- Seuils de couleur configurables (warning orange, critical rouge)
- Couleur appliquée à la valeur et aux jauges

#### Fixed
- Espacement vertical des libellés de métrique

### [2026.09.07] - 2026-09-03
#### Added
- Quatre jauges cliquables (GPU, CPU, RAM, NET) à droite de la sparkline
- Basculement de métrique par clic sur une jauge
- Option pour afficher/masquer les jauges dans les réglages

### [2026.09.06] - 2026-09-03
#### Added
- Mesure GPU via IOKit (IOAccelerator PerformanceStatistics)

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
