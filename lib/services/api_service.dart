import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';

class ApiService {
  final String apiKey = 'COLE_AQUI_SUA_CHAVE_RAWG';
  final String baseUrl = 'https://api.rawg.io/api';

  Future<List<Game>> fetchGames({String? genre}) async {
    String url = '$baseUrl/games?key=$apiKey&page_size=12';
    if (genre != null) url += '&genres=${genre.toLowerCase()}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = json.decode(response.body)['results'];
      return data.map((item) => Game.fromJson(item)).toList();
    }
    throw Exception('Erro ao conectar com a API');
  }
}