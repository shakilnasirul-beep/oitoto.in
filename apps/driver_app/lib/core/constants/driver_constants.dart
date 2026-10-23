class DriverConstants {
  // Configured for physical Android phone connected to local Wi-Fi or Cloudflare/Ngrok Tunnel
  static const String baseUrl = 'http://192.168.1.10:8000/api/v1';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String webBaseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String me = '/auth/me';

  // Driver Controls
  static const String profile = '/driver/profile';
  static const String toggleOnline = '/driver/toggle-online';
  static const String updateLocation = '/driver/location';
  static const String uploadDocument = '/driver/upload-document';
  static const String documents = '/driver/documents';
  static const String earnings = '/driver/earnings';
  static const String wallet = '/driver/wallet';
  static const String requestPayout = '/driver/payout-request';

  // Trip Lifecycle
  static const String activeBooking = '/bookings/active';
  static const String acceptBooking = '/bookings'; // + /{id}/accept
  static const String arrivedAtPickup = '/bookings'; // + /{id}/arrived
  static const String startTrip = '/bookings'; // + /{id}/start-trip
  static const String completeTrip = '/bookings'; // + /{id}/complete-trip
  static const String cashCollected = '/payments/cash-collected';

  static const double defaultLat = 22.572646;
  static const double defaultLng = 88.363895;
}
