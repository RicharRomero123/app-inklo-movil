class AppConstants {
  // Auth0 Config
  static const String auth0Domain = 'dev-rzdnpm4zkt0mhys5.us.auth0.com';
  static const String auth0ClientId = 'TwiMi2exdjfe2LoiM1V3GUt3iiWLu4oK';
  static const String auth0Scheme = 'inklop';

  // 👇 AQUÍ ESTÁ LA MAGIA 👇
  // Cambiamos el Management API por la API de tu backend
  static const String auth0Audience = 'https://api.inklop.com/';

  // API Backend Config
  static const String apiBaseUrl = 'https://inklop-backend-dev-develop.up.railway.app/api/v1';
}