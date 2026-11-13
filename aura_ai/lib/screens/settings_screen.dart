import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/settings_controller.dart';
import '../core/secrets.dart';
import '../core/theme/app_colors.dart';
import '../services/ai_service.dart';
import '../widgets/buttons.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';

enum _Cat { general, profile, key, voice, data, about }

const _cats = [
  (_Cat.general, Icons.tune_rounded, 'General'),
  (_Cat.profile, Icons.person_rounded, 'Profile'),
  (_Cat.key, Icons.key_rounded, 'API Key'),
  (_Cat.voice, Icons.mic_rounded, 'Voice'),
  (_Cat.data, Icons.shield_rounded, 'Data & Privacy'),
  (_Cat.about, Icons.info_outline_rounded, 'About'),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key, required this.auth, required this.settings, required this.chat});
  final AuthController auth;
  final SettingsController settings;
  final ChatController chat;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsController get st => widget.settings;
  _Cat? _sel;
  late final _name = TextEditingController(text: st.displayName);
  late final _about = TextEditingController(text: st.aboutMe);
  late final _instr = TextEditingController(text: st.customInstructions);
  late final _key = TextEditingController(text: st.apiKey);
  bool _hide = true, _testing = false, _testOk = false;
  String? _testMsg;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    _instr.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testMsg = null;
    });
    final err = await ChatApiService.testKey(
        SettingsController.groqUrl, st.effectiveKey);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = err == null;
      _testMsg = err ?? 'Connection OK ✅ Groq key sahi hai';
    });
  }

  Widget _card(String title, List<Widget> children) => GlassContainer(
        margin: const EdgeInsets.only(bottom: 14),
        radius: 26,
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _chips(Map<String, String> opts, String current,
          Future<void> Function(String) onPick) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in opts.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: current == e.key,
            onSelected: (_) async {
              await onPick(e.key);
              if (mounted) setState(() {});
            },
          ),
      ]);

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
      );

  List<Widget> _general() => [
        _card('Reply language', [
          _chips(
              const {'auto': 'Auto', 'en': 'English', 'ur': 'اردو', 'roman': 'Roman Urdu'},
              st.replyLanguage,
              (v) => st.update(replyLanguage: v)),
        ]),
        _card('Response style', [
          _chips(
              const {'concise': 'Concise', 'balanced': 'Balanced', 'detailed': 'Detailed'},
              st.replyStyle,
              (v) => st.update(replyStyle: v)),
          _hint('Concise = chhote jawab, Detailed = step-by-step tafseel'),
        ]),
        _card('Text size', [
          Slider(
            value: st.textScale,
            min: 0.85,
            max: 1.3,
            divisions: 9,
            label: '${(st.textScale * 100).round()}%',
            onChanged: (v) async {
              await st.update(textScale: v);
              if (mounted) setState(() {});
            },
          ),
        ]),
      ];

  List<Widget> _profile() {
    final u = widget.auth.user!;
    return [
      _card('Account', [
        Row(children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.brand),
            child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(u.email.isEmpty ? 'Guest account' : u.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      ]),
      _card('About you', [
        TextField(
          controller: _name,
          onChanged: (v) => st.update(displayName: v),
          decoration: const InputDecoration(
              labelText: 'Display name',
              helperText: 'Greeting aur AI is naam se bulayega'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _about,
          maxLines: 3,
          onChanged: (v) => st.update(aboutMe: v),
          decoration: const InputDecoration(
              labelText: 'Aap ke baare mein (AI ko kya pata hona chahiye)',
              hintText: 'e.g. Main BSCS student hoon, Flutter seekh raha hoon'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _instr,
          maxLines: 3,
          onChanged: (v) => st.update(customInstructions: v),
          decoration: const InputDecoration(
              labelText: 'Custom instructions (AI kaise jawab de)',
              hintText: 'e.g. Pehle chhota jawab, phir example do'),
        ),
      ]),
      OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          widget.auth.signOut();
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
      ),
    ];
  }

  List<Widget> _keySection() => [
        _card('Status', [
          Row(children: [
            Icon(
                st.hasKey
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: st.hasKey ? AppColors.cyan : AppColors.gold),
            const SizedBox(width: 10),
            Expanded(
                child: Text(st.hasKey
                    ? 'AI ready: ${st.activeProviders.join(' → ')}'
                    : 'API key nahi mili (demo mode)')),
          ]),
          _hint('Model: ${Secrets.model}. Backup keys aur models secrets.dart mein hain'),
        ]),
        _card('Groq API key (free)', [
          TextField(
            controller: _key,
            obscureText: _hide,
            onChanged: (v) {
              st.update(apiKey: v);
              setState(() => _testMsg = null);
            },
            decoration: InputDecoration(
              labelText: 'Groq API key (optional)',
              helperText: 'Khali chhodo to secrets.dart wali key use hogi',
              suffixIcon: IconButton(
                icon: Icon(
                    _hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Test connection',
            icon: Icons.bolt_rounded,
            loading: _testing,
            onTap: st.effectiveKey.isNotEmpty ? _test : null,
          ),
          if (_testMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_testMsg!,
                  style: TextStyle(
                      color: _testOk ? AppColors.cyan : AppColors.pink, height: 1.4)),
            ),
          _hint('Free key (card nahi chahiye): console.groq.com/keys'),
        ]),
      ];

  List<Widget> _voice() => [
        _card('Voice language', [
          _chips(SettingsController.voiceLangs, st.voiceLang,
              (v) => st.update(voiceLang: v)),
          _hint('Bolne (mic) aur sunne (read aloud) dono ke liye'),
        ]),
      ];

  List<Widget> _data() => [
        _card('Chats', [
          OutlinedButton.icon(
            onPressed: () async {
              if (await confirm(
                  context, 'Clear all chats?', 'Saari chats delete ho jayengi.')) {
                widget.chat.deleteAll();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Clear all chats'),
          ),
        ]),
        _card('API key', [
          OutlinedButton.icon(
            onPressed: () async {
              await st.update(apiKey: '');
              _key.clear();
              if (mounted) setState(() => _testMsg = null);
            },
            icon: const Icon(Icons.key_off_rounded),
            label: const Text('Remove key saved in app'),
          ),
        ]),
      ];

  List<Widget> _aboutSection() => [
        _card('Aura AI', [
          const Text('Version 3.0', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      ];

  List<Widget> _items(_Cat c) => switch (c) {
        _Cat.general => _general(),
        _Cat.profile => _profile(),
        _Cat.key => _keySection(),
        _Cat.voice => _voice(),
        _Cat.data => _data(),
        _Cat.about => _aboutSection(),
      };

  Widget _content(_Cat c) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(16), children: _items(c)),
        ),
      );

  Widget _menu(_Cat? selected) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final c in _cats)
            GlassContainer(
              margin: const EdgeInsets.only(bottom: 10),
              radius: 20,
              opacity: selected == c.$1 ? 0.18 : 0.07,
              tint: selected == c.$1 ? AppColors.violet : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              onTap: () => setState(() => _sel = c.$1),
              child: Row(children: [
                Icon(c.$2, color: AppColors.cyan),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(c.$3,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final cat = _sel ?? (wide ? _Cat.general : null);
    return PopScope(
      canPop: wide || _sel == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _sel = null);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    if (!wide && _sel != null) {
                      setState(() => _sel = null);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 14),
                Text(
                  wide || cat == null
                      ? 'Settings'
                      : _cats.firstWhere((c) => c.$1 == cat).$3,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ]),
            ),
            Expanded(
              child: wide
                  ? Row(children: [
                      SizedBox(width: 270, child: _menu(cat)),
                      Expanded(child: _content(cat!)),
                    ])
                  : (cat == null ? _menu(null) : _content(cat)),
            ),
          ]),
        ),
      ),
    );
  }
}