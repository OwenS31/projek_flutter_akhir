import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/booking_provider.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(bookingsProvider);
            },
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat booking',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mulai buat booking pertama Anda!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return BookingCard(booking: booking);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(bookingsProvider);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class BookingCard extends ConsumerStatefulWidget {
  final Booking booking;

  const BookingCard({super.key, required this.booking});

  @override
  ConsumerState<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<BookingCard> {
  bool _isLoading = false;

  Future<void> _handleAction(String action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = ref.read(bookingServiceProvider);
      bool success = false;
      String message = '';

      switch (action) {
        case 'checkin':
          success = await bookingService.checkIn(widget.booking.id);
          message = 'Check-in berhasil!';
          break;
        case 'checkout':
          success = await bookingService.checkOut(widget.booking.id);
          message = 'Check-out berhasil!';
          break;
        case 'cancel':
          success = await bookingService.cancelBooking(widget.booking.id);
          message = 'Booking berhasil dibatalkan!';
          break;
      }

      if (success) {
        Fluttertoast.showToast(msg: message, backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCancelConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Pembatalan'),
            content: const Text(
              'Apakah Anda yakin ingin membatalkan booking ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Ya, Batalkan',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _handleAction('cancel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.spotName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: booking.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: booking.status.color, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        booking.status.icon,
                        size: 16,
                        color: booking.status.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.status.displayName,
                        style: TextStyle(
                          color: booking.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Detail booking
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy').format(booking.date),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking.startTime} - ${booking.endTime}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Dibuat: ${DateFormat('dd MMM yyyy HH:mm').format(booking.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // Action buttons
            if (booking.canCheckIn() ||
                booking.canCheckOut() ||
                booking.canCancel()) ...[
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (booking.canCheckIn())
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => _handleAction('checkin'),
                          icon: const Icon(Icons.login, size: 16),
                          label: const Text('Check-in'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),

                  if (booking.canCheckOut())
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => _handleAction('checkout'),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Check-out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),

                  if (booking.canCancel())
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: OutlinedButton.icon(
                          onPressed:
                              _isLoading ? null : _showCancelConfirmation,
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Batalkan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
