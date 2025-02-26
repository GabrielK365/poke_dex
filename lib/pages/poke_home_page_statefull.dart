import 'package:flutter/material.dart';

class PokeHomePageStatefull extends StatefulWidget {
  const PokeHomePageStatefull({super.key});

  @override
  State<PokeHomePageStatefull> createState() => _PokeHomePageStatefullState();
}

class _PokeHomePageStatefullState extends State<PokeHomePageStatefull> {
  bool isCarregando = true;
  List<String> listaDePokemon = [];

  @override
  void initState() {
    super.initState();
    _carregaDados();
  }

  Future<void> _carregaDados() async {
    await Future.delayed(const Duration(seconds: 4));
    setState(() {
      listaDePokemon = ["Charmander", "Pikachu", "MewTwo"];
      isCarregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto
      appBar: AppBar(
        title: const Text(
          "Lista de Pokemon",
          style: TextStyle(color: Colors.white), // Texto branco no AppBar
        ),
        backgroundColor: Colors.red, // Mantém o AppBar vermelho
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return isCarregando
        ? const CircularProgressIndicator(color: Colors.white) // Ícone branco
        : ListView.builder(
            itemCount: listaDePokemon.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900], // Fundo cinza escuro
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    listaDePokemon[index],
                    style: const TextStyle(
                      color: Colors.white, // Texto branco
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          );
  }
}