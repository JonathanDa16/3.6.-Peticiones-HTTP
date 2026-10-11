import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Conserva los datos que se muestran de la respuesta de PokeAPI.
class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.types,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final double height;
  final double weight;
  final List<String> types;
  final String? imageUrl;

  /// Valida el JSON y convierte decimetros y hectogramos a metros y kilos.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final height = json['height'];
    final weight = json['weight'];
    final rawTypes = json['types'];
    final sprites = json['sprites'];

    if (id is! int ||
        name is! String ||
        height is! num ||
        weight is! num ||
        rawTypes is! List ||
        sprites is! Map<String, dynamic>) {
      throw const FormatException('Respuesta incompleta de PokeAPI');
    }

    final types = <String>[];

    for (final entry in rawTypes) {
      if (entry is! Map<String, dynamic> ||
          entry['type'] is! Map<String, dynamic> ||
          entry['type']['name'] is! String) {
        throw const FormatException('Tipos de Pokemon invalidos');
      }

      types.add(entry['type']['name'] as String);
    }

    final imageUrl = sprites['front_default'];

    if (imageUrl != null &&
        (imageUrl is! String || Uri.tryParse(imageUrl)?.scheme != 'https')) {
      throw const FormatException('URL de imagen invalida');
    }

    return Pokemon(
      id: id,
      name: name,
      height: height / 10,
      weight: weight / 10,
      types: List.unmodifiable(types),
      imageUrl: imageUrl as String?,
    );
  }
}

/// Expone un mensaje comprensible para los errores de consulta.
class PokemonRequestException implements Exception {
  const PokemonRequestException(this.message);

  final String message;
}

/// Solicita un Pokemon real y transforma su respuesta JSON.
class PokemonService {
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Pokemon> fetchPokemon(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (!RegExp(
      r'^(?:[a-z]+(?:-[a-z0-9]+)*|[1-9][0-9]*)$',
    ).hasMatch(normalizedQuery)) {
      throw const PokemonRequestException(
        'Escribe un nombre válido o un número mayor que cero.',
      );
    }

    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon/$normalizedQuery');

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw const PokemonRequestException(
          'No encontré ese Pokémon. Revisa el nombre o el número.',
        );
      }

      if (response.statusCode != 200) {
        throw const PokemonRequestException(
          'El servicio no está disponible. Intenta de nuevo.',
        );
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));

      if (json is! Map<String, dynamic>) {
        throw const FormatException('Se esperaba un objeto JSON');
      }

      return Pokemon.fromJson(json);
    } on TimeoutException {
      throw const PokemonRequestException(
        'La consulta tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const PokemonRequestException(
        'No pude conectar con PokéAPI. Revisa tu conexión.',
      );
    } on FormatException {
      throw const PokemonRequestException(
        'El servicio devolvió datos que no pude leer.',
      );
    }
  }

  void close() {
    _client.close();
  }
}
