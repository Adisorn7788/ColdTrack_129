import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/user.dart';
import '../model/cargo.dart';
import 'cargo_form_screen.dart';

class CargoListScreen extends StatefulWidget {
  final AppUser? currentUser;
  const CargoListScreen({super.key, this.currentUser});

  @override
  State<CargoListScreen> createState() => _CargoListScreenState();
}

class _CargoListScreenState extends State<CargoListScreen> {
  final _cargoCollection = FirebaseFirestore.instance.collection('cargo');
  bool get _isAdmin => widget.currentUser?.isAdmin ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการขนส่ง'),
        backgroundColor: const Color(0xFF008060),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // ✅ ปุ่มลบทั้งหมด เฉพาะ Admin
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteAllDialog(),
              tooltip: 'ลบรายการทั้งหมด',
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF2F9F4),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cargoCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีรายการสินค้า\nกด "เพิ่มสินค้าใหม่" เพื่อเริ่มต้น',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final item = CargoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              return _buildCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildCard(CargoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTempColor(item.temp),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.temp}°C',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item.code} | ${item.type}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('ผู้ตรวจสอบ: ${item.inspector}', style: const TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('เหลือ ${item.daysLeft}', style: const TextStyle(fontSize: 13)),
                ]),
              ],
            ),
          ),
          // ✅ ปุ่มแก้ไข+ลบ แสดงเฉพาะ Admin
          if (_isAdmin)
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF008060)),
                    onPressed: () => _openEdit(item),
                    tooltip: 'แก้ไข',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(item),
                    tooltip: 'ลบ',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getTempColor(double temp) {
    if (temp <= 5) return Colors.blue;
    if (temp <= 10) return Colors.orange;
    return Colors.red;
  }

  void _openEdit(CargoItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargoFormScreen(
          currentUser: widget.currentUser,
          editItem: item,
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ อัปเดตสำเร็จ'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _showDeleteDialog(CargoItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${item.code}" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cargoCollection.doc(item.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ลบข้อมูลสำเร็จ'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันลบทั้งหมด'),
        content: const Text('ต้องการลบรายการทั้งหมด ใช่หรือไม่? การกระทำนี้ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final docs = await _cargoCollection.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ลบทั้งหมดสำเร็จ'), backgroundColor: Colors.green),
        );
      }
    }
  }
}