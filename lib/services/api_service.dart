import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';

class StoreLink {
  final int storeId;
  final String url;
  StoreLink({required this.storeId, required this.url});
}

class DLC {
  final int id;
  final String name;
  final String? image;
  DLC({required this.id, required this.name, this.image});
}

class GameVideo {
  final String name;
  final String preview;
  final String videoUrl;
  GameVideo({required this.name, required this.preview, required this.videoUrl});
}

class HLTBData {
  final int? mainStory;
  final int? mainExtra;
  final int? completionist;
  HLTBData({this.mainStory, this.mainExtra, this.completionist});
}

class StorePriceInfo {
  final String storeName;
  final String? originalPrice;
  final String? finalPrice;
  final int? discountPercent;
  StorePriceInfo({
    required this.storeName,
    this.originalPrice,
    this.finalPrice,
    this.discountPercent,
  });
}

class GamesPage {
  final List<Game> games;
  final int totalCount;
  GamesPage({required this.games, required this.totalCount});
}

class ApiService {
  static const String _apiKey = 'ee73cfbd7e8d4ad7a01180f8b27cfc1d';
  static const String _baseUrl = 'https://api.rawg.io/api';
  static const int pageSize = 20;

  // ── Jogos principais ────────────────────────────────────────────

  Future<GamesPage> fetchGames({
    String? genre,
    String? platform,
    String? tag,
    String ordering = '-added',  // NOVO: ordenação dinâmica
    bool upcomingOnly = false,   // NOVO: só jogos futuros
    int page = 1,
  }) async {
    final now = DateTime.now();
    final params = <String, String>{
      'key': _apiKey,
      'page_size': pageSize.toString(),
      'page': page.toString(),
      'ordering': ordering,
    };

    // Apenas com metacritic se não for upcoming e não for ordenação por data
    if (!upcomingOnly && ordering != '-released') params['metacritic'] = '1,100';

    // Upcoming: datas futuras
    if (upcomingOnly) {
      final future = now.add(const Duration(days: 365));
      params['dates'] =
          '${now.toIso8601String().substring(0, 10)},${future.toIso8601String().substring(0, 10)}';
    }

    if (genre != null && genre.isNotEmpty) params['genres'] = genre;
    if (platform != null && platform.isNotEmpty) params['platforms'] = platform;
    if (tag != null && tag.isNotEmpty) params['tags'] = tag;

    final uri = Uri.parse('$_baseUrl/games').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return GamesPage(
        games: (data['results'] as List).map((j) => Game.fromJson(j)).toList(),
        totalCount: data['count'] as int,
      );
    }
    throw Exception('Erro na API: ${res.statusCode}');
  }

  Future<List<Game>> searchGames(String query, {bool precise = false}) async {
    final params = <String, String>{
      'key': _apiKey,
      'search': query,
      'page_size': '15',
      'search_precise': precise.toString(),
    };
    final uri = Uri.parse('$_baseUrl/games').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['results'] as List).map((j) => Game.fromJson(j)).toList();
    }
    throw Exception('Erro na API');
  }

  Future<Game> fetchGameDetails(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/games/$id?key=$_apiKey'));
    if (res.statusCode == 200) return Game.fromJson(json.decode(res.body));
    throw Exception('Erro ao buscar detalhes');
  }

  Future<List<String>> fetchGameScreenshots(int id) async {
    final res = await http.get(Uri.parse(
        '$_baseUrl/games/$id/screenshots?key=$_apiKey&page_size=12'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['results'] as List).map((s) => s['image'] as String).toList();
    }
    return [];
  }

  Future<List<StoreLink>> fetchGameStores(int gameId) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/games/$gameId/stores?key=$_apiKey'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['results'] as List)
          .map((s) => StoreLink(
                storeId: s['store_id'] as int,
                url: s['url'] as String,
              ))
          .toList();
    }
    return [];
  }

  Future<List<DLC>> fetchGameDLCs(int gameId) async {
    final res = await http.get(Uri.parse(
        '$_baseUrl/games/$gameId/additions?key=$_apiKey&page_size=10'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['results'] as List)
          .map((d) => DLC(
                id: d['id'] as int,
                name: d['name'] as String,
                image: d['background_image'] as String?,
              ))
          .toList();
    }
    return [];
  }

  Future<List<GameVideo>> fetchGameVideos(int gameId) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/games/$gameId/movies?key=$_apiKey'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['results'] as List).map((v) {
        final url = v['data']?['max'] as String? ??
            v['data']?['480'] as String? ?? '';
        return GameVideo(
          name: v['name'] as String,
          preview: v['preview'] as String? ?? '',
          videoUrl: url,
        );
      }).where((v) => v.videoUrl.isNotEmpty).toList();
    }
    return [];
  }

  // ── HLTB com timeout de 6s ──────────────────────────────────────

  Future<HLTBData?> fetchHLTB(String gameName) async {
    try {
      final uri = Uri.parse('https://howlongtobeat.com/api/search');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Referer': 'https://howlongtobeat.com',
              'Origin': 'https://howlongtobeat.com',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            body: json.encode({
              'searchType': 'games',
              'searchTerms': gameName.split(' '),
              'searchPage': 1,
              'size': 1,
              'searchOptions': {
                'games': {
                  'userId': 0,
                  'platform': '',
                  'sortCategory': 'popular',
                  'rangeCategory': 'main',
                  'rangeTime': {'min': null, 'max': null},
                  'gameplay': {'perspective': '', 'flow': '', 'genre': ''},
                  'rangeYear': {'min': '', 'max': ''},
                  'modifier': '',
                },
                'users': {'sortCategory': 'postcount'},
                'filter': '',
                'sort': 0,
                'randomizer': 0,
              },
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['data'] as List?;
        if (results != null && results.isNotEmpty) {
          final g = results[0];
          int? hrs(dynamic val) {
            if (val == null || val == 0) return null;
            return ((val as num).toInt() / 3600).round();
          }
          return HLTBData(
            mainStory: hrs(g['comp_main']),
            mainExtra: hrs(g['comp_plus']),
            completionist: hrs(g['comp_100']),
          );
        }
      }
    } catch (_) {
      // timeout ou erro de rede — retorna null silenciosamente
    }
    return null;
  }

  // ── Preço via Steam (apenas jogos com loja Steam) ───────────────

  Future<StorePriceInfo?> fetchSteamPrice(String storeUrl) async {
    try {
      final match =
          RegExp(r'store\.steampowered\.com/app/(\d+)').firstMatch(storeUrl);
      if (match == null) return null;
      final appId = match.group(1)!;

      final uri = Uri.parse(
          'https://store.steampowered.com/api/appdetails'
          '?appids=$appId&cc=br&l=portuguese&filters=price_overview');

      final res = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'pt-BR,pt;q=0.9',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final appData = data[appId];
        if (appData?['success'] != true) return null;

        final price = appData['data']?['price_overview'];
        if (price == null) {
          return StorePriceInfo(storeName: 'Steam', finalPrice: 'Gratuito');
        }

        final discount = price['discount_percent'] as int? ?? 0;
        final initial =
            'R\$${((price['initial'] as int) / 100).toStringAsFixed(2).replaceAll('.', ',')}';
        final finalP =
            'R\$${((price['final'] as int) / 100).toStringAsFixed(2).replaceAll('.', ',')}';

        return StorePriceInfo(
          storeName: 'Steam',
          originalPrice: discount > 0 ? initial : null,
          finalPrice: finalP,
          discountPercent: discount > 0 ? discount : null,
        );
      }
    } catch (_) {}
    return null;
  }
}