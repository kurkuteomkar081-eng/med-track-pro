import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Top Linear Progress Indicator for Web Page Loading
class WebProgressIndicator extends StatelessWidget {
  final double progress;
  final bool isVisible;

  const WebProgressIndicator({
    super.key,
    required this.progress,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible && progress < 1.0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        height: 3.5,
        child: LinearProgressIndicator(
          value: progress > 0.0 ? progress : null,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
        ),
      ),
    );
  }
}

/// Centered Loading Spinner Overlay for Full Page Navigation / Initial Load
class LoadingSpinnerOverlay extends StatelessWidget {
  final String message;

  const LoadingSpinnerOverlay({
    super.key,
    this.message = 'Loading MedTrack Pro...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                  backgroundColor: AppConstants.primaryColor.withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
