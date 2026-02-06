import 'dart:async';
import 'dart:html' as html;

Future<bool> speakText(String text, {String lang = 'en-US'}) async {
  final synth = html.window.speechSynthesis;
  if (text.trim().isEmpty || synth == null) return false;
  try {
    synth.cancel();
  } catch (_) {}
  final utterance = html.SpeechSynthesisUtterance(text);
  utterance.lang = lang;

  final completer = Completer<bool>();
  void complete(bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  utterance.onEnd.listen((_) => complete(true));
  utterance.onError.listen((_) => complete(false));
  synth.speak(utterance);

  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => false,
  );
}
