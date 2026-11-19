import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'activity_image.dart';
import 'activity_card.dart';
import 'page_intro.dart';
import 'register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MiagedApp());
}

class MiagedApp extends StatelessWidget {
  const MiagedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIAGED',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D77),
          primary: const Color(0xFF006D77),
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F6F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12343B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 72,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE0EAEA)),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF12343B),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF006D77),
          unselectedItemColor: Color(0xFF65777B),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF12343B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD5E1E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD5E1E2)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: const Color(0xFF006D77),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: const BorderSide(color: Color(0xFF9CBDBF)),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// -------------------------------------------------------------
// US#1 : LOGIN PAGE
// -------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (_isLoading) return;
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      debugPrint('[AUTH] Connexion annulée : Login ou mot de passe vide.');
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('login', isEqualTo: login)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (!mounted) return;
      if (querySnapshot.docs.isNotEmpty) {
        final userId = querySnapshot.docs.first.id;
        debugPrint('[AUTH] Connexion réussie pour $userId');

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(userId: userId),
          ),
        );
      } else {
        debugPrint('[AUTH] Échec de connexion : Identifiants incorrects.');
        setState(() {
          _errorMessage = 'Identifiants incorrects.';
        });
      }
    } catch (e) {
      debugPrint('[AUTH ERROR] Erreur Firestore : $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur est survenue lors de la connexion.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MIAGED',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageIntro(
                  icon: Icons.explore_outlined,
                  title: 'Bienvenue.',
                  subtitle: 'Connectez-vous pour découvrir les activités et préparer votre prochaine sortie.',
                ),
                TextField(
                  controller: _loginController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Login',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Se connecter'),
                      ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final login = await Navigator.of(context)
                              .push<String>(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                          if (!mounted || !context.mounted || login == null) {
                            return;
                          }
                          _loginController.text = login;
                          _passwordController.clear();
                          setState(() => _errorMessage = null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Compte créé. Vous pouvez vous connecter.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Créer un compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// NAVIGATION CONTAINER (BottomNavigationBar) - US#2 Critère #1 & #2
// -------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  final String userId;
  const MainNavigationScreen({super.key, required this.userId});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ActivitiesListScreen(userId: widget.userId),
      CartScreen(userId: widget.userId),
      ProfileScreen(
        userId: widget.userId,
        onSignOut: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (context) => const LoginPage()),
          (route) => false,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MIAGED',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: IndexedStack(index: _currentIndex, children: pages),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Activités',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Panier',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// US#2 : LISTE DES ACTIVITÉS
// -------------------------------------------------------------
class ActivitiesListScreen extends StatefulWidget {
  final String userId;
  const ActivitiesListScreen({super.key, required this.userId});

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  late final _activities = FirebaseFirestore.instance
      .collection('activities')
      .snapshots();
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _activities,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Chargement des activités impossible : ${snapshot.error}');
          return const Center(
            child: Text('Impossible de charger les activités.'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Aucune activité disponible pour le moment.'),
          );
        }

        final documents = snapshot.data!.docs;
        final categories =
            documents
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['category']?.toString().trim() ?? '';
                })
                .where((category) => category.isNotEmpty)
                .toSet()
                .toList()
              ..sort(
                (first, second) =>
                    first.toLowerCase().compareTo(second.toLowerCase()),
              );

        // Une catégorie supprimée de la base ne doit pas masquer la liste.
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }

        final activities = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final searchable =
              '${data['title'] ?? ''} ${data['location'] ?? ''} ${data['category'] ?? ''}'
                  .toLowerCase();
          final category = data['category']?.toString().trim() ?? '';
          return (_selectedCategory == null || category == _selectedCategory) &&
              searchable.contains(_search);
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Découvrez votre prochaine activité.',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Un moment pour bouger, créer ou explorer.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher une activité',
                        hintText: 'Titre, lieu ou catégorie',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) =>
                          setState(() => _search = value.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes les catégories'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                        for (final category in categories)
                          ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) => setState(
                              () => _selectedCategory = selected
                                  ? category
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${activities.length} résultat(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (activities.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucune activité ne correspond à votre recherche.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 620 ? 2 : 1;
                    final textGrowth =
                        MediaQuery.textScalerOf(context).scale(16) - 16;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 365 + textGrowth * 7,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = activities[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title']?.toString() ?? 'Sans titre';
                        final location =
                            data['location']?.toString() ?? 'Lieu non spécifié';
                        final category =
                            data['category']?.toString() ?? 'Non renseignée';
                        final price = data['price'] ?? 0;
                        final imageUrl = data['imageUrl']?.toString() ?? '';
                        return ActivityCard(
                          title: title,
                          location: location,
                          category: category,
                          price: price,
                          imageUrl: imageUrl,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => ActivityDetailScreen(
                                cartItem: userCart(widget.userId).doc(doc.id),
                                title: title,
                                location: location,
                                price: price,
                                imageUrl: imageUrl,
                                category: category,
                                maxParticipants:
                                    data['maxParticipants']?.toString() ??
                                    'Non renseigné',
                              ),
                            ),
                          ),
                        );
                      }, childCount: activities.length),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class ActivityDetailScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> cartItem;
  final String title;
  final String location;
  final Object price;
  final String imageUrl;
  final String category;
  final String maxParticipants;

  const ActivityDetailScreen({
    super.key,
    required this.cartItem,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.maxParticipants,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    String message;
    try {
      await widget.cartItem.set({
        'title': widget.title,
        'location': widget.location,
        'price': widget.price,
        'imageUrl': widget.imageUrl,
      });
      message = 'Activité ajoutée au panier.';
    } catch (error) {
      debugPrint('Ajout au panier impossible : $error');
      message = 'Impossible d’ajouter cette activité au panier.';
    }
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’activité')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image(
                  image: activityImage(widget.imageUrl),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ListTile(
                title: const Text('Catégorie'),
                subtitle: Text(widget.category),
              ),
              ListTile(
                title: const Text('Lieu'),
                subtitle: Text(widget.location),
              ),
              ListTile(
                title: const Text('Nombre maximum de personnes'),
                subtitle: Text(widget.maxParticipants),
              ),
              ListTile(
                title: const Text('Prix'),
                subtitle: Text('${widget.price} €'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _adding ? null : _addToCart,
                child: Text(_adding ? 'Ajout en cours…' : 'Ajouter au panier'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
