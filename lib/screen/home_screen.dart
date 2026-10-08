import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/user.dart';
import 'cargo_form_screen.dart';
import 'cargo_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentUser = AppUser.fromMap(doc.data()!, widget.user.uid);
          _isLoading = false;
        });
      } else {
        final newUser = AppUser(
          uid: widget.user.uid,
          email: widget.user.email ?? '',
          role: _detectRoleFromEmail(widget.user.email ?? ''),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .set(newUser.toMap());

        if (!mounted) return;
        setState(() {
          _currentUser = newUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดข้อมูลไม่ได้: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  String _detectRoleFromEmail(String email) {
    if (email == 'admin@test.com') return 'admin';
    if (email == 'operator@test.com') return 'operator';
    return 'operator';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ไม่พบข้อมูลผู้ใช้'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับไปเข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      );
    }

    final isAdmin = _currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ColdTrack'),
        backgroundColor: const Color(0xFF008060),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
            },
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.thermostat, size: 80, color: Color(0xFF008060)),
              const SizedBox(height: 16),
              const Text('ColdTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              const Text('ระบบติดตามห่วงโซ่ความเย็น', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),
              Text(
                'เข้าสู่ระบบในฐานะ:\n${isAdmin ? "👑 ผู้ดูแลระบบ" : "👁️ ผู้ปฏิบัติงาน"}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(_currentUser?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CargoFormScreen(currentUser: _currentUser),
                    ));
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(isAdmin ? 'เพิ่มสินค้าใหม่' : 'ดูข้อมูลสินค้า'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008060),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CargoListScreen(currentUser: _currentUser),
                    ));
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('ดูรายการทั้งหมด'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF008060)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 4,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CargoFormScreen(currentUser: _currentUser),
                  ));
                },
                icon: const Icon(Icons.save_outlined, color: Color(0xFF008060)),
                label: const Text('บันทึกข้อมูล', style: TextStyle(color: Color(0xFF008060))),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CargoListScreen(currentUser: _currentUser),
                  ));
                },
                icon: const Icon(Icons.list_alt, color: Colors.grey),
                label: const Text('รายการขนส่ง', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}