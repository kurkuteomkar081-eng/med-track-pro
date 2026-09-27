import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'MedTrack Pro';
  static const String targetUrl = 'https://gigantic-med-track-pro.base44.app';

  // Branding & Theme Colors
  static const Color primaryColor = Color(0xFF0284C7); // Medical Ocean Blue
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color accentColor = Color(0xFF0EA5E9);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  // Timeouts & Durations
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration exitWarningWindow = Duration(seconds: 2);

  // Pull-to-Refresh JavaScript Injection
  static const String pullToRefreshJs = '''
    (function() {
      let startY = 0;
      let isAtTop = true;

      window.addEventListener('touchstart', function(e) {
        if (e.touches.length === 1) {
          startY = e.touches[0].clientY;
          isAtTop = (window.scrollY || document.documentElement.scrollTop || 0) <= 0;
        }
      }, { passive: true });

      window.addEventListener('touchmove', function(e) {
        if (isAtTop && e.touches.length === 1) {
          let currentY = e.touches[0].clientY;
          if (currentY - startY > 100 && (window.scrollY || 0) <= 0) {
            startY = 999999; // debounce single drag
            if (window.FlutterPullToRefresh) {
              window.FlutterPullToRefresh.postMessage('refresh');
            }
          }
        }
      }, { passive: true });
    })();
  ''';
}
