TechshopIO
==========

Le gestionnaire de TechShop facile, pour vos évènements Mix et workshops.
Inspiré des besoins de Muséomix ce gestionnaire de techshop vous facilitera la vie lors de vos évènements Mix et workshops, dans lesquelles vous devez fournir rapidement toute sorte de matériels à toutes sortes d'équipes.
TechShopIO vous permet de tenir simplement votre stock à jour, et facilite l'opération de ré-intégration et vérification de votre matériel à a fin de l'évènement.

TechShopIO s'utilise localement sur votre poste de travail, sans avoir forcément besoin du réseau et encore moins d'une connexion internet.
L'application est capable de lire plusieurs types de codes barres via un lecteur laser.
Elle est compatible tablette et smartphone.

### Fonctionnalités
- Tout se trame sur la liste 
	Un liste simple, lisible, entière, et non paginée de votre inventaire sous les yeux !

- Entrée massive de matériel
	Une interface de chargement de fichiers aux format CSV vous confère une grande efficacité quant au chargement de votre inventaire dans TechShopIO.

- Entrées et sorties d'inventaire rapide, par lecture de codes barres.
- Association de mots clé multiple
	Ce petit back-office, vous permet de définir les noms des équipes, des emprunteurs, ou tout autre mot clé pour caratériser les matériels de votre TechShop. Ils sont associés aux matériels lors de l'opération de sortie d'inventaire.

- Recherche rapide sur la liste
	Rechercher, réduisez, sélectonnez des élements dans votre liste grâce à la recherche simple dans la page.

- Prise en charge des photos et illustrations des matériels.
	Prenez des photos de vos matériels avec vos outils mobiles et ajoutez les simplement comme illustration de vos matériels.

- Génération et impression de codes barres dans les formats standards.
	Choisissez le format de code barres parmi en grand choix de standard et gére-les comme vous le souhaitez grace au back-office "codes barres".

- compatibilité outils mobiles (tablettes et smatrphones)
	Une fois lancé sur votre poste de travail, TechShopIO génère un QR code afin que vous puissiez facilement y connecter votre outil mobile.
	Celui-ci devient alors un client de TechShopIO et vous permet de géré votre inventaire à distance, ajouter des photos, faire les entrées sorties, etc.

### installation

- Installer ruby ( https://www.ruby-lang.org/fr/documentation/installation/ )
- `git clone git@github.com:pilooz/stechshopio.git` ou télécharger le ZIP `https://github.com/Pilooz/TechShopIO/archive/master.zip`
- `bundle install`
- copier les config/\*.sample en config/\*.rb

### Démarrage de l'application
- Ouvrir une console
- ./scripts/run.sh (Linux et MacOS)
- ./scripts/run.bat (Windows)

### Arrêter l'application
- `Ctrl-C`


