import 'package:flutter/material.dart';

const _dlgBg = Color(0xFF16133A);

Future<String?> promptText(BuildContext context,
    {required String title,
      String initial = '',
      String hint = '',
      bool obscure = false}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _dlgBg,
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: obscure,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save')),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String body) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _dlgBg,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
      ],
    ),
  );
  return r == true;
}

Future<(String, String)?> projectDialog(BuildContext context,
    {String name = '', String instructions = '', bool edit = false}) {
  final n = TextEditingController(text: name);
  final i = TextEditingController(text: instructions);
  return showDialog<(String, String)>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _dlgBg,
      title: Text(edit ? 'Edit project' : 'New project'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: n,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Project name')),
          const SizedBox(height: 12),
          TextField(
            controller: i,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Custom instructions (optional)',
                hintText: 'e.g. Hamesha Roman Urdu mein jawab do'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, (n.text.trim(), i.text.trim())),
            child: const Text('Save')),
      ],
    ),
  );
}