# MIAGED

Application Flutter du TP2 MIAGE. Les écrans suivent les six user stories du sujet.

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
- Inscription. Création d’un compte depuis la connexion, confirmation du mot
  de passe et vérification de la disponibilité du login.

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

**Préparation nécessaire avant le rendu.** Ces identifiants sont prévus pour les
tests. Créer les deux comptes avec **Créer un compte**, puis vérifier chaque
connexion avant de transmettre le dépôt. Leur existence dans Firebase reste à
confirmer. Si ces logins sont déjà utilisés, choisir deux autres comptes et
mettre ce tableau à jour.

## Vérifications techniques

```powershell
flutter analyze
flutter test
flutter build web --no-pub --no-wasm-dry-run
```
