import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:poke_dex/models/pokemon_model.dart';

class PokemonDetailPage extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailPage({super.key, required this.pokemon});

  @override
  State<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? pokemonDetails;
  bool isLoading = true;
  String? errorMessage;
  bool isShiny = false;
  late TabController _tabController;
  List<Map<String, dynamic>> evolutionChain = [];

  @override
  void initState() {
    super.initState();
    _fetchPokemonDetails();
    _tabController = TabController(length: 3, vsync: this); // 3 abas
  }

  Future<void> _fetchPokemonDetails() async {
    final dio = Dio();
    try {
      final response = await dio.get(widget.pokemon.url);
      setState(() {
        pokemonDetails = response.data;
        isLoading = false;
      });
      _fetchEvolutionChain(response.data['species']['url']);
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar detalhes do Pokémon: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchEvolutionChain(String speciesUrl) async {
    final dio = Dio();
    try {
      final speciesResponse = await dio.get(speciesUrl);
      final evolutionChainUrl = speciesResponse.data['evolution_chain']['url'];
      final evolutionChainResponse = await dio.get(evolutionChainUrl);
      _parseEvolutionChain(evolutionChainResponse.data['chain']);
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar cadeia de evolução: $e";
      });
    }
  }

  void _parseEvolutionChain(Map<String, dynamic> chain) {
    List<Map<String, dynamic>> evolutions = [];
    Map<String, dynamic>? current = chain;

    while (current != null) {
      // Extrai a URL correta do Pokémon
      final speciesUrl = current['species']['url'];
      final pokemonUrl = speciesUrl.replaceFirst('pokemon-species', 'pokemon');

      evolutions.add({
        'name': current['species']['name'],
        'url': pokemonUrl, // Usa a URL correta
      });

      if (current['evolves_to'].isNotEmpty) {
        current = current['evolves_to'][0];
      } else {
        current = null;
      }
    }

    setState(() {
      evolutionChain = evolutions;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryType = pokemonDetails != null
        ? pokemonDetails!['types'][0]['type']['name']
        : 'normal';

    return Scaffold(
      backgroundColor: Colors.red.withOpacity(0.8), // Cor de fundo vermelha
      appBar: AppBar(
        title: Text(
          _capitalizeName(widget.pokemon.name),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Digital',
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'Shiny',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Switch(
                  value: isShiny,
                  onChanged: (value) {
                    setState(() {
                      isShiny = value;
                    });
                  },
                  activeColor: Colors.red, // Cor do Switch quando ativado
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Detalhes"),
            Tab(text: "Movimentos"),
            Tab(text: "Evoluções"),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Icon(
              _getTypeIcon(primaryType),
              size: 300,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          _buildBody(),
        ],
      ),
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
    } else if (pokemonDetails == null) {
      return const Center(
        child: Text(
          "Detalhes do Pokémon não encontrados.",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(), // Primeira aba: Detalhes
          _buildMovesTab(),   // Segunda aba: Movimentos
          _buildEvolutionsTab(), // Terceira aba: Evoluções
        ],
      );
    }
  }

  // ================== ABA DE DETALHES ==================
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildPokemonImage(),
          const SizedBox(height: 50),
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildStatusSection(),
        ],
      ),
    );
  }

  Widget _buildPokemonImage() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Image.network(
          isShiny
              ? pokemonDetails!['sprites']['other']['showdown']['front_shiny']
              : pokemonDetails!['sprites']['other']['showdown']['front_default'],
          fit: BoxFit.contain,
          height: 80,
          width: 80,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Altura", "${pokemonDetails!['height'] / 10} m"),
            _buildInfoRow("Peso", "${pokemonDetails!['weight'] / 10} kg"),
            const SizedBox(height: 10),
            _buildAbilitiesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Habilidades:",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        ...pokemonDetails!['abilities']
            .map<Widget>((ability) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    "- ${_translateAbility(ability['ability']['name'])}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Card(
      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status Básicos:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            ...pokemonDetails!['stats'].map<Widget>((stat) => _buildStatRow(stat)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> stat) {
    final statName = _capitalizeName(stat['stat']['name']);
    final statValue = stat['base_stat'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$statName:",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: statValue / 255,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatColor(statName)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$statValue",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ================== ABA DE MOVIMENTOS ==================
  Widget _buildMovesTab() {
    final moves = pokemonDetails!['moves']
        .map<String>((move) => _capitalizeName(move['move']['name']))
        .toList();

    // Remove a primeira fileira de movimentos (exemplo: remove os primeiros 5 movimentos)
    final filteredMoves = moves.length > 5 ? moves.sublist(5) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Movimentos:",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (filteredMoves.isNotEmpty)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: filteredMoves
                  .map<Widget>((move) => _buildMoveChip(move))
                  .toList(),
            )
          else
            const Text(
              "Nenhum movimento disponível.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 20),
          _buildMovesByLevelSection(),
        ],
      ),
    );
  }

  Widget _buildMoveChip(String moveName) {
    return Chip(
      label: Text(
        moveName,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
    );
  }

  Widget _buildMovesByLevelSection() {
    final Map<String, List<String>> movesByLevel = {
      'Nível 1 - 20': [],
      'Nível 21 - 40': [],
      'Nível 41 - 60': [],
      'Nível 61 - 80': [],
      'Nível 81 - 100': [],
    };

    for (var move in pokemonDetails!['moves']) {
      final level = move['version_group_details'][0]['level_learned_at'];
      final moveName = _capitalizeName(move['move']['name']);

      if (move['version_group_details'][0]['move_learn_method']['name'] == 'level-up') {
        if (level <= 20) {
          movesByLevel['Nível 1 - 20']!.add(moveName);
        } else if (level <= 40) {
          movesByLevel['Nível 21 - 40']!.add(moveName);
        } else if (level <= 60) {
          movesByLevel['Nível 41 - 60']!.add(moveName);
        } else if (level <= 80) {
          movesByLevel['Nível 61 - 80']!.add(moveName);
        } else {
          movesByLevel['Nível 81 - 100']!.add(moveName);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Movimentos por Nível:",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...movesByLevel.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: entry.value
                    .map<Widget>((move) => _buildMoveChip(move))
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
          );
        }).toList(),
      ],
    );
  }

  // ================== ABA DE EVOLUÇÕES ==================
  Widget _buildEvolutionsTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Cadeia de Evolução:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (evolutionChain.isNotEmpty)
              _buildEvolutionChainVisual()
            else
              const Text(
                "Nenhuma evolução encontrada.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionChainVisual() {
    return Column(
      children: [
        for (int i = 0; i < evolutionChain.length; i++)
          Column(
            children: [
              _buildEvolutionCard(evolutionChain[i]),
              if (i < evolutionChain.length - 1) // Adiciona uma seta entre os Pokémon
                const Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                  size: 32,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEvolutionCard(Map<String, dynamic> evolution) {
    // Extrai o ID do Pokémon da URL
    final urlParts = evolution['url'].split('/');
    final pokemonId = urlParts[urlParts.length - 2];

    // URL da imagem do Pokémon em GIF
    final imageUrl =
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/$pokemonId.gif";

    return Card(
      color: Colors.white.withOpacity(0.2),
      child: SizedBox(
        width: 100, // Tamanho fixo para o quadrado
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red);
            },
          ),
        ),
      ),
    );
  }

  // ================== UTILIDADES ==================
  Color _getTypeColor(String type) {
    switch (type) {
      case 'grass':
        return Colors.green;
      case 'poison':
        return Colors.purple;
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'electric':
        return const Color.fromARGB(255, 207, 193, 0).withOpacity(0.05);
      case 'psychic':
        return Colors.pink;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown;
      case 'fairy':
        return Colors.pinkAccent;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.deepOrange;
      case 'flying':
        return Colors.lightBlueAccent;
      case 'ground':
        return Colors.brown;
      case 'rock':
        return Colors.grey;
      case 'bug':
        return Colors.lightGreen;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
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

  Color _getStatColor(String statName) {
    switch (statName.toLowerCase()) {
      case 'hp':
        return Colors.green;
      case 'attack':
        return Colors.red;
      case 'defense':
        return Colors.blue;
      case 'special-attack':
        return Colors.purple;
      case 'special-defense':
        return Colors.orange;
      case 'speed':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  String _translateAbility(String ability) {
    final Map<String, String> abilityTranslations = {
      'overgrow': 'Crescimento Excessivo',
      'chlorophyll': 'Clorofila',
      'blaze': 'Chama',
      'solar-power': 'Poder Solar',
      'torrent': 'Torrente',
      'rain-dish': 'Prato da Chuva',
      'static': 'Estático',
      'lightning-rod': 'Para-Raios',
    };
    return abilityTranslations[ability] ?? ability;
  }
}