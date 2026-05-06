import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // 'customer' or 'auditor' — no admins shown
  String _selectedRole = 'customer';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<UserEntity> _applyFilters(List<UserEntity> users) {
    return users.where((u) {
      if (u.role.toLowerCase() == 'admin') return false; // never show admins
      if (u.role.toLowerCase() != _selectedRole) return false;
      if (_searchQuery.isEmpty) return true;
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "User Management",
          style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: "Search users...",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Horizontal Role Toggle ──────────────────────────────────────
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildToggle(
                    label: 'Customers',
                    role: 'customer',
                    icon: Icons.person_outline,
                    activeColor: const Color(0xFF00C853),
                  ),
                  _buildToggle(
                    label: 'Auditors',
                    role: 'auditor',
                    icon: Icons.person_search_outlined,
                    activeColor: const Color(0xFFAA00FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── User List ───────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<UserEntity>>(
                stream: context.read<AdminProvider>().getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final filtered = _applyFilters(snapshot.data ?? []);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedRole == 'customer' ? Icons.people_outline : Icons.manage_search,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No ${_selectedRole == 'customer' ? 'customers' : 'auditors'} found",
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildUserCard(
                      user: filtered[index],
                      onToggle: () => context
                          .read<AdminProvider>()
                          .toggleUserStatus(filtered[index].id, filtered[index].isActive),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required String role,
    required IconData icon,
    required Color activeColor,
  }) {
    final isActive = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? activeColor : const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : const Color(0xFF94A3B8),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({required UserEntity user, required VoidCallback onToggle}) {
    final isAuditor = user.role.toLowerCase() == 'auditor';
    final roleColor    = isAuditor ? const Color(0xFFAA00FF) : const Color(0xFF00C853);
    final roleBg       = isAuditor ? const Color(0xFFF3E5F5) : const Color(0xFFE8F5E9);
    final iconBg       = isAuditor ? const Color(0xFFF3E5F5) : const Color(0xFFE8F5E9);
    final statusActive = user.isActive;
    final statusBg     = statusActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final statusColor  = statusActive ? const Color(0xFF00C853) : const Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  isAuditor ? Icons.person_search_outlined : Icons.person_outline,
                  color: roleColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onToggle,
                          child: Icon(
                            user.isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                            color: user.isActive ? const Color(0xFF00C853) : Colors.grey,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _badge(user.role, roleBg, roleColor),
              _badge(statusActive ? "Active" : "Inactive", statusBg, statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
