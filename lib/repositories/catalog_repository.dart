import 'package:dio/dio.dart';
import '../models/product.dart';

class CatalogRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));

  Future<List<Product>> fetchProducts() async {
    final response = await _dio.get('/products');
    final data = response.data['products'] as List;
    return data.map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> fetchProduct(int id) async {
    final response = await _dio.get('/products/$id');
    return Product.fromJson(response.data);
  }
}
