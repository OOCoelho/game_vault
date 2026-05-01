import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/firebase_service.dart';
import 'game_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171a21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171a21),
        elevation: 0,
        leading: const BackButton(color: Colors.white70),
        title: const Text('LISTA DE DESEJOS',
            style: TextStyle(letterSpacing: 2, fontSize: 14,
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.watchWishlist(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(
                color: Colors.blueAccent));
          }
          if (snap.data!.isEmpty) {
            return const Center(child: Text(
                'Sua lista de desejos está vazia.',
                style: TextStyle(color: Colors.grey)));
          }
          return ListView.separated(
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final d = snap.data![i];
              final game = Game(
                id: d['id'] as int,
                name: d['name'] as String,
                backgroundImage: d['backgroundImage'] as String? ?? '',
                metacritic: d['metacritic'] as int?,
                genres: List<String>.from(d['genres'] ?? []),
              );
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: game.backgroundImage,
                    width: 80, height: 50, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 80, height: 50,
                        color: const Color(0xFF1b2838)),
                    errorWidget: (_, __, ___) => Container(
                        width: 80, height: 50,
                        color: const Color(0xFF1b2838)),
                  ),
                ),
                title: Text(game.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(game.genres.take(2).join(' • '),
                    style: const TextStyle(
                        color: Colors.blueGrey, fontSize: 10)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (game.metacritic != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFa4d007), width: 1.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text('${game.metacritic}',
                          style: const TextStyle(
                              color: Color(0xFFa4d007),
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove,
                        color: Colors.redAccent, size: 18),
                    onPressed: () =>
                        FirebaseService.removeFromWishlist(game.id),
                  ),
                ]),
                onTap: () => Navigator.push(ctx,
                    MaterialPageRoute(
                        builder: (_) => GameDetailsScreen(game: game))),
              );
            },
          );
        },
      ),
    );
  }
}