import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'model/user.dart';
import 'screen/login_screen.dart';
import 'screen/home_screen.dart';

const FirebaseOptions defaultFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSySyBQCUIC_yfDMjnUE3E90T1sYGuzqNCw8",
  appId: "1:325792973217:android:2205b8817368080ab84be0",
  projectId: "coldtrack129",
  storageBucket: "coldtrack129.appspot.com",
  messagingSenderId: "325792973217",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ ตรวจสอบแบบชัวร์ๆ ก่อนเริ่ม
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: defaultFirebaseOptions);
    }
    // ถ้ามีอยู่แล้ว → ข้ามไปเลย ไม่ต้องเรียกอีก
  } on FirebaseException catch (e) {
    // ✅ จัดกรณี "already exists" โดยเฉพาะ
    if (e.code == 'duplicate-app' || e.message?.contains('already exists') == true) {
      // ไม่ใช่ปัญหา — ข้ามไปรันแอปได้เลย
    } else {
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'เกิดข้อผิดพลาดเริ่มต้น:\n${e.message}',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ));
      return;
    }
  }

  // ✅ มาถึงตรงนี้ = พร้อมทำงานแล้ว
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColdTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF008060)),
                  SizedBox(height: 16),
                  Text('กำลังเชื่อมต่อ...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'ผิดพลาด: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(user: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}