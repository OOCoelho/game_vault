class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final int? metacritic;
  final List<String> genres;
  final String description;
  final String released;
  final List<String> developers;
  final List<String> publishers;
  final String? requirements;
  final List<String> platforms;
  final String? esrbRating; // NOVO

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    this.metacritic,
    required this.genres,
    this.description = '',
    this.released = '',
    this.developers = const [],
    this.publishers = const [],
    this.requirements,
    this.platforms = const [],
    this.esrbRating,
  });

  static String translateGenre(String genre) {
    const map = {
      'Action': 'Ação', 'Adventure': 'Aventura', 'RPG': 'RPG',
      'Shooter': 'Tiro', 'Indie': 'Indie', 'Strategy': 'Estratégia',
      'Sports': 'Esportes', 'Racing': 'Corrida', 'Fighting': 'Luta',
      'Platformer': 'Plataforma', 'Massively Multiplayer': 'MMO',
      'Simulation': 'Simulação', 'Puzzle': 'Quebra-cabeça',
    };
    return map[genre] ?? genre;
  }

  static String cleanDescription(String text) {
    String clean = text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
    for (final marker in ['Español', 'Deutsch', 'Français', 'Italiano', 'Polski']) {
      if (clean.contains(marker)) clean = clean.split(marker)[0].trim();
    }
    return clean;
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    String? reqs;
    if (json['platforms'] != null) {
      final pc = (json['platforms'] as List).firstWhere(
        (p) => p['platform']['name'] == 'PC',
        orElse: () => null,
      );
      reqs = pc?['requirements']?['minimum'];
    }

    return Game(
      id: json['id'],
      name: json['name'],
      backgroundImage: json['background_image'] ?? '',
      metacritic: json['metacritic'],
      genres: (json['genres'] as List?)
              ?.map((g) => translateGenre(g['name'].toString()))
              .toList() ?? [],
      description: json['description_raw'] ?? json['description'] ?? '',
      released: json['released'] ?? 'TBA',
      developers: (json['developers'] as List?)
              ?.map((d) => d['name'].toString()).toList() ?? [],
      publishers: (json['publishers'] as List?)
              ?.map((p) => p['name'].toString()).toList() ?? [],
      requirements: reqs,
      platforms: (json['platforms'] as List?)
              ?.map((p) => p['platform']['name'] as String).toList() ?? [],
      esrbRating: json['esrb_rating']?['name'] as String?,
    );
  }
}