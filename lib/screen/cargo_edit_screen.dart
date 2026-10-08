import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/cargo.dart';
import '../model/user.dart';

class CargoEditScreen extends StatefulWidget {
  final AppUser? currentUser;
  final CargoItem editItem;

  const CargoEditScreen({
    super.key,
    required this.currentUser,
    required this.editItem,
  });

  @override
  State<CargoEditScreen> createState() => _CargoEditScreenState();
}

class _CargoEditScreenState extends State<CargoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cargoCollection = FirebaseFirestore.instance.collection('cargo');

  late TextEditingController _codeController;
  late TextEditingController _typeController;
  late TextEditingController _inspectorController;
  late TextEditingController _tempController;
  late TextEditingController _daysLeftController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.editItem.code);
    _typeController = TextEditingController(text: widget.editItem.type);
    _inspectorController = TextEditingController(text: widget.editItem.inspector);
    _tempController = TextEditingController(text: widget.editItem.temp.toString());
    _daysLeftController = TextEditingController(text: widget.editItem.daysLeft);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

      final docRef = _cargoCollection.doc(widget.editItem.id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ บันทึกการแก้ไขสำเร็จ'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ไม่สามารถบันทึก: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลสินค้า'),
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
              if (!isAdmin)
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
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'เฉพาะผู้ดูแลระบบเท่านั้นที่สามารถแก้ไขข้อมูลได้',
                          style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildTextField(
                controller: _codeController,
                label: 'รหัสสินค้า',
                icon: Icons.qr_code,
                enabled: isAdmin,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _typeController,
                label: 'ประเภทสินค้า',
                icon: Icons.category,
                enabled: isAdmin,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _inspectorController,
                label: 'ผู้ตรวจสอบ',
                icon: Icons.person,
                enabled: isAdmin,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _tempController,
                label: 'อุณหภูมิ (°C)',
                icon: Icons.thermostat,
                keyboardType: TextInputType.number,
                enabled: isAdmin,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _daysLeftController,
                label: 'เวลาที่เหลือ',
                icon: Icons.timer,
                enabled: isAdmin,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAdmin && !_isSaving ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008060),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกการแก้ไข', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
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