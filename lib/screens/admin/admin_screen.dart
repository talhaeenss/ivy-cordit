import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/invite.dart';
import '../../widgets/brutal_card.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/brutal_input.dart';
import '../../widgets/brutal_skeleton.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _maxUsesController = TextEditingController(text: '1');
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchInvites();
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: const Text('ADMIN PANEL', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.black,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'INVITE CODES'),
            Tab(text: 'USERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInviteTab(),
          _buildUserTab(),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        // Create Form
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: BrutalCard(
            backgroundColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CREATE INVITE CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: BrutalInput(
                        controller: _maxUsesController,
                        label: 'MAX USES',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: BrutalCard(
                          backgroundColor: AppColors.bgMain,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EXPIRES AT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Text(
                                _selectedDate == null ? 'NEVER' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BrutalButton(
                  onPressed: () {
                    final maxUses = int.tryParse(_maxUsesController.text) ?? 1;
                    admin.createInvite(maxUses: maxUses, expiresAt: _selectedDate);
                  },
                  isLoading: admin.isLoading,
                  text: 'GENERATE CODE',
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: admin.isLoading && admin.invites.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BrutalSkeleton(height: 80),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: admin.invites.length,
                  itemBuilder: (context, index) {
                    final invite = admin.invites[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BrutalCard(
                        backgroundColor: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SelectableText(
                                        invite.code,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(invite),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Uses: ${invite.usedCount}/${invite.maxUses} | Exp: ${invite.expiresAt == null ? 'Never' : DateFormat('dd/MM/yyyy').format(invite.expiresAt!)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                  ),
                                  Text(
                                    'By: ${invite.createdBy}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => admin.deleteInvite(invite.code),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(dynamic invite) {
    bool isValid = true;
    if (invite is Invite) {
      isValid = invite.isValid;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isValid ? AppColors.success : AppColors.error,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        isValid ? 'ACTIVE' : 'EXPIRED',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _buildUserTab() {
    final admin = context.watch<AdminProvider>();

    if (admin.isLoading && admin.users.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BrutalSkeleton(height: 70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.users.length,
      itemBuilder: (context, index) {
        final user = admin.users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BrutalCard(
            backgroundColor: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(user.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(user.username.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(user.role.toUpperCase(), style: TextStyle(color: user.isAdmin ? AppColors.error : AppColors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              trailing: user.isAdmin 
                ? const Icon(Icons.admin_panel_settings, color: AppColors.error)
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _showDeleteUserDialog(context, user.username),
                  ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteUserDialog(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.black, width: 3),
        ),
        title: const Text('KULLANICIYI SİL', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('$username kullanıcısını silmek istediğinize emin misiniz?'),
        actions: [
          BrutalButton(
            onPressed: () => Navigator.pop(context),
            text: 'İPTAL',
            backgroundColor: AppColors.grey,
          ),
          const SizedBox(width: 8),
          BrutalButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AdminProvider>().deleteUser(username);
            },
            text: 'SİL',
            backgroundColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}
