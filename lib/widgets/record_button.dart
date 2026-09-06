import 'package:flutter/material.dart';

enum RecordButtonState { idle, recording, busy }

/// Der große runde Aufnahme-Button – wichtigstes Bedienelement im
/// Aufnahme-Flow und in der Sprach-Eingabe. Geteiltes Widget, damit beide
/// Stellen gleich aussehen und sich gleich anfühlen.
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.size = 184,
  });

  final RecordButtonState state;

  /// `null` deaktiviert den Button (z.B. während der Transkription).
  final VoidCallback? onPressed;

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recording = state == RecordButtonState.recording;
    final busy = state == RecordButtonState.busy;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: recording ? scheme.errorContainer : scheme.primaryContainer,
      ),
      padding: EdgeInsets.all(size * 0.065),
      child: Material(
        color: recording ? scheme.error : scheme.primary,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onPressed,
          child: Center(
            child: busy
                ? SizedBox(
                    width: size * 0.26,
                    height: size * 0.26,
                    child: CircularProgressIndicator(
                      color: scheme.onPrimary,
                      strokeWidth: 4,
                    ),
                  )
                : Icon(
                    recording ? Icons.stop : Icons.mic,
                    size: size * 0.41,
                    color: recording ? scheme.onError : scheme.onPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
