import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/translation_service.dart';
import '../widgets/media_viewer.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  const GameDetailsScreen({required this.game, Key? key}) : super(key: key);

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final ApiService _api = ApiService();
  bool _expandNotes = false;
  bool _inWishlist = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final result = await FirebaseService.isInWishlist(widget.game.id);
    if (mounted) setState(() => _inWishlist = result);
  }

  // ── Classificação etária ────────────────────────────────────────

  static Color _esrbColor(String? rating) {
    if (rating == null) return Colors.transparent;
    if (rating.contains('Everyone') || rating.contains('Early')) return const Color(0xFF2d6a2d);
    if (rating.contains('Teen')) return const Color(0xFF7a6a00);
    if (rating.contains('Mature') || rating.contains('Adults')) return const Color(0xFF7a1a1a);
    return Colors.transparent;
  }

  static String _esrbLabel(String? rating) {
    if (rating == null) return '';
    if (rating.contains('Everyone 10')) return 'E10+';
    if (rating.contains('Everyone')) return 'E';
    if (rating.contains('Early')) return 'EC';
    if (rating.contains('Teen')) return 'T';
    if (rating.contains('Mature')) return 'M';
    if (rating.contains('Adults')) return 'AO';
    return 'RP';
  }

  // ── Constantes ──────────────────────────────────────────────────

  static const _storeInfo = <int, Map<String, dynamic>>{
    1:  {'name': 'Steam',       'color': Color(0xFF1b2838)},
    2:  {'name': 'Xbox',        'color': Color(0xFF107C10)},
    3:  {'name': 'PlayStation', 'color': Color(0xFF003087)},
    5:  {'name': 'GOG',         'color': Color(0xFF8A00D4)},
    6:  {'name': 'Nintendo',    'color': Color(0xFFE4000F)},
    9:  {'name': 'itch.io',     'color': Color(0xFF1a1a2e)},
    11: {'name': 'Epic Games',  'color': Color(0xFF2B2B2B)},
    13: {'name': 'Fanatical',   'color': Color(0xFF8B0000)},
  };

  static const _storeIcons = <int, IconData>{
    1:  Icons.gamepad,
    2:  Icons.sports_esports,
    3:  Icons.sports_esports,
    5:  Icons.store,
    6:  Icons.sports_esports,
    9:  Icons.store_mall_directory,
    11: Icons.store_mall_directory,
    13: Icons.local_offer,
  };

  static const _platformIcons = <String, IconData>{
    'PC':              Icons.computer,
    'PlayStation 5':   Icons.sports_esports,
    'PlayStation 4':   Icons.sports_esports,
    'PlayStation 3':   Icons.sports_esports,
    'Xbox One':        Icons.sports_esports,
    'Xbox Series S/X': Icons.sports_esports,
    'Xbox 360':        Icons.sports_esports,
    'Nintendo Switch': Icons.sports_esports,
    'iOS':             Icons.phone_iphone,
    'Android':         Icons.phone_android,
    'macOS':           Icons.laptop_mac,
    'Linux':           Icons.laptop,
  };

  static const _reqLabels = <String, String>{
    'OS':               'Sistema Operacional',
    'Processor':        'Processador',
    'Memory':           'Memória RAM',
    'Graphics':         'Placa de Vídeo',
    'DirectX':          'DirectX',
    'Storage':          'Armazenamento',
    'Sound Card':       'Placa de Som',
    'Network':          'Rede',
    'Additional Notes': 'Notas Adicionais',
  };

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b0e11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171a21),
        elevation: 0,
        leading: const BackButton(color: Colors.white70),
        actions: [
          if (FirebaseService.currentUser != null)
            IconButton(
              icon: Icon(
                _inWishlist ? Icons.bookmark : Icons.bookmark_outline,
                color: _inWishlist ? Colors.blueAccent : Colors.grey,
              ),
              onPressed: () async {
                if (_inWishlist) {
                  await FirebaseService.removeFromWishlist(widget.game.id);
                } else {
                  await FirebaseService.addToWishlist(widget.game);
                }
                setState(() => _inWishlist = !_inWishlist);
              },
            ),
        ],
      ),
      body: FutureBuilder<List<Object>>(
        future: Future.wait([
          _api.fetchGameDetails(widget.game.id),
          _api.fetchGameScreenshots(widget.game.id),
          _api.fetchGameStores(widget.game.id),
          _api.fetchGameDLCs(widget.game.id),
          _api.fetchGameVideos(widget.game.id),
        ]),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erro ao carregar',
                    style: TextStyle(color: Colors.grey[600])));
          }
          final game   = snap.data![0] as Game;
          final shots  = snap.data![1] as List<String>;
          final stores = snap.data![2] as List<StoreLink>;
          final dlcs   = snap.data![3] as List<DLC>;
          final videos = snap.data![4] as List<GameVideo>;
          return _buildContent(ctx, game, shots, stores, dlcs, videos);
        },
      ),
    );
  }

  // ── Conteúdo principal ──────────────────────────────────────────

  Widget _buildContent(
    BuildContext ctx,
    Game game,
    List<String> shots,
    List<StoreLink> stores,
    List<DLC> dlcs,
    List<GameVideo> videos,
  ) {
    final hasMedia = shots.isNotEmpty || videos.isNotEmpty;
    final api = _api;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone 80x80
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: game.backgroundImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      width: 80, height: 80, color: const Color(0xFF1b2838)),
                  errorWidget: (_, __, ___) => Container(
                      width: 80, height: 80, color: const Color(0xFF1b2838)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: game.genres.take(4).map(_genreChip).toList(),
                    ),
                  ],
                ),
              ),
              // Classificação etária + nota
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (game.metacritic != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1b2838),
                        border: Border.all(
                            color: const Color(0xFFa4d007), width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${game.metacritic}',
                          style: const TextStyle(
                              color: Color(0xFFa4d007),
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                  if (game.esrbRating != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _esrbColor(game.esrbRating),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _esrbColor(game.esrbRating)
                                .withOpacity(0.7),
                            width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(_esrbLabel(game.esrbRating),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Cards info ───────────────────────────────────────────
          Row(children: [
            _infoCard('LANÇAMENTO', game.released),
            const SizedBox(width: 8),
            _infoCard('METACRITIC', game.metacritic?.toString() ?? '--'),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _infoCard('DESENVOLVEDORA',
                game.developers.isEmpty ? 'N/A' : game.developers.join(', '),
                flex: 2),
            const SizedBox(width: 8),
            _infoCard('DISTRIBUIDORA',
                game.publishers.isEmpty ? 'N/A' : game.publishers.join(', '),
                flex: 2),
          ]),

          // ── Plataformas ──────────────────────────────────────────
          const SizedBox(height: 8),
          if (game.platforms.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1b2838),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DISPONÍVEL EM',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 9,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: game.platforms.map(_platformChip).toList(),
                  ),
                ],
              ),
            ),

          // ── Mídia ────────────────────────────────────────────────
          if (hasMedia) ...[
            const SizedBox(height: 20),
            _sectionHeader('MÍDIA',
                subtitle:
                    '${shots.length} foto${shots.length != 1 ? 's' : ''}'
                    ' • ${videos.length} vídeo${videos.length != 1 ? 's' : ''}'),
            const SizedBox(height: 10),
            _buildMediaGrid(shots, videos),
          ],

          // ── Onde comprar ─────────────────────────────────────────
          const SizedBox(height: 24),
          _sectionHeader('ONDE COMPRAR'),
          const SizedBox(height: 10),
          _buildStores(stores),
          // Onde comprar
const SizedBox(height: 24),
_sectionHeader('ONDE COMPRAR'),
const SizedBox(height: 10),
_buildStores(stores),

// Preço Steam — item separado, fora do _buildStores
FutureBuilder<StorePriceInfo?>(
  future: () async {
    final steamStore = stores.where((s) => s.storeId == 1).firstOrNull;
    if (steamStore == null) return null;
    return _api.fetchSteamPrice(steamStore.url);
  }(),
  builder: (ctx, snap) {
    if (!snap.hasData || snap.data == null) return const SizedBox();
    final p = snap.data!;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1b2838),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        const Icon(Icons.local_offer, color: Colors.blueAccent, size: 14),
        const SizedBox(width: 8),
        const Text('Steam  ',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        if (p.discountPercent != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            color: const Color(0xFF4c6b22),
            child: Text('-${p.discountPercent}%',
                style: const TextStyle(
                    color: Color(0xFFa4d007),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(p.originalPrice ?? '',
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough)),
          const SizedBox(width: 6),
        ],
        Text(p.finalPrice ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ]),
    );
  },
),
          // Preço Steam
          FutureBuilder<StorePriceInfo?>(
            future: () async {
              final steamStore =
                  stores.where((s) => s.storeId == 1).firstOrNull;
              if (steamStore == null) return null;
              return api.fetchSteamPrice(steamStore.url);
            }(),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data == null) return const SizedBox();
              final p = snap.data!;
              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1b2838),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(children: [
                  const Icon(Icons.local_offer,
                      color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 8),
                  const Text('Steam  ',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  if (p.discountPercent != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      color: const Color(0xFF4c6b22),
                      child: Text('-${p.discountPercent}%',
                          style: const TextStyle(
                              color: Color(0xFFa4d007),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(p.originalPrice ?? '',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 6),
                  ],
                  Text(p.finalPrice ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ]),
              );
            },
          ),

          // ── DLCs ─────────────────────────────────────────────────
          if (dlcs.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionHeader('DLCs & EXPANSÕES (${dlcs.length})'),
            const SizedBox(height: 10),
            ...dlcs.map((d) => _dlcCard(ctx, d)).toList(),
          ],

          // ── Sobre o jogo ─────────────────────────────────────────
          const SizedBox(height: 28),
          _sectionHeader('SOBRE O JOGO'),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: TranslationService.translate(
                Game.cleanDescription(game.description)),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Row(children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blueAccent),
                  ),
                  SizedBox(width: 8),
                  Text('Traduzindo...',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]);
              }
              final text = snap.data ?? Game.cleanDescription(game.description);
              return Text(text,
                  style: const TextStyle(
                      color: Color(0xFFc6d4df),
                      fontSize: 14,
                      height: 1.75));
            },
          ),

          // ── Requisitos ───────────────────────────────────────────
          if (game.requirements != null) ...[
            const SizedBox(height: 32),
            _sectionHeader('REQUISITOS MÍNIMOS (PC)'),
            const SizedBox(height: 12),
            _buildRequirements(game.requirements!),
          ],
        ],
      ),
    );
  }

  // ── Media grid ──────────────────────────────────────────────────

  Widget _buildMediaGrid(List<String> shots, List<GameVideo> videos) {
    final previews = <_PreviewItem>[
      ...videos.map((v) => _PreviewItem(thumb: v.preview, isVideo: true)),
      ...shots.map((s) => _PreviewItem(thumb: s, isVideo: false)),
    ];
    if (previews.isEmpty) return const SizedBox();

    final shown = previews.take(3).toList();
    final extra = previews.length - 3;

    return Row(
      children: [
        ...shown.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => MediaViewer.show(context,
                  screenshots: shots, videos: videos, initialIndex: i),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(
                      imageUrl: item.thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFF1b2838)),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFF1b2838)),
                    ),
                    if (item.isVideo)
                      const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: Colors.white70, size: 22),
                      ),
                  ]),
                ),
              ),
            ),
          );
        }),
        if (extra > 0)
          GestureDetector(
            onTap: () => MediaViewer.show(context,
                screenshots: shots, videos: videos),
            child: Container(
              width: 44,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1b2838),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.blueAccent, size: 18),
                  Text('$extra',
                      style: const TextStyle(
                          color: Colors.blueAccent, fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── DLC clicável ────────────────────────────────────────────────

  Widget _dlcCard(BuildContext ctx, DLC dlc) => InkWell(
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => GameDetailsScreen(
              game: Game(
                id: dlc.id,
                name: dlc.name,
                backgroundImage: dlc.image ?? '',
                genres: [],
              ),
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1b2838),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            if (dlc.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4)),
                child: CachedNetworkImage(
                  imageUrl: dlc.image!,
                  width: 100,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      width: 100, height: 56, color: const Color(0xFF0b0e11)),
                  errorWidget: (_, __, ___) => Container(
                      width: 100, height: 56, color: const Color(0xFF0b0e11)),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(dlc.name,
                  style: const TextStyle(
                      color: Color(0xFFc6d4df), fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            const SizedBox(width: 8),
          ]),
        ),
      );

  // ── Widgets auxiliares ──────────────────────────────────────────

  Widget _genreChip(String genre) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.15),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(genre,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
      );

  Widget _platformChip(String platform) {
    final icon = _platformIcons[platform] ?? Icons.devices;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.grey, size: 12),
      const SizedBox(width: 4),
      Text(platform,
          style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }

  Widget _infoCard(String label, String value, {int flex = 1}) =>
      Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1b2838),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 9,
                      letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ],
          ),
        ),
      );

  Widget _hltbRow(String label, int hours) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
            Text('${hours}h',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _sectionHeader(String title, {String? subtitle}) =>
      Row(children: [
        Container(width: 3, height: 14, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5)),
        if (subtitle != null) ...[
          const SizedBox(width: 10),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ]);
Widget _buildStores(List<StoreLink> stores) {
  final known =
      stores.where((s) => _storeInfo.containsKey(s.storeId)).toList();
  if (known.isEmpty) {
    return const Text('Lojas não disponíveis',
        style: TextStyle(color: Colors.grey, fontSize: 12));
  }
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: known.map(_storeButton).toList(),
  );
}

  Widget _storeButton(StoreLink store) {
    final info = _storeInfo[store.storeId]!;
    final icon = _storeIcons[store.storeId] ?? Icons.store;
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(store.url);
        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (info['color'] as Color).withOpacity(0.25),
          border: Border.all(
              color: (info['color'] as Color).withOpacity(0.6)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(info['name'] as String,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildRequirements(String raw) {
    var clean = raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'^Minimum:\s*', caseSensitive: false), '');

    final allKeys = _reqLabels.keys.map(RegExp.escape).join('|');
    final rows = <Widget>[];

    for (final entry in _reqLabels.entries) {
      final pattern = RegExp(
        '${RegExp.escape(entry.key)}:\\s*(.*?)(?=(?:$allKeys):|\\s*\$)',
        caseSensitive: false,
        dotAll: true,
      );
      final match = pattern.firstMatch(clean);
      if (match == null) continue;
      final value = match.group(1)?.trim() ?? '';
      if (value.isEmpty) continue;

      rows.add(entry.key == 'Additional Notes'
          ? _reqRowExpandable(entry.value, value)
          : _reqRow(entry.value, value));
      rows.add(const Divider(color: Colors.white10, height: 1));
    }
    if (rows.isNotEmpty && rows.last is Divider) rows.removeLast();

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF1b2838),
            borderRadius: BorderRadius.circular(4)),
        child: Text(clean.trim(),
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.6,
                fontFamily: 'monospace')),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1b2838),
          borderRadius: BorderRadius.circular(4)),
      child: Column(children: rows),
    );
  }

  Widget _reqRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 115,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: Color(0xFFc6d4df),
                      fontSize: 11,
                      height: 1.5)),
            ),
          ],
        ),
      );

  Widget _reqRowExpandable(String label, String value) {
    const maxChars = 130;
    final isLong = value.length > maxChars;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _expandNotes || !isLong
                      ? value
                      : '${value.substring(0, maxChars)}...',
                  style: const TextStyle(
                      color: Color(0xFFc6d4df),
                      fontSize: 11,
                      height: 1.5),
                ),
                if (isLong)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _expandNotes = !_expandNotes),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        _expandNotes ? 'Ver menos' : 'Ver mais',
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewItem {
  final String thumb;
  final bool isVideo;
  _PreviewItem({required this.thumb, required this.isVideo});
}