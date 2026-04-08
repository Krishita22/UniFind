part of '../main.dart';

/// UniNotifications
/// ─────────────────────────────────────────────────────────────────────────
/// Handles in-app and system notifications for UniFind.
///
/// On mobile (Android / iOS) and desktop (Windows / macOS / Linux):
///   Uses flutter_local_notifications to show real OS-level push banners.
///
/// On web (Edge / Chrome):
///   flutter_local_notifications does not support web, so we fall back to
///   an in-app overlay banner displayed inside the Flutter widget tree.
/// ─────────────────────────────────────────────────────────────────────────

class UniNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  /// Call once at app startup (in initState).
  static Future<void> init() async {
    if (_initialised || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin  = DarwinInitializationSettings(
      requestAlertPermission:  true,
      requestBadgePermission:  true,
      requestSoundPermission:  true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const settings = InitializationSettings(
      android: android,
      iOS:     darwin,
      macOS:   darwin,
      linux:   linux,
    );
    await _plugin.initialize(settings);
    _initialised = true;
  }

  /// Show a notification.
  ///
  /// [context] is only used for web (in-app overlay fallback).
  /// Pass `null` if the widget is no longer mounted.
  static Future<void> showMessage({
    required String title,
    required String body,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      // Web fallback: show an in-app overlay banner
      if (context != null) {
        _showWebBanner(context, title, body);
      }
      return;
    }

    if (!_initialised) return;

    const androidDetails = AndroidNotificationDetails(
      'unifind_messages',
      'UniFind Messages',
      channelDescription: 'Notifications for new UniFind messages',
      importance: Importance.high,
      priority:   Priority.high,
      icon:       '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS:     darwinDetails,
      macOS:   darwinDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// In-app banner overlay used as the web fallback.
  static void _showWebBanner(BuildContext ctx, String title, String body) {
    // Safely get the overlay — context from a GlobalKey may not have one
    OverlayState? overlay;
    try {
      overlay = Overlay.of(ctx);
    } catch (_) {
      return; // No overlay available, skip the banner silently
    }
    if (!overlay.mounted) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _WebNotifBanner(
        title: title,
        body:  body,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }
}

/// The in-app banner widget rendered on web.
class _WebNotifBanner extends StatefulWidget {
  final String title, body;
  final VoidCallback onDismiss;
  const _WebNotifBanner({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_WebNotifBanner> createState() => _WebNotifBannerState();
}

class _WebNotifBannerState extends State<_WebNotifBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1010),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cRed.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: cRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: cRed, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(widget.body,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5), size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
