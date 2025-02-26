import 'package:poke_dex/models/pokemon_model.dart';

class PokemonListModel {
  final int count;
  final String next;
  final String? previous;
  final List<Pokemon> results;

  PokemonListModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PokemonListModel.fromMap(Map<String, dynamic> map) {
    return PokemonListModel(
      count: map['count'] as int,
      next: map['next'] as String,
      previous: map['previous'] as String?,
      results: (map['results'] as List<dynamic>)
          .map((pokemonJson) => Pokemon.fromMap(pokemonJson))
          .toList(),
    );
  }
}