import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../models/game.dart';
import 'game_details_screen.dart';
import 'wishlist_screen.dart';
import 'login_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  String _genre = '';
  String _platform = '';
  String _ordering = '-added';
  bool _upcomingOnly = false;
  int _currentPage = 1;
  int _totalPages = 1;
  late Future<GamesPage> _future;
  final ScrollController _scroll = ScrollController();

  static const _genres = <String, String>{
    'Todos': '', 'Ação': 'action', 'Aventura': 'adventure',
    'RPG': 'role-playing-games-rpg', 'Tiro': 'shooter',
    'Estratégia': 'strategy', 'Esportes': 'sports',
    'Corrida': 'racing', 'Indie': 'indie',
    'Puzzle': 'puzzle', 'Simulação': 'simulation',
    'Luta': 'fighting', 'Horror': 'horror',
  };

  static const _platforms = <String, String>{
    'Todas': '', 'PC': '4', 'PS5': '187', 'PS4': '18',
    'Xbox Series': '186', 'Xbox One': '1',
    'Switch': '7', 'iOS': '3', 'Android': '21',
  };

  // Ordering: label → RAWG param
  static const _orderings = <String, String>{
    'Mais Populares': '-added',
    'Melhor Avaliados': '-metacritic',
    'Mais Recentes': '-released',
    'Ordem Aleatória': '-rating',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _load() {
    _future = _api.fetchGames(
      genre: _genre,
      platform: _platform,
      ordering: _ordering,
      upcomingOnly: _upcomingOnly,
      page: _currentPage,
    );
  }

  void _resetAndLoad() {
    setState(() { _currentPage = 1; _load(); });
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _changePage(int p) {
    setState(() { _currentPage = p; _load(); });
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171a21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171a21),
        elevation: 0,
        title: const Text('GAMEVAULT',
            style: TextStyle(
                letterSpacing: 3, fontSize: 15,
                fontWeight: FontWeight.w900, color: Colors.white)),
        actions: [
          // Wishlist
          StreamBuilder(
            stream: FirebaseService.authChanges,
            builder: (ctx, snap) {
              final user = snap.data;
              if (user == null) {
                return IconButton(
                  icon: const Icon(Icons.account_circle_outlined,
                      color: Colors.grey),
                  onPressed: () async {
                    await FirebaseService.signInWithGoogle();
                    setState(() {});
                  },
                );
              }
              return Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_outline,
                      color: Colors.blueAccent),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.grey, size: 18),
                  onPressed: () async {
                    await FirebaseService.signOut();
                    setState(() {});
                  },
                ),
              ]);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blueAccent),
            onPressed: () => showSearch(
                context: context, delegate: GameSearchDelegate(_api)),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Lista ────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<GamesPage>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(
                      color: Colors.blueAccent));
                }
                if (!snap.hasData || snap.hasError) {
                  return Center(child: Text(
                    snap.hasError ? 'Erro de conexão' : 'Nenhum resultado',
                    style: TextStyle(color: Colors.grey[600]),
                  ));
                }
                final page = snap.data!;
                _totalPages =
                    (page.totalCount / ApiService.pageSize).ceil().clamp(1, 500);

                return ListView.builder(
                  controller: _scroll,
                  itemCount: page.games.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == page.games.length) return _buildPagination();
                    return Column(children: [
                      _buildGameRow(ctx, page.games[i]),
                      const Divider(color: Colors.white10, height: 1),
                    ]);
                  },
                );
              },
            ),
          ),

          // ── Sidebar direita ──────────────────────────────────────
          Container(
            width: 200,
            color: const Color(0xFF1b2838),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
              children: [
                // Ordenação
                _sideSection('ORDENAR POR', _orderings, _ordering,
                    (v) { _ordering = v; _resetAndLoad(); }),
                const SizedBox(height: 4),
                // Em breve toggle
                InkWell(
                  onTap: () {
                    _upcomingOnly = !_upcomingOnly;
                    _resetAndLoad();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _upcomingOnly
                          ? Colors.blueAccent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: _upcomingOnly
                              ? Colors.blueAccent.withOpacity(0.5)
                              : Colors.transparent),
                    ),
                    child: Row(children: [
                      Icon(Icons.upcoming,
                          size: 12,
                          color: _upcomingOnly
                              ? Colors.blueAccent
                              : Colors.grey),
                      const SizedBox(width: 6),
                      Text('Em Breve',
                          style: TextStyle(
                            color: _upcomingOnly
                                ? Colors.blueAccent
                                : Colors.grey,
                            fontSize: 12,
                          )),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                _sideSection('GÊNERO', _genres, _genre,
                    (v) { _genre = v; _resetAndLoad(); }),
                const SizedBox(height: 14),
                _sideSection('PLATAFORMA', _platforms, _platform,
                    (v) { _platform = v; _resetAndLoad(); }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideSection(
    String label,
    Map<String, String> options,
    String selected,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.blueAccent, fontSize: 9,
                letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...options.entries.map((e) {
          final isSel = e.value == selected;
          return InkWell(
            onTap: () => onSelect(e.value),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSel
                    ? Colors.blueAccent.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: isSel
                        ? Colors.blueAccent.withOpacity(0.5)
                        : Colors.transparent),
              ),
              child: Row(children: [
                if (isSel)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.chevron_right,
                        color: Colors.blueAccent, size: 11),
                  ),
                Expanded(
                  child: Text(e.key,
                      style: TextStyle(
                        color: isSel ? Colors.blueAccent : Colors.grey,
                        fontSize: 11,
                        fontWeight:
                            isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGameRow(BuildContext ctx, Game game) {
    final isReleased = game.released != 'TBA' &&
        DateTime.tryParse(game.released)?.isBefore(DateTime.now()) == true;

    return InkWell(
      onTap: () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => GameDetailsScreen(game: game))),
      child: SizedBox(
        height: 85,
        child: Row(children: [
          SizedBox(
            width: 152,
            height: 85,
            child: CachedNetworkImage(
              imageUrl: game.backgroundImage,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: const Color(0xFF1b2838)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF1b2838)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(game.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    // Status de lançamento
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isReleased
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                            color: isReleased
                                ? Colors.green.withOpacity(0.5)
                                : Colors.orange.withOpacity(0.5)),
                      ),
                      child: Text(
                        isReleased ? 'Lançado' : 'Em breve',
                        style: TextStyle(
                            color: isReleased ? Colors.green : Colors.orange,
                            fontSize: 9),
                      ),
                    ),
                    Text(game.genres.take(2).join(' • '),
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 10)),
                  ]),
                  if (game.released.isNotEmpty && game.released != 'TBA')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(game.released,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 9)),
                    ),
                ],
              ),
            ),
          ),
          if (game.metacritic != null)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                    color: _scoreColor(game.metacritic!), width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('${game.metacritic}',
                  style: TextStyle(
                    color: _scoreColor(game.metacritic!),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  )),
            ),
        ]),
      ),
    );
  }

  Widget _buildPagination() {
    final total = _totalPages.clamp(1, 500);
    const w = 2;
    int start = (_currentPage - w).clamp(1, total);
    int end = (_currentPage + w).clamp(1, total);
    if (end - start < 4) {
      if (start == 1) end = (start + 4).clamp(1, total);
      if (end == total) start = (end - 4).clamp(1, total);
    }
    final pages = List.generate(end - start + 1, (i) => start + i);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pgBtn(Icons.chevron_left, _currentPage > 1,
              () => _changePage(_currentPage - 1)),
          const SizedBox(width: 4),
          if (start > 1) ...[
            _pgNum(1),
            if (start > 2)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...', style: TextStyle(color: Colors.grey))),
          ],
          ...pages.map(_pgNum),
          if (end < total) ...[
            if (end < total - 1)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...', style: TextStyle(color: Colors.grey))),
            _pgNum(total),
          ],
          const SizedBox(width: 4),
          _pgBtn(Icons.chevron_right, _currentPage < total,
              () => _changePage(_currentPage + 1)),
        ],
      ),
    );
  }

  Widget _pgNum(int page) {
    final cur = page == _currentPage;
    return GestureDetector(
      onTap: cur ? null : () => _changePage(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: cur ? Colors.blueAccent : const Color(0xFF1b2838),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: cur ? Colors.blueAccent : Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text('$page',
            style: TextStyle(
              color: cur ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: cur ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _pgBtn(IconData icon, bool enabled, VoidCallback fn) =>
      GestureDetector(
        onTap: enabled ? fn : null,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1b2838),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon,
              color: enabled ? Colors.grey : Colors.white12, size: 18),
        ),
      );

  Color _scoreColor(int s) {
    if (s >= 75) return const Color(0xFFa4d007);
    if (s >= 50) return Colors.orange;
    return Colors.redAccent;
  }
}

// Search delegate igual ao anterior — omitido por espaço, mantenha o existente
class GameSearchDelegate extends SearchDelegate<Game?> {
  final ApiService _api;
  bool _precise = false;
  GameSearchDelegate(this._api);

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFF171a21),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1b2838), elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        StatefulBuilder(builder: (ctx, setS) => GestureDetector(
          onTap: () { setS(() => _precise = !_precise); query = query; },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _precise ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
              border: Border.all(color: _precise ? Colors.blueAccent : Colors.white24),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(_precise ? 'EXATO' : 'AMPLO',
                style: TextStyle(color: _precise ? Colors.blueAccent : Colors.grey,
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        )),
        IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.grey),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      query.trim().isEmpty
          ? Container(color: const Color(0xFF171a21),
              child: const Center(child: Text('Digite o nome do jogo',
                  style: TextStyle(color: Colors.grey))))
          : _results(context);

  Widget _results(BuildContext context) {
    return FutureBuilder<List<Game>>(
      future: _api.searchGames(query.trim(), precise: _precise),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(color: const Color(0xFF171a21),
              child: Center(child: Text('Nenhum resultado para "$query"',
                  style: const TextStyle(color: Colors.grey))));
        }
        return Container(
          color: const Color(0xFF171a21),
          child: ListView.separated(
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final g = snap.data![i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: ClipRRect(borderRadius: BorderRadius.circular(3),
                  child: CachedNetworkImage(imageUrl: g.backgroundImage,
                      width: 64, height: 40, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(width: 64, height: 40, color: const Color(0xFF1b2838)),
                      errorWidget: (_, __, ___) => Container(width: 64, height: 40, color: const Color(0xFF1b2838)))),
                title: Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                subtitle: Text(g.genres.take(2).join(' • '), style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
                trailing: g.metacritic != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFa4d007), width: 1.5), borderRadius: BorderRadius.circular(3)),
                        child: Text('${g.metacritic}', style: const TextStyle(color: Color(0xFFa4d007), fontWeight: FontWeight.bold, fontSize: 12)))
                    : null,
                onTap: () {
                  close(context, g);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailsScreen(game: g)));
                },
              );
            },
          ),
        );
      },
    );
  }
}