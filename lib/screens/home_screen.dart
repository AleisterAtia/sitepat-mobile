import 'package:flutter/material.dart';

import '../config.dart';
import '../models/claim_result.dart';
import '../services/api_service.dart';
import '../services/nfc_service.dart';
import 'login_screen.dart';

enum _Phase { idle, scanning, submitting }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _commodity = Commodity.lpg3kg;
  _Phase _phase = _Phase.idle;
  ClaimResult? _result;
  String? _error;

  bool get _busy => _phase != _Phase.idle;

  Future<void> _scanAndClaim() async {
    setState(() {
      _phase = _Phase.scanning;
      _result = null;
      _error = null;
    });
    try {
      final uid = await NfcService.readUid();
      if (!mounted) return;
      setState(() => _phase = _Phase.submitting);
      final result = await ApiService.instance.claim(
        nfcUid: uid,
        commodity: _commodity,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.idle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _logout();
        return;
      }
      setState(() {
        _error = e.message;
        _phase = _Phase.idle;
      });
    } catch (e) {
      // termasuk NfcException
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _phase = _Phase.idle;
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SI-TEPAT Petugas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _busy ? null : _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identitas SPBU/petugas
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station, color: Colors.blue),
                  title: Text(
                    user?.merchantName.isNotEmpty == true
                        ? user!.merchantName
                        : (user?.username ?? 'Petugas'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Petugas: ${user?.username ?? '-'}'),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Pilih Komoditas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: Commodity.all
                    .map(
                      (c) => ButtonSegment<String>(
                        value: c,
                        label: Text(Commodity.label(c)),
                      ),
                    )
                    .toList(),
                selected: {_commodity},
                onSelectionChanged: _busy
                    ? null
                    : (sel) => setState(() => _commodity = sel.first),
              ),
              const SizedBox(height: 32),

              _buildScanArea(),
              const SizedBox(height: 24),

              if (_error != null) _buildErrorCard(_error!),
              if (_result != null) _buildResultCard(_result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanArea() {
    if (_busy) {
      final label = _phase == _Phase.scanning
          ? 'Tempelkan e-KTP ke perangkat…'
          : 'Memproses klaim…';
      return Column(
        children: [
          const SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(strokeWidth: 5),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }
    return SizedBox(
      height: 120,
      child: FilledButton.icon(
        onPressed: _scanAndClaim,
        icon: const Icon(Icons.contactless, size: 36),
        label: const Text('Scan e-KTP', style: TextStyle(fontSize: 22)),
        style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ClaimResult result) {
    final success = result.isSuccess;
    final color = success ? Colors.green : Colors.orange;
    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: color.shade700,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              success ? 'KLAIM BERHASIL' : 'KLAIM DITOLAK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            if (success) ...[
              const SizedBox(height: 12),
              Text(
                'Sisa kuota: ${result.quotaRemaining}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
