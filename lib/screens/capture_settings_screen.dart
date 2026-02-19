import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models.dart';

const int _kMaxOffsetSeconds = 60;

class CaptureSettingsScreen extends StatefulWidget {
  const CaptureSettingsScreen({super.key});

  @override
  State<CaptureSettingsScreen> createState() => _CaptureSettingsScreenState();
}

class _CaptureSettingsScreenState extends State<CaptureSettingsScreen> {
  CaptureSettings get _s => captureSettingsService.settings;

  String _formatArea(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s == 0 ? '${m}min' : '${m}min ${s}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Capture Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Quick Capture section ──
          _SectionHeader(title: 'Quick Capture'),
          const SizedBox(height: 4),
          _SectionDescription(
            text:
                'These settings apply when you capture insights via volume buttons or headphone controls.',
          ),
          const SizedBox(height: 12),

          // Volume capture toggle
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Volume Button Capture',
            subtitle: 'Press volume up or down to capture an insight',
            trailing: Switch.adaptive(
              value: _s.volumeCaptureEnabled,
              activeTrackColor: Colors.amber,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() {
                  captureSettingsService.update(volumeCaptureEnabled: v);
                });
              },
            ),
          ),

          // Show capture sheet toggle
          _SettingsTile(
            icon: Icons.assignment_outlined,
            title: 'Show Capture Sheet',
            subtitle: 'Open the detail sheet after each quick capture',
            trailing: Switch.adaptive(
              value: _s.showCaptureSheet,
              activeTrackColor: Colors.amber,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() {
                  captureSettingsService.update(showCaptureSheet: v);
                });
              },
            ),
          ),

          // Auto AI summary toggle
          _SettingsTile(
            icon: Icons.auto_awesome,
            title: 'Auto AI Summary',
            subtitle:
                'Automatically generate an AI note when capturing an insight',
            trailing: Switch.adaptive(
              value: _s.autoAiSummary,
              activeTrackColor: Colors.amber,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() {
                  captureSettingsService.update(autoAiSummary: v);
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Default Offset section ──
          _SectionHeader(title: 'Default Offset'),
          const SizedBox(height: 4),
          _SectionDescription(
            text:
                'The time offset used for quick captures. You can still adjust per-insight in the capture sheet.',
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _s.defaultOffsetSeconds == 0
                            ? 'Exact'
                            : '±${_s.defaultOffsetSeconds}s',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        'Recommended: ±${kRecommendedOffsetSeconds}s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.amber,
                      inactiveTrackColor: Colors.white.withAlpha(20),
                      thumbColor: Colors.amber,
                      overlayColor: Colors.amber.withAlpha(30),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      min: 0,
                      max: _kMaxOffsetSeconds.toDouble(),
                      divisions: _kMaxOffsetSeconds,
                      value: _s.defaultOffsetSeconds.toDouble(),
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          captureSettingsService.update(
                              defaultOffsetSeconds: v.round());
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0s',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                      Text('${_kMaxOffsetSeconds}s',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Capture Area Size section ──
          _SectionHeader(title: 'Capture Area Size'),
          const SizedBox(height: 4),
          _SectionDescription(
            text: 'Total duration of audio to capture around the bookmark.',
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    _formatArea(_s.captureAreaSeconds),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.amber,
                      inactiveTrackColor: Colors.white.withAlpha(20),
                      thumbColor: Colors.amber,
                      overlayColor: Colors.amber.withAlpha(30),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      min: 10,
                      max: 300,
                      divisions: 29,
                      value: _s.captureAreaSeconds.toDouble(),
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          captureSettingsService.update(
                              captureAreaSeconds: v.round());
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10s',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                      Text('5min',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Info card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withAlpha(30)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 20, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The sync engine uses the offset precision to define a search window around your tap. '
                      'A wider range helps when your reaction time is slower.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionDescription extends StatelessWidget {
  final String text;
  const _SectionDescription({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey[500]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
