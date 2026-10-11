import 'package:flutter/material.dart';

import 'pokemon_service.dart';

/// Permite buscar en PokeAPI y presenta carga, resultados y errores.
class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  final _queryController = TextEditingController(text: 'pikachu');
  final _service = PokemonService();
  Pokemon? _pokemon;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchPokemon();
  }

  Future<void> _searchPokemon() async {
    if (_isLoading) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pokemon = null;
    });

    try {
      final pokemon = await _service.fetchPokemon(_queryController.text);

      if (!mounted) {
        return;
      }

      setState(() {
        _pokemon = pokemon;
      });
    } on PokemonRequestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta Pokémon')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Explora PokéAPI',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Busca por nombre o número. Los datos vienen de PokéAPI.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _queryController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Nombre o número',
                  hintText: 'Por ejemplo, pikachu o 25',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _searchPokemon(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isLoading ? null : _searchPokemon,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                Center(
                  child: Semantics(
                    label: 'Consultando PokéAPI',
                    child: const CircularProgressIndicator(),
                  ),
                ),
              if (_errorMessage != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _searchPokemon,
                  child: const Text('Reintentar'),
                ),
              ],
              if (_pokemon case final pokemon?)
                _PokemonResult(pokemon: pokemon),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokemonResult extends StatelessWidget {
  const _PokemonResult({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pokemon.imageUrl != null)
          Center(
            child: Image.network(
              pokemon.imageUrl!,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              semanticLabel: pokemon.name,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 180,
                child: Center(child: Text('Imagen no disponible')),
              ),
            ),
          ),
        Text(
          '#${pokemon.id} · ${pokemon.name}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        Text('Tipos: ${pokemon.types.join(', ')}'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('Altura: ${pokemon.height} m')),
            Expanded(child: Text('Peso: ${pokemon.weight} kg')),
          ],
        ),
      ],
    );
  }
}
