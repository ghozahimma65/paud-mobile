import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_services/api_service.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Note: Pastikan Firebase.initializeApp() sudah dipanggil di main.dart 
    // dan file google-services.json sudah ditaruh di folder android/app/.
    
    try {
      // 1. Request permission untuk notifikasi
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      }

      // 2. Setup Local Notifications untuk menangkap pop-up di Foreground
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotificationsPlugin.initialize(initializationSettings);

      // 2.5 Buat Notification Channel khusus Android 8.0+ agar muncul heads-up banner
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'paud_notif_channel', // id harus sama dengan yg dipakai di _showNotification
        'PAUD Notifications', // nama channel (muncul di setting HP)
        description: 'Notifikasi penting dari sistem PAUD',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Dapatkan FCM Token dan kirim ke Backend Laravel (saat aplikasi dibuka)
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("FCM Token (onInit): $token");
        await sendTokenToBackend(token);
      }

      // Listen untuk perubahan token (jika token expire lalu refresh)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        sendTokenToBackend(newToken);
      });

      // 4. Handle Notifikasi saat aplikasi berjalan di depan (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        
        if (message.notification != null) {
          _showNotification(message.notification!.title, message.notification!.body);
        }
      });

    } catch (e) {
      print("FCM Setup Error: $e");
    }
  }

  Future<void> _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'paud_notif_channel', // id
      'PAUD Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotificationsPlugin.show(
      0, 
      title, 
      body, 
      platformChannelSpecifics,
    );
  }

  // Panggil fungsi ini setelah user berhasil Login
  Future<void> updateTokenToServer() async {
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print("=== FCM TOKEN BERHASIL DI-GENERATE ===");
      print("FCM Token: $fcmToken");
      await sendTokenToBackend(fcmToken);
    } else {
      print("FCM Token gagal di-generate oleh device.");
    }
  }

  Future<void> sendTokenToBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
         print("Token Auth kosong, tidak bisa update FCM (belum login).");
         return;
      }

      // Pastikan Base URL sudah mengarah ke IP Laptop WiFi, bukan localhost
      final url = Uri.parse('${ApiService().baseUrl}/update-fcm-token');
      print("Mengirim FCM Token ke: $url");
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print("Token FCM berhasil disimpan di server Laravel!");
      } else {
        print("Gagal simpan Token FCM. Status Code: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Gagal mengirim token FCM ke server: $e");
    }
  }
}
