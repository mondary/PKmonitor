# Changelog

Historique des évolutions de PKMonitor.

---

## TODO — Roadmap

Statut : `2026.09.21` (prototype fonctionnel)

### Prochaines étapes
- [x] Mesures CPU, RAM et réseau locales
- [x] Sparkline à 200 ms avec icônes d'applications
- [x] Popover de détail et menu contextuel
- [ ] Mesure GPU native fiable
- [ ] Alertes réseau et distribution signée
- [x] Déport d'icônes tierces dans la seconde barre (type Bartender/Ice : permission Accessibilité + APIs privées, restauration des positions à la sortie)

---

## Releases

### [2026.09.21] - 2026-09-04
#### Added
- Module disque autonome hors des jauges : valeur lisible (taille de police réglable 8–14 pt), position gauche/droite du bandeau, choix Libre vs Disponible (inclut l'espace purgeable APFS), total masquable, module cliquable comme les jauges
- Carte Settings « Disk Module » dans General

#### Changed
- Le disque n'apparaît plus dans la liste et l'ordre des jauges

### [2026.09.20] - 2026-09-04
#### Changed
- Pages About et Help & Support refaites au style Vorssaint (PKwindowsManagement) : About centré avec lettre personnelle et pied de page liens/licence, Support avec carte café et liste de liens
- Flag `--settings` au lancement pour ouvrir directement les réglages (captures et tests)

#### Fixed
- Énumération des icônes de la menu barre sur macOS récent : `AXExtrasMenuBar` renvoie un conteneur unique dont les enfants sont les items (la liste Menu Bar Items restait vide)
- Store complet selon la convention : bannière `store/assets/banner-1544x500.png` en tête des README FR/EN, captures 02 et 04 en retina, laius store à jour (tags, FAQ)

### [2026.09.19] - 2026-09-04
#### Added
- Project Library repensée : carte vedette PKMonitor avec capture en fondu, cartes avec zone média (screenshot réel ou dégradé + grand picto) et badge de plateforme
- Captures d'écran officielles dans `store/screenshots/` et intégration en tête des README FR/EN
- Screenshots des projets PK intégrés au bundle (`ProjectScreenshots/`)

#### Fixed
- Rendu de l'icône lissé partout (pré-rendu carré haute interpolation) : sidebar, page About, bibliothèque
- Ligne About de la sidebar avec le symbole SF standard au lieu de l'icône de l'app

### [2026.09.18] - 2026-09-04
#### Added
- Icônes des autres applications descendues dans la seconde barre, à la Bartender : énumération via Accessibilité, parc des icônes d'origine hors écran, capture d'image et clic transféré vers le menu d'origine
- Page Settings « Menu Bar Items » : cases à cocher pour choisir les icônes à descendre, réordonnancement par glisser-déposer, aides à l'octroi des permissions Accessibilité et Enregistrement d'écran
- Bouton réglages dans le panneau de survol du détail

#### Changed
- La seconde barre s'affiche désormais dès qu'une icône est descendue, même si la pilule PKMonitor reste dans la barre des menus
- Restauration automatique des icônes d'origine au décochage ou à la fermeture de PKMonitor

### [2026.09.17] - 2026-09-04
#### Added
- Bibliothèque de projets avec les icônes officielles récupérées depuis les dépôts GitHub
- Descriptions et liens directs pour les applications macOS et extensions Chrome récentes
- Icône officielle `icon.png` utilisée dans la sidebar Settings et la page About

#### Changed
- Assets des projets intégrés au bundle de production

#### Fixed
- Suppression des pictogrammes SF Symbols génériques dans la bibliothèque de projets

### [2026.09.16] - 2026-09-04
#### Added
- Navigation des réglages inspirée de Vorssaint : catégories, recherche, aide et bibliothèque de projets
- Module Disque en deux lignes dans la barre des menus : capacité totale en rouge et espace libre en bleu
- Toggles d’activation dans les en-têtes Sparkline, Gauges et Panel

#### Changed
- README FR/EN et documentation store synchronisés avec les fonctionnalités livrées

### [2026.09.15] - 2026-09-04
#### Added
- Noms d'applications cliquables dans le panneau de détail (affiche toutes les fenêtres de l'app)
- Numéro de version affiché discrètement en bas du panneau de détail
- Largeur des jauges réglable (10–28 pt) dans les réglages
- Jauge réseau centre-zéro : download (bleu) vers le bas, upload (orange) vers le haut
- Lettres identifiant chaque jauge en bas (G/C/R/N)
#### Changed
- Toutes les jauges sont maintenant toujours colorées selon leurs seuils, pas seulement la jauge active
- Clic gauche sur l'icône force l'affichage du détail sans épinglage (le panneau se ferme automatiquement au survol sortant)
#### Fixed
- Calcul RAM corrigé : utilise désormais la formule macOS standard (app memory + wired + compressed) au lieu de active + wired + compressed
- `appBundlePath` renvoyait un slash final, cassant la détection du PID principal des applications
- Self-test remis en ordre (unités françaises, comparaison flottante tolérante)

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
