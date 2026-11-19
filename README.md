# MIAGED

Application Flutter du TP2 MIAGE. La branche `main` est consacrée aux six
user stories du sujet. La branche `upgraded-version` regroupe les compléments
(inscription, recherche, filtres par catégorie et assistance Ollama).
Les deux branches partagent le même style visuel.

## Lancement

Depuis ce dossier, exécuter les commandes suivantes.

```powershell
flutter pub get
flutter run -d chrome
```

Après une modification de `web/activity_classifier.js`, arrêter le lancement
avec `q`, puis relancer l’application pour recharger le JavaScript.

## Fonctionnalités du TP

- US #1. Connexion avec vérification du login et du password dans Firestore.
- US #2. Liste des activités et navigation Activités, Panier, Profil.
- US #3. Détail et ajout de l’activité au panier de l’utilisateur.
- US #4. Panier, total et suppression par la croix.
- US #5. Profil modifiable, login en lecture seule et déconnexion.
- US #6. Ajout depuis le profil, catégorie déduite de l’image et sauvegarde.

## Vérification manuelle

Se connecter avec un utilisateur existant. Ouvrir une activité, l’ajouter au panier,
vérifier son prix dans le total, puis la retirer. Modifier la ville du profil et
valider. Après déconnexion et reconnexion, vérifier que la ville a été conservée.

Dans Profil → Ajouter une activité, sélectionner une image JPEG, PNG ou WebP,
ou coller un lien HTTPS direct public. Attendre la catégorie, compléter le titre,
le lieu, le nombre maximum de personnes et le prix, puis valider.
Vérifier la nouvelle activité dans la liste et dans sa fiche.

Le prix du formulaire accepte uniquement les chiffres, conformément au sujet.
La catégorie est calculée à partir de l’image et reste en lecture seule.

## Images et classification

La classification fonctionne actuellement dans Chrome, avec Transformers.js
3.8.1 et le modèle Xenova/clip-vit-base-patch32. La bibliothèque et les poids sont
téléchargés au premier usage, puis la classification s’exécute dans le navigateur.
Prévoir une connexion Internet au premier lancement.

Le fichier est limité à 10 Mo et redimensionné à 640 pixels sur son plus grand
côté. L’image JPEG est enregistrée dans le document Firestore avec les autres
champs. Un site peut bloquer l’import par lien depuis le navigateur.
Dans ce cas, télécharger l’image et importer le fichier.

Sources de la partie IA.
- https://huggingface.co/Xenova/clip-vit-base-patch32
- https://huggingface.co/docs/transformers.js

## Activités et photos de démonstration

Quatre activités fictives ont été ajoutées dans la collection Firestore
`activities`, avec des photos générées par IA. Les lieux, prix et capacités
ont été choisis pour la démonstration du TP.

| Activité | Catégorie | Prix | Personnes maximum | Photo |
| --- | --- | --- | --- | --- |
| Randonnée découverte | Plein air | 15 € | 12 | [Randonnée](images/activities/randonnee.jpg) |
| Yoga au parc | Sport | 12 € | 10 | [Yoga](images/activities/yoga.jpg) |
| Atelier pâtes fraîches | Gastronomie | 35 € | 8 | [Cuisine](images/activities/cuisine.jpg) |
| Initiation à la peinture | Culture | 25 € | 10 | [Peinture](images/activities/peinture.jpg) |

Les photos sont incluses dans le dépôt pour tester la classification via
**Profil → Ajouter une activité → Choisir une image**. Les catégories du tableau
sont celles prévues pour le catalogue. Les prédictions du modèle peuvent varier.

## Données Firestore

- `users/{userId}` contient `login`, `password`, `birthday` (JJ/MM/AAAA),
  `address`, `postalCode` et `city`.
- `activities/{activityId}` contient `imageUrl`, `title`, `category`,
  `location`, `maxParticipants` et `price`.
- `users/{userId}/cart/{activityId}` contient la copie de l’activité ajoutée.
  Une activité apparaît une fois dans le panier.

Les règles de la base doivent autoriser les lectures et écritures nécessaires.

## Comptes pour le rendu

| Login | Password |
| --- | --- |
| testmiage1 | MiageTest1! |
| testmiage2 | MiageTest2! |

Ces deux couples login/password n’ont pas été retrouvés lors de la vérification
de Firebase. Avant le rendu, créer ces comptes dans la collection `users`
ou depuis l’inscription de la branche `upgraded-version`, puis tester chaque
connexion. Si d’autres comptes de test sont utilisés, mettre le tableau à jour.

## Vérifications techniques

```powershell
flutter analyze
flutter test
flutter build web --no-pub --no-wasm-dry-run
```
