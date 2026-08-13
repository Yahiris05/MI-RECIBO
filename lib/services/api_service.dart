import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  // Metodo solicitado exactamente en el documento PDF
  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('$baseUrl/data'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Metodo para obtener el tipo de cambio del dolar (USD a DOP) en tiempo real
  Future<double> fetchDopExchangeRate() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final dopRate = rates['DOP'] as num;
        return dopRate.toDouble();
      }
    } catch (e) {
      // Retornar tasa de cambio por defecto si falla la conexion
      return 59.20;
    }
    return 59.20;
  }
}
