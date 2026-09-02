import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

/// Retrofit REST API client contract for Raghif network services.
@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/auth/login')
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST('/auth/register')
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @GET('/stores')
  Future<dynamic> getStores();

  @GET('/stores/{id}')
  Future<dynamic> getStoreById(@Path('id') String storeId);

  @POST('/purchases')
  Future<dynamic> createPurchase(@Body() Map<String, dynamic> body);

  @GET('/purchases/user/{userId}')
  Future<dynamic> getUserPurchases(@Path('userId') String userId);
}
