import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/cargo.dart';
import '../model/user.dart';

class CargoFormScreen extends StatefulWidget {
  final AppUser? currentUser;
  final CargoItem? editItem; // null = เพิ่มใหม่, มีค่า = แก้ไข

  const CargoFormScreen({
    super.key,
    required this.currentUser,
    this.editItem,
  });

  @override
  State<CargoFormScreen> createState() => _CargoFormScreenState();
}

class _CargoFormScreenState extends State<CargoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoCollection = FirebaseFirestore.instance.collection('cargo');

  late TextEditingController _codeController;
  late TextEditingController _typeController;
  late TextEditingController _inspectorController;
  late TextEditingController _tempController;
  late TextEditingController _daysLeftController;

  bool _isSaving = false;

  // ✅ กฎสิทธิ์: เพิ่มได้ทุกคน, แก้ไขได้เฉพาะ Admin
  bool get _isCreateMode => widget.editItem == null;
  bool get _canModify => _isCreateMode || (widget.currentUser?.isAdmin ?? false);

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _codeController = TextEditingController(text: item?.code ?? '');
    _typeController = TextEditingController(text: item?.type ?? '');
    _inspectorController = TextEditingController(text: item?.inspector ?? '');
    _tempController = TextEditingController(text: item != null ? item.temp.toString() : '');
    _daysLeftController = TextEditingController(text: item?.daysLeft ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _typeController.dispose();
    _inspectorController.dispose();
    _tempController.dispose();
    _daysLeftController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ ป้องกัน: ถ้าไม่ใช่ Admin พยายามแก้ไข
    if (!_isCreateMode && !(widget.currentUser?.isAdmin ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ เฉพาะผู้ดูแลระบบเท่านั้นที่แก้ไขได้'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'code': _codeController.text.trim(),
        'type': _typeController.text.trim(),
        'inspector': _inspectorController.text.trim(),
        'temp': double.tryParse(_tempController.text.trim()) ?? 0.0,
        'daysLeft': _daysLeftController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isCreateMode) {
        // ✅ เพิ่มใหม่: ทุกคนทำได้
        data['createdAt'] = FieldValue.serverTimestamp();
        await _cargoCollection.add(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ เพิ่มข้อมูลสำเร็จ'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        // แก้ไข: เฉพาะ Admin
        final docRef = _cargoCollection.doc(widget.editItem!.id);
        final docSnap = await docRef.get();

        if (docSnap.exists) {
          await docRef.update(data);
        } else {
          data['createdAt'] = FieldValue.serverTimestamp();
          await docRef.set(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ แก้ไขข้อมูลสำเร็จ'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ไม่สามารถบันทึกข้อมูล: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'เพิ่มสินค้าใหม่' : 'แก้ไขข้อมูลสินค้า'),
        backgroundColor: const Color(0xFF008060),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ แจ้งเตือน Operator เมื่อเข้าโหมดแก้ไข
              if (!_isCreateMode && !(widget.currentUser?.isAdmin ?? false))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'คุณสามารถดูข้อมูลได้เท่านั้น\nหากต้องการแก้ไขหรือลบ ติดต่อผู้ดูแลระบบ',
                          style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // ✅ เพิ่ม: เปิดแก้ไขได้ / แก้ไข: ปิดช่องถ้าไม่ใช่ Admin
              _buildField(
                controller: _codeController,
                label: 'รหัสสินค้า',
                icon: Icons.qr_code,
                enabled: _canModify,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _typeController,
                label: 'ประเภทสินค้า',
                icon: Icons.category,
                enabled: _canModify,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _inspectorController,
                label: 'ผู้ตรวจสอบ',
                icon: Icons.person,
                enabled: _canModify,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _tempController,
                label: 'อุณหภูมิ (°C)',
                icon: Icons.thermostat,
                keyboardType: TextInputType.number,
                enabled: _canModify,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _daysLeftController,
                label: 'เวลาที่เหลือ',
                icon: Icons.timer,
                enabled: _canModify,
              ),
              const SizedBox(height: 32),

              // ✅ ปุ่มบันทึก: แสดง/เปิดเฉพาะเพิ่ม หรือ Admin
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isCreateMode || (widget.currentUser?.isAdmin ?? false)) && !_isSaving
                      ? _saveData
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isCreateMode || (widget.currentUser?.isAdmin ?? false))
                        ? const Color(0xFF008060)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isCreateMode ? 'เพิ่มรายการ' : 'บันทึกการแก้ไข',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF008060)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
      ),
      validator: (v) {
        if (!enabled) return null;
        if (v == null || v.trim().isEmpty) return 'กรุณาป้อน$label';
        return null;
      },
    );
  }
}