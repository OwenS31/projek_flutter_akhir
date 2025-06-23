import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String mallId;
  const BookingScreen({super.key, required this.mallId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  Spot? _selectedSpot;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default end time 1 hour after start time
    final now = TimeOfDay.now();
    _startTime = now;
    _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isValidTimeRange() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes > startMinutes;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Auto adjust end time to be 1 hour later
        _endTime = TimeOfDay(
          hour: (picked.hour + 1) % 24,
          minute: picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _createBooking() async {
    if (_selectedSpot == null) {
      Fluttertoast.showToast(
        msg: "Pilih spot terlebih dahulu",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!_isValidTimeRange()) {
      Fluttertoast.showToast(
        msg: "Waktu selesai harus lebih besar dari waktu mulai",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.createBooking(
        spotId: _selectedSpot!.id,
        date: _selectedDate,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
      );

      Fluttertoast.showToast(
        msg: "Booking berhasil dibuat!",
        backgroundColor: Colors.green,
      );

      if (mounted) {
      Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(spotsByMallProvider(widget.mallId));
    // final spotsAsync = ref.watch(spotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Spot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spot Selection
            const Text(
              'Pilih Spot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            spotsAsync.when(
              data: (spots) {
                if (spots.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada spot tersedia'),
                    ),
                  );
                }

                return Column(
                  children:
                      spots.map((spot) {
                        return Card(
                          child: RadioListTile<Spot>(
                            title: Text(spot.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(spot.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${NumberFormat('#,###').format(spot.pricePerHour)}/jam',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            value: spot,
                            groupValue: _selectedSpot,
                            onChanged: (Spot? value) {
                              setState(() {
                                _selectedSpot = value;
                              });
                            },
                          ),
                        );
                      }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $error'),
                    ),
                  ),
            ),

            const SizedBox(height: 24),

            // Date & Time Selection
            const Text(
              'Pilih Tanggal & Waktu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Tanggal'),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _selectDate,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Waktu Mulai'),
                      subtitle: Text(_formatTimeOfDay(_startTime)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _selectStartTime,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time_filled),
                      title: const Text('Waktu Selesai'),
                      subtitle: Text(_formatTimeOfDay(_endTime)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _selectEndTime,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Booking Summary
            if (_selectedSpot != null) ...[
              const Text(
                'Ringkasan Booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Spot:'),
                          Text(
                            _selectedSpot!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tanggal:'),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Waktu:'),
                          Text(
                            '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Harga:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###').format(_calculateTotalPrice())}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createBooking,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Buat Booking', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  double _calculateTotalPrice() {
    if (_selectedSpot == null) return 0;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationHours = (endMinutes - startMinutes) / 60;

    return _selectedSpot!.pricePerHour * durationHours.ceil();
  }
}
