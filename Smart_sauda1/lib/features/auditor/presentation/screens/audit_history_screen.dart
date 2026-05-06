import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/domain/entities/audit_entity.dart';
import 'package:smart_sauda1/domain/repositories/audit_repository.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';

class AuditHistoryScreen extends StatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  State<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends State<AuditHistoryScreen> {
  List<AuditEntity> _audits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    try {
      final audits = await context.read<AuditRepository>().getAudits(userId);
      if (mounted) setState(() { _audits = audits; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime dt) =>
      "${dt.day}/${_pad(dt.month)}/${dt.year}  ${_pad(dt.hour)}:${_pad(dt.minute)}";

  void _showDetail(AuditEntity audit) {
    final isVerified = audit.status == 'verified';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVerified ? Icons.verified_outlined : Icons.warning_amber_rounded,
                    color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AUD-${audit.id.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D1B2A)),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isVerified ? "Verified" : "Flagged",
                        style: TextStyle(
                          color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            _detailRow("Date & Time", _formatDate(audit.timestamp)),
            if (audit.orderId != null)
              _detailRow("Order ID", "...${audit.orderId!.substring(audit.orderId!.length > 8 ? audit.orderId!.length - 8 : 0)}"),
            _detailRow("Cart ID", "...${audit.cartId.substring(audit.cartId.length > 8 ? audit.cartId.length - 8 : 0)}"),
            _detailRow("Discrepancies", "${audit.discrepanciesCount}",
                valueColor: audit.discrepanciesCount > 0
                    ? const Color(0xFFFF6D00)
                    : const Color(0xFF00C853)),
            if (audit.totalAmount != null)
              _detailRow("Order Total", "Rs. ${audit.totalAmount!.toStringAsFixed(0)}",
                  valueColor: const Color(0xFF00C853)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAudits = _audits.length;
    final verified = _audits.where((a) => a.status == 'verified').length;
    final successRate = totalAudits == 0 ? 0 : ((verified / totalAudits) * 100).round();
    final totalDiscrepancies = _audits.fold(0, (t, a) => t + a.discrepanciesCount);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Audit History"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFF0D1B2A),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Expanded(child: _buildStatCard("Total Audits", "$totalAudits", null)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard("Success Rate", "$successRate%", const Color(0xFF00C853))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard("Discrepancies", "$totalDiscrepancies",
                              totalDiscrepancies > 0 ? const Color(0xFFFF6D00) : null)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_audits.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              "No audits completed yet",
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                            ),
                          ),
                        )
                      else
                        ..._audits.map((audit) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHistoryCard(audit),
                        )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, Color? valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF0D1B2A), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(AuditEntity audit) {
    final isVerified = audit.status == 'verified';
    final dateStr = _formatDate(audit.timestamp);
    final shortCart = audit.cartId.length > 10
        ? "...${audit.cartId.substring(audit.cartId.length - 8)}"
        : audit.cartId;

    return GestureDetector(
      onTap: () => _showDetail(audit),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isVerified ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AUD-${audit.id.substring(0, 8).toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A)),
                      ),
                      const SizedBox(height: 4),
                      Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailColumn("Cart", shortCart, null),
                _buildDetailColumn(
                  "Discrepancies",
                  "${audit.discrepanciesCount}",
                  isVerified ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                ),
                _buildDetailColumn(
                  "Amount",
                  audit.totalAmount != null
                      ? "Rs. ${audit.totalAmount!.toStringAsFixed(0)}"
                      : "—",
                  audit.totalAmount != null ? const Color(0xFF0D1B2A) : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.check : Icons.warning_amber,
                    size: 14,
                    color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVerified ? "Verified" : "Flagged",
                    style: TextStyle(
                      color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, Color? valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}
