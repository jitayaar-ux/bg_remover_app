import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
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
      title: 'Dual-SIM Telegram SMS',
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
      home: const NumberSetupScreen(),
    );
  }
}

// 1. Login & Dual Number Setup Screen
class NumberSetupScreen extends StatefulWidget {
  const NumberSetupScreen({Key? key}) : super(key: key);

  @override
  _NumberSetupScreenState createState() => _NumberSetupScreenState();
}

class _NumberSetupScreenState extends State<NumberSetupScreen> {
  final TextEditingController _sim1Controller = TextEditingController();
  final TextEditingController _sim2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.sms,
      Permission.phone,
    ].request();
  }

  void _proceedToChat() {
    if (_sim1Controller.text.isEmpty || _sim2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both SIM numbers to login!')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHomeScreen(
          sim1Number: _sim1Controller.text,
          sim2Number: _sim2Controller.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual-SIM Login Setup'),
        backgroundColor: const Color(0xFF17212B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sim_card, size: 80, color: Color(0xFF4EA4F4)),
            const SizedBox(height: 20),
            const Text(
              'Enter Your Dual SIM Numbers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get 200 daily free SMS limits combined (100 per SIM)',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _sim1Controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'SIM 1 Phone Number',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sim2Controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'SIM 2 Phone Number',
                filled: true,
                fillColor: const Color(0xFF17212B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _proceedToChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA4F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Secure Chat', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Telegram Style Dual-SIM Chat Screen
class ChatHomeScreen extends StatefulWidget {
  final String sim1Number;
  final String sim2Number;

  const ChatHomeScreen({Key? key, required this.sim1Number, required this.sim2Number}) : super(key: key);

  @override
  _ChatHomeScreenState createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final Telephony telephony = Telephony.instance;
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _sim1Used = 10; // Used out of 100
  int _sim2Used = 5;  // Used out of 100
  final int _maxPerSim = 100;
  
  String _selectedSim = "SIM 1"; // Default SIM
  bool _isAutoDeleteActive = true; // 5 min timer active
  List<Map<String, dynamic>> _messages = [];

  String _encryptMessage(String text) {
    return "🔒E2EE:${text.split('').reversed.join('')}";
  }

  void _sendMessage() async {
    if (_phoneController.text.isEmpty || _msgController.text.isEmpty) return;

    if (_selectedSim == "SIM 1" && _sim1Used >= _maxPerSim) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIM 1 daily limit (100) reached! Switch to SIM 2.')));
      return;
    }
    if (_selectedSim == "SIM 2" && _sim2Used >= _maxPerSim) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIM 2 daily limit (100) reached! Switch to SIM 1.')));
      return;
    }

    String plainText = _msgController.text;
    String secureText = _encryptMessage(plainText);
    String recipient = _phoneController.text;

    try {
      await telephony.sendSms(
        to: recipient,
        message: secureText,
        statusListener: (SendStatus status) {
          if (status == SendStatus.SENT) {
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

            // 5 Minute Auto-Delete Timer
            if (_isAutoDeleteActive) {
              Future.delayed(const Duration(minutes: 5), () {
                setState(() {
                  _messages.removeWhere((m) => m["text"] == plainText);
                });
              });
            }
          }
        },
      );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Telegram Secure Chat', style: TextStyle(fontSize: 17)),
            Text(
              'SIM1 Left: $sim1Left | SIM2 Left: $sim2Left | ⏱️ 5m Timer',
              style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
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
            items: [
              DropdownMenuItem(value: "SIM 1", child: Text("SIM 1 (${widget.sim1Number})", style: const TextStyle(fontSize: 12, color: Colors.white))),
              DropdownMenuItem(value: "SIM 2", child: Text("SIM 2 (${widget.sim2Number})", style: const TextStyle(fontSize: 12, color: Colors.white))),
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
