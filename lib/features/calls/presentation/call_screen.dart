import 'package:flutter/material.dart';

class CallScreen extends StatelessWidget {
  final String channelId;
  final bool isAudioOnly;
  final String otherUserName;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.isAudioOnly,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Call: $channelId')));
  }
}
