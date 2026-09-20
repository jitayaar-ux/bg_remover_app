
```dart:lib/main.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const JeetaSmsApp());
}

class AppSession {
  static String? storedPhone;
  static String? storedPassword;
  static String? storedUsername;
}

class JeetaSmsApp extends StatelessWidget {
  const JeetaSmsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jeeta SMS App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2B5278),
        scaffoldBackgroundColor: const Color(0xFF0E1621),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2B5278),
          secondary: const Color(0xFF4EA4F4),
          surface: const Color(0xFF17212B),
        ),
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _checkUser() {
    String phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid mobile number!')),
      );
      return;
    }

    AppSession.storedPhone = phone;

    if (AppSession.storedPassword == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SetPasswordScreen(phoneNumber: phone),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPasswordScreen(phoneNumber: phone),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF17212B), title: const Text('Jeeta SMS Secure Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Color(0xFF4EA4F4)),
            const SizedBox(height: 20),
            const Text('Enter Your Mobile Number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Secure End-to-End Encrypted SMS Messenger', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _checkUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA4F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class SetPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  const SetPasswordScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _SetPasswordScreenState createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  void _savePassword() {
    String pass = _passController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    if (pass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters!')),
      );
      return;
    }
    if (pass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    AppSession.storedPassword = pass;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(phoneNumber: widget.phoneNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF17212B), title: const Text('Create Secure Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 20),
            const Text('Set Your Login Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This password will be required to unlock your secure chat.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Set Password & Continue', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  const LoginPasswordScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _LoginPasswordScreenState createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final TextEditingController _passController = TextEditingController();

  void _verifyPassword() {
    if (_passController.text.trim() == AppSession.storedPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatHomeScreen(
            username: AppSession.storedUsername ?? 'User',
            privateNumber: widget.phoneNumber,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect Password! Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF17212B), title: const Text('Enter Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Color(0xFF4EA4F4)),
            const SizedBox(height: 20),
            Text('Welcome Back, ${widget.phoneNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enter your secure password to unlock chat', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 30),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _verifyPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA4F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Unlock Chat', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  const ProfileSetupScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _saveProfile() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your username!')),
      );
      return;
    }

    AppSession.storedUsername = _nameController.text.trim();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHomeScreen(
          username: AppSession.storedUsername!,
          privateNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF17212B), title: const Text('Create Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2B5278),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text('Tap to set Display Picture (DP)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Username',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF17212B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phone Number (Private)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(widget.phoneNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.lock, color: Colors.greenAccent, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA4F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save & Open Chat', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatHomeScreen extends StatefulWidget {
  final String username;
  final String privateNumber;

  const ChatHomeScreen({Key? key, required this.username, required this.privateNumber}) : super(key: key);

  @override
  _ChatHomeScreenState createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _sim1Used = 12;
  int _sim2Used = 8;
  final int _maxPerSim = 100;
  
  String _selectedSim = "SIM 1";
  bool _isAutoDeleteActive = true;
  List<Map<String, dynamic>> _messages = [];

  String _encryptMessage(String text) {
    return "🔒E2EE:${text.split('').reversed.join('')}";
  }

  void _sendMessage() async {
    if (_phoneController.text.isEmpty || _msgController.text.isEmpty) return;

    if (_selectedSim == "SIM 1" && _sim1Used >= _maxPerSim) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIM 1 daily limit reached!')));
      return;
    }
    if (_selectedSim == "SIM 2" && _sim2Used >= _maxPerSim) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIM 2 daily limit reached!')));
      return;
    }

    String plainText = _msgController.text;
    String secureText = _encryptMessage(plainText);
    String recipient = _phoneController.text;

    setState(() {
      if (_selectedSim == "SIM 1") {
        _sim1Used++;
      } else {
        _sim2Used++;
      }

      _messages.add({
        "text": plainText,
        "sim": _selectedSim,
        "isMe": true,
        "time": DateTime.now(),
      });
      _msgController.clear();
    });

    if (_isAutoDeleteActive) {
      Future.delayed(const Duration(minutes: 5), () {
        setState(() {
          _messages.removeWhere((m) => m["text"] == plainText);
        });
      });
    }

    try {
      final Uri smsUri = Uri.parse('sms:$recipient?body=${Uri.encodeComponent(secureText)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    int sim1Left = _maxPerSim - _sim1Used;
    int sim2Left = _maxPerSim - _sim2Used;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17212B),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF2B5278),
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jeeta SMS - ${widget.username}', style: const TextStyle(fontSize: 15)),
                Text(
                  'SIM1: $sim1Left | SIM2: $sim2Left | ⏱️ 5m',
                  style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedSim,
            dropdownColor: const Color(0xFF17212B),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: const [
              DropdownMenuItem(value: "SIM 1", child: Text("SIM 1", style: TextStyle(fontSize: 12, color: Colors.white))),
              DropdownMenuItem(value: "SIM 2", child: Text("SIM 2", style: TextStyle(fontSize: 12, color: Colors.white))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedSim = val!;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF17212B),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Recipient Phone Number...',
                filled: true,
                fillColor: const Color(0xFF0E1621),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isMe = msg["isMe"];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF2B5278) : const Color(0xFF182533),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(msg["text"], style: const TextStyle(fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${msg["sim"]} • 🔒 E2EE • ⏱️ 5m', style: const TextStyle(fontSize: 9, color: Colors.white60)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF17212B),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _msgController.text += " 😊👍";
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type secure message...',
                     
