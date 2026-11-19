import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'activity_image.dart';
import 'page_intro.dart';

CollectionReference<Map<String, dynamic>> userCart(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cart');
}

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final _cartUpdates = userCart(widget.userId).snapshots();
  final _removing = <String>{};

  Future<void> _remove(DocumentReference<Map<String, dynamic>> item) async {
    if (!_removing.add(item.id)) return;
    setState(() {});
    try {
      await item.delete();
    } catch (error) {
      debugPrint('Retrait du panier impossible : $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de retirer cette activité.')),
      );
    } finally {
      if (mounted) setState(() => _removing.remove(item.id));
    }
  }

  int _priceInCents(Object? value) {
    final price = num.tryParse(value.toString().replaceAll(',', '.'));
    if (price == null || !price.isFinite) return 0;
    return (price * 100).round();
  }

  String _formatPrice(int cents) {
    return '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _cartUpdates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Impossible de charger le panier.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs;
        final total = items.fold<int>(
          0,
          (totalCents, item) =>
              totalCents + _priceInCents(item.data()['price']),
        );

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: PageIntro(
                icon: Icons.shopping_basket_outlined,
                title: 'Mon panier',
                subtitle:
                    'Vérifiez vos activités et le total de votre sélection.',
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Votre panier est vide.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final data = item.data();
                        final title = data['title']?.toString() ?? 'Sans titre';
                        return Card(
                          child: ListTile(
                            leading: Image(
                              image: activityImage(
                                data['imageUrl']?.toString() ?? '',
                              ),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(
                                    width: 56,
                                    child: Icon(Icons.broken_image),
                                  ),
                            ),
                            title: Text(title),
                            subtitle: Text(
                              '${data['location'] ?? 'Lieu non spécifié'}\n'
                              '${_formatPrice(_priceInCents(data['price']))}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Retirer $title du panier',
                              icon: const Icon(Icons.close),
                              onPressed: _removing.contains(item.id)
                                  ? null
                                  : () => _remove(item.reference),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              width: double.infinity,
              child: Text(
                'Total : ${_formatPrice(total)}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}
