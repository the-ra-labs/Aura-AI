/// Is file ko GitHub par push mat karna (.gitignore mein hai).
class Secrets {
  /// Main (free): console.groq.com/keys
  static const groqKey = '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';

  /// Backup (free): cloud.cerebras.ai. Groq ki limit khatam ho to khud use hoga
  static const cerebrasKey = 'PASTE_CEREBRAS_KEY';

  /// Optional 3rd backup: GitHub token (free GPT-4o-mini)
  static const githubKey = 'PASTE_GITHUB_TOKEN';

  static const model = 'openai/gpt-oss-120b'; // Groq
  static const visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct'; // Groq, images ke liye
  static const backupModel = 'gpt-oss-120b'; // Cerebras
  static const githubModel = 'openai/gpt-4o-mini';
}