import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart' as ok;

enum ToastType {
  success,
  info,
  warning,
  error,
}

class ToastConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const ToastConfig({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });
}

// Track active toasts for proper stacking
final List<_ToastEntry> _activeToasts = [];
int _nextToastId = 0;

class _ToastEntry {
  final int id;
  final ok.ToastFuture future;

  _ToastEntry(this.id, this.future);
}

void showToast(
    String msg, {
      ToastType type = ToastType.info,
      ok.ToastPosition? position,
      Duration? duration,
    }) {
  final config = _getToastConfig(type);
  final toastId = _nextToastId++;

  // Calculate offset based on existing toasts
  final offset = _activeToasts.length * 72.0; // 72px per toast (56 height + 16 gap)

  final future = ok.showToastWidget(
    Padding(
      padding: EdgeInsets.only(bottom: 32 + offset, right: 24),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: config.iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored side bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: config.iconColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  config.icon,
                  color: config.iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Message
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    ),
    duration: duration ?? const Duration(seconds: 3),
    position: position ?? ok.ToastPosition(align: Alignment.bottomRight),
    dismissOtherToast: false,
  );

  // Track this toast
  final entry = _ToastEntry(toastId, future);
  _activeToasts.add(entry);

  // Remove from tracking when done
  Future.delayed(duration ?? const Duration(seconds: 3), () {
    _activeToasts.removeWhere((e) => e.id == toastId);
  });
}

ToastConfig _getToastConfig(ToastType type) {
  switch (type) {
    case ToastType.success:
      return const ToastConfig(
        icon: Icons.check_circle_rounded,
        backgroundColor: Color(0xFF1E293B),
        iconColor: Color(0xFF10B981),
        textColor: Colors.white,
      );
    case ToastType.info:
      return const ToastConfig(
        icon: Icons.info_rounded,
        backgroundColor: Color(0xFF1E293B),
        iconColor: Color(0xFF3B82F6),
        textColor: Colors.white,
      );
    case ToastType.warning:
      return const ToastConfig(
        icon: Icons.warning_rounded,
        backgroundColor: Color(0xFF1E293B),
        iconColor: Color(0xFFF59E0B),
        textColor: Colors.white,
      );
    case ToastType.error:
      return const ToastConfig(
        icon: Icons.error_rounded,
        backgroundColor: Color(0xFF1E293B),
        iconColor: Color(0xFFEF4444),
        textColor: Colors.white,
      );
  }
}

// Convenience methods
void showSuccessToast(String msg, {ok.ToastPosition? position, Duration? duration}) {
  showToast(msg, type: ToastType.success, position: position, duration: duration);
}

void showInfoToast(String msg, {ok.ToastPosition? position, Duration? duration}) {
  showToast(msg, type: ToastType.info, position: position, duration: duration);
}

void showWarningToast(String msg, {ok.ToastPosition? position, Duration? duration}) {
  showToast(msg, type: ToastType.warning, position: position, duration: duration);
}

void showErrorToast(String msg, {ok.ToastPosition? position, Duration? duration}) {
  showToast(msg, type: ToastType.error, position: position, duration: duration);
}

// Example usage widget
class ToastDemo extends StatelessWidget {
  const ToastDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toast Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => showSuccessToast('Operation completed successfully!'),
              icon: const Icon(Icons.check_circle),
              label: const Text('Success Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => showInfoToast('Here is some useful information'),
              icon: const Icon(Icons.info),
              label: const Text('Info Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => showWarningToast('Please review before continuing'),
              icon: const Icon(Icons.warning),
              label: const Text('Warning Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => showErrorToast('Something went wrong. Please try again.'),
              icon: const Icon(Icons.error),
              label: const Text('Error Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
