class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final int? metacritic;
  final double userRating;
  final int? playtime; // How Long To Beat

  Game({
    required this.id, 
    required this.name, 
    required this.backgroundImage, 
    this.metacritic, 
    required this.userRating,
    this.playtime
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'],
      backgroundImage: json['background_image'] ?? '',
      metacritic: json['metacritic'],
      userRating: (json['rating'] as num).toDouble() * 20, // 0-5 para 0-100
      playtime: json['playtime'],
    );
  }
}