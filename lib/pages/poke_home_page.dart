import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:poke_dex/models/pokemon_list_model.dart';
import 'package:poke_dex/models/pokemon_model.dart';
import 'package:poke_dex/pages/pokemon_detail_page.dart';

class PokeHomePage extends StatefulWidget {
  const PokeHomePage({super.key});

  @override
  State<PokeHomePage> createState() => _PokeHomePageState();
}

class _PokeHomePageState extends State<PokeHomePage> {
  bool isLoading = true;
  List<Pokemon> pokemonList = [];
  List<Pokemon> filteredPokemonList = [];
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPokemons();
  }

  Future<void> _fetchPokemons() async {
    final dio = Dio();
    try {
      final response = await dio.get('https://pokeapi.co/api/v2/pokemon?limit=151');
      var model = PokemonListModel.fromMap(response.data);
      setState(() {
        pokemonList = model.results;
        filteredPokemonList = pokemonList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar Pokémon: $e";
        isLoading = false;
      });
    }
  }

  void _filterPokemon(String query) {
    setState(() {
      filteredPokemonList = pokemonList
          .where((pokemon) => pokemon.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Pokedex",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Digital',
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.red,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              controller: _searchController,
              onChanged: _filterPokemon,
              hintText: "Pesquisar Pokémon...",
              leading: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    } else if (filteredPokemonList.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum Pokémon encontrado.",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredPokemonList.length,
        itemBuilder: (context, index) {
          var pokemon = filteredPokemonList[index];
          return _buildPokemonListItem(pokemon);
        },
      );
    }
  }

  Widget _buildPokemonListItem(Pokemon pokemon) {
    // Extrai o ID do Pokémon da URL
    final pokemonId = _extractPokemonId(pokemon.url);

    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Colors.grey[800],
      child: ListTile(
        leading: Image.network(
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png',
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
        title: Row(
          children: [
            Text(
              _capitalizeName(pokemon.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8), // Espaço entre o nome e o ícone do tipo
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchPokemonDetails(pokemon.url),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(color: Colors.white);
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error, color: Colors.red);
                } else if (!snapshot.hasData || snapshot.data!['types'].isEmpty) {
                  return const Icon(Icons.help_outline, color: Colors.white);
                } else {
                  final primaryType = snapshot.data!['types'][0]['type']['name'];
                  return Icon(
                    _getTypeIcon(primaryType),
                    color: Colors.white,
                  );
                }
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailPage(pokemon: pokemon),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchPokemonDetails(String url) async {
    final dio = Dio();
    try {
      final response = await dio.get(url);
      return response.data;
    } catch (e) {
      throw Exception("Erro ao carregar detalhes do Pokémon: $e");
    }
  }

  String _extractPokemonId(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    return segments[segments.length - 2]; // O ID está no penúltimo segmento
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'grass':
        return Icons.grass;
      case 'poison':
        return Icons.water_damage;
      case 'fire':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water_drop;
      case 'electric':
        return Icons.flash_on;
      case 'psychic':
        return Icons.psychology;
      case 'ice':
        return Icons.ac_unit;
      case 'dragon':
        return Icons.auto_awesome;
      case 'dark':
        return Icons.nights_stay;
      case 'fairy':
        return Icons.auto_awesome_motion;
      case 'normal':
        return Icons.circle_outlined;
      case 'fighting':
        return Icons.sports_mma;
      case 'flying':
        return Icons.airplanemode_active;
      case 'ground':
        return Icons.terrain;
      case 'rock':
        return Icons.landscape;
      case 'bug':
        return Icons.bug_report;
      case 'ghost':
        return Icons.visibility_off;
      case 'steel':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }
}