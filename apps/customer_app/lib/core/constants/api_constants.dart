class ApiConstants {
  // Configured for physical Android phone connected to local Wi-Fi or Cloudflare/Ngrok Tunnel
  static const String baseUrl = 'http://192.168.1.10:8000/api/v1';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String webBaseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String me = '/auth/me';

  // Customer
  static const String customerProfile = '/customer/profile';
  static const String emergencyContacts = '/customer/emergency-contacts';
  static const String savedLocations = '/customer/saved-locations';

  // Bookings
  static const String nearbyTotos = '/bookings/nearby-totos';
  static const String estimateFare = '/fare/estimate';
  static const String createBooking = '/bookings/estimate-and-create';
  static const String activeBooking = '/bookings/active';
  static const String bookingHistory = '/bookings/history';
  static const String bookingDetails = '/bookings'; // + /{id}
  static const String cancelBooking = '/bookings'; // + /{id}/cancel

  // Payments
  static const String createOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify-signature';

  // Ratings & Support
  static const String submitReview = '/reviews';
  static const String submitComplaint = '/support/complaints';
  static const String sosAlert = '/support/sos';
  static const String notifications = '/support/notifications';

  // Default Pan-India Map Coordinates (Kolkata Metro Center)
  static const double defaultLat = 22.572646;
  static const double defaultLng = 88.363895;
}
