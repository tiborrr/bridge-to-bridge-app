import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bridge_to_bridge_app/services/api_service.dart';

class MockFlutterAppAuth extends Mock implements FlutterAppAuth {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockHttpClient extends Mock implements http.Client {}

class FakeTokenRequest extends Fake implements TokenRequest {}
class FakeAuthorizationTokenRequest extends Fake implements AuthorizationTokenRequest {}

void main() {
  late ApiService apiService;
  late MockFlutterAppAuth mockAppAuth;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.com\nKEYCLOAK_URL=https://auth.example.com');
    registerFallbackValue(FakeTokenRequest());
    registerFallbackValue(FakeAuthorizationTokenRequest());
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockAppAuth = MockFlutterAppAuth();
    mockSecureStorage = MockFlutterSecureStorage();
    mockHttpClient = MockHttpClient();

    apiService = ApiService(
      appAuth: mockAppAuth,
      secureStorage: mockSecureStorage,
      httpClient: mockHttpClient,
    );
  });

  group('initAuth', () {
    test('returns false when no tokens in storage', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await apiService.initAuth();
      expect(result, isFalse);
    });

    test('returns true when token is fresh', () async {
      when(() => mockSecureStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'valid_token');
      when(() => mockSecureStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh_token');
      // Set expiration to 10 minutes in the future
      when(() => mockSecureStorage.read(key: 'access_token_expiration'))
          .thenAnswer((_) async => DateTime.now().add(const Duration(minutes: 10)).toIso8601String());

      final result = await apiService.initAuth();
      expect(result, isTrue);
      
      // Should not call refresh
      verifyNever(() => mockAppAuth.token(any()));
    });

    test('refreshes token if expiration is within 1 minute', () async {
      when(() => mockSecureStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'old_token');
      when(() => mockSecureStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh_token');
      // Set expiration to 30 seconds in the future
      when(() => mockSecureStorage.read(key: 'access_token_expiration'))
          .thenAnswer((_) async => DateTime.now().add(const Duration(seconds: 30)).toIso8601String());

      // Mock successful refresh
      final newExpiration = DateTime.now().add(const Duration(minutes: 5));
      final tokenResponse = TokenResponse(
        'new_access_token',
        'new_refresh_token',
        newExpiration,
        'id_token',
        'bearer',
        ['openid', 'profile'],
        null,
      );
      
      when(() => mockAppAuth.token(any()))
          .thenAnswer((_) async => tokenResponse);
          
      // Mock saving tokens
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});

      final result = await apiService.initAuth();
      expect(result, isTrue);
      
      verify(() => mockAppAuth.token(any())).called(1);
      verify(() => mockSecureStorage.write(key: 'access_token', value: 'new_access_token')).called(1);
    });

    test('returns false and clears storage if refresh fails', () async {
      when(() => mockSecureStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'old_token');
      when(() => mockSecureStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh_token');
      // Set expiration to past
      when(() => mockSecureStorage.read(key: 'access_token_expiration'))
          .thenAnswer((_) async => DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String());

      // Mock failed refresh
      when(() => mockAppAuth.token(any())).thenThrow(Exception('Refresh failed'));
      when(() => mockSecureStorage.deleteAll()).thenAnswer((_) => Future<void>.value());

      final result = await apiService.initAuth();
      expect(result, isFalse);
      
      verify(() => mockSecureStorage.deleteAll()).called(1);
    });
  });

  group('getValidToken', () {
    test('throws exception if token is missing', () async {
      // Don't call initAuth, so token is null
      expect(() => apiService.getValidToken(), throwsA(isA<Exception>()));
    });
  });

  group('loginWithOidc', () {
    test('saves tokens on success', () async {
      final expiration = DateTime.now().add(const Duration(minutes: 5));
      final response = AuthorizationTokenResponse(
        'new_access_token',
        'new_refresh_token',
        expiration,
        'id_token',
        'bearer',
        ['openid', 'profile'],
        null,
        null,
      );

      when(() => mockAppAuth.authorizeAndExchangeCode(any()))
          .thenAnswer((_) async => response);
      
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});

      await apiService.loginWithOidc();

      verify(() => mockSecureStorage.write(key: 'access_token', value: 'new_access_token')).called(1);
    });
  });
}
