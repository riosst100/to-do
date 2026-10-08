import 'package:flutter/material.dart';

/// Pesan kosong / error di tengah daftar, dengan aksi opsional (mis. "Coba lagi").
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(children: [
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ?action,
        ]),
      );
}
