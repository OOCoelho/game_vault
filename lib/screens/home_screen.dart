import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/game.dart';
import '../utils/theme_utils.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  String? selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("STEAM HUB", style: TextStyle(fontWeight: FontWeight.bold, color: SteamTheme.steamBlue)),
        backgroundColor: SteamTheme.steamNavy,
      ),
      body: Column(
        children: [
          _buildGenreFilter(),
          Expanded(
            child: FutureBuilder<List<Game>>(
              future: _api.fetchGames(genre: selectedGenre),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => _gameCard(snapshot.data![index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilter() {
    final genres = ['Action', 'RPG', 'Strategy', 'Indie', 'Shooter'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(10),
      child: Row(
        children: genres.map((g) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(g),
            selected: selectedGenre == g,
            onSelected: (val) => setState(() => selectedGenre = val ? g : null),
            selectedColor: SteamTheme.steamBlue,
          ),
        )).toList(),
      ),
    );
  }

  Widget _gameCard(Game game) {
    Color color = SteamTheme.getScoreColor(game.metacritic?.toDouble() ?? 0);
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SteamTheme.cardBg,
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        children: [
          Image.network(game.backgroundImage, height: 150, width: double.infinity, fit: BoxFit.cover),
          ListTile(
            title: Text(game.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("HLTB: ${game.playtime ?? '--'}h", style: TextStyle(color: Colors.grey)),
            trailing: CircleAvatar(
              backgroundColor: color,
              child: Text("${game.metacritic ?? '??'}", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}