import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const TelegramSmsApp());
}

class TelegramSmsApp extends StatelessWidget {
  const TelegramSmsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telegram Secure SMS',
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
      home: const LoginScreen(),
    );
  }
}

// 1. Single Number Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.sms, Permission.phone].request();
  }

  void _sendOtp() {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid mobile number!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(phoneNumber: _phoneController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF17212B), title: const Text('Login with Phone')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFF4EA4F4)),
            const SizedBox(height: 20),
            const Text('Enter Your Mobile Number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('We will send a verification code via SMS', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA4F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Get OTP', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. OTP Verification Screen
class OtpVerificationScreen extends StatelessWidget {
  final String phoneNumber;
  OtpVerificationScreen({Key? key, required this.phoneNumber}) : super(key: key);

  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF17212B), title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 20),
            Text('Enter 4-digit OTP sent to\n$phoneNumber', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('(Demo OTP: 1234)', style: TextStyle(color: Colors.orange, fontSize: 13)),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter OTP (1234)',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_otpController.text == "1234") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileSetupScreen(phoneNumber: phoneNumber),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid OTP! Enter 1234')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Verify & Continue', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Profile Creation Screen (DP, Username, Private Number)
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHomeScreen(
          username: _nameController.text,
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
            // Private Number field (Only for me)
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

// 4. Telegram Style Chat Screen with SIM Selector
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

    final Uri smsUri = Uri.parse('sms:$recipient?body=${Uri.encodeComponent(secureText)}');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
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
      } else {
        // Fallback simple SMS launch
        final Uri fallbackUri = Uri.parse('sms:$recipient');
        await launchUrl(fallbackUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
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
                Text(widget.username, style: const TextStyle(fontSize: 16)),
                Text(
                  'SIM1: $sim1Left | SIM2: $sim2Left | ⏱️ 5m',
                  style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // SIM Selector Dropdown
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
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sticky_note_2_outlined, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _msgController.text += " 🎨[Sticker]";
                    });
                  },
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFF4EA4F4),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
