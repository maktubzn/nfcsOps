import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dados retornados pela consulta de CEP via ViaCEP.
class ViaCepResult {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade; // Cidade
  final String uf; // Estado (SP, RJ, etc.)
  final bool isError;

  const ViaCepResult({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
    this.isError = false,
  });

  String get formattedAddress {
    final parts = <String>[];
    if (logradouro.isNotEmpty) parts.add(logradouro);
    if (bairro.isNotEmpty) parts.add(bairro);
    return parts.join(' - ');
  }

  factory ViaCepResult.fromMap(Map<String, dynamic> map) {
    if (map['erro'] == true || map['erro'] == 'true') {
      return const ViaCepResult(
        cep: '',
        logradouro: '',
        complemento: '',
        bairro: '',
        localidade: '',
        uf: '',
        isError: true,
      );
    }
    return ViaCepResult(
      cep: map['cep'] as String? ?? '',
      logradouro: map['logradouro'] as String? ?? '',
      complemento: map['complemento'] as String? ?? '',
      bairro: map['bairro'] as String? ?? '',
      localidade: map['localidade'] as String? ?? '',
      uf: map['uf'] as String? ?? '',
      isError: false,
    );
  }
}

/// Serviço para busca de endereços através do CEP público (ViaCEP).
class ViaCepService {
  static const _baseUrl = 'https://viacep.com.br/ws';

  /// Busca informações de endereço a partir de um CEP.
  /// Aceita formatos como '01001-000' ou '01001000'.
  static Future<ViaCepResult?> fetchCep(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return null;

    try {
      final uri = Uri.parse('$_baseUrl/$cleanCep/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final result = ViaCepResult.fromMap(data);
        if (result.isError) return null;
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lista dos 27 estados do Brasil (UFs).
  static const List<String> brazilianStates = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];
}
