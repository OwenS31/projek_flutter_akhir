import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final spotsProvider = FutureProvider<List<Spot>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('spots')
      .select()
      .eq('is_available', true)
      .order('name');

  return (response as List).map((spot) => Spot.fromJson(spot)).toList();
});

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(authProvider).value;

  if (user == null) return [];

  final response = await supabase
      .from('bookings')
      .select('*, spots(name)')
      .eq('user_id', user.id)
      .order('date', ascending: false)
      .order('start_time', ascending: false);

  return (response as List)
      .map((booking) => Booking.fromJson(booking))
      .toList();
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BookingService(supabase, ref);
});

class BookingService {
  final SupabaseClient _supabase;
  final Ref _ref;

  BookingService(this._supabase, this._ref);

  Future<bool> createBooking({
    required String spotId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User tidak terautentikasi');

      // Ambil semua booking pada spot dan tanggal yang sama
      final existing = await _supabase
          .from('bookings')
          .select()
          .eq('spot_id', spotId)
          .eq('date', date.toIso8601String().split('T')[0])
          .neq('status', 'cancelled');

      final startMin = _toMinutes(startTime);
      final endMin = _toMinutes(endTime);

      final conflicts =
          existing.where((booking) {
            final existingStart = _toMinutes(booking['start_time']);
            final existingEnd = _toMinutes(booking['end_time']);
            return startMin < existingEnd && endMin > existingStart;
          }).toList();

      if (conflicts.isNotEmpty) {
        throw Exception('Waktu tidak tersedia');
      }

      await _supabase.from('bookings').insert({
        'user_id': user.id,
        'spot_id': spotId,
        'date': date.toIso8601String().split('T')[0],
        'start_time': startTime,
        'end_time': endTime,
        'status': 'pending',
      });

      _ref.invalidate(bookingsProvider);
      return true;
    } catch (e) {
      throw Exception('Gagal membuat booking: ${e.toString()}');
    }
  }

  int _toMinutes(String time) {
    final parts = time.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }

  Future<bool> checkIn(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'checkedIn'})
          .eq('id', bookingId);

      _ref.invalidate(bookingsProvider);
      return true;
    } catch (e) {
      throw Exception('Gagal check-in: ${e.toString()}');
    }
  }

  Future<bool> checkOut(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'checkedOut'})
          .eq('id', bookingId);

      _ref.invalidate(bookingsProvider);
      return true;
    } catch (e) {
      throw Exception('Gagal check-out: ${e.toString()}');
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      _ref.invalidate(bookingsProvider);
      return true;
    } catch (e) {
      throw Exception('Gagal membatalkan booking: ${e.toString()}');
    }
  }
}
