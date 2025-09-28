import 'package:flutter/material.dart';
import 'package:velix_i18n/i18n/i18n.dart';

import '../components/panel_header.dart';

class BottomErrorDisplay extends StatelessWidget {
  final List<String> errors;
  final VoidCallback onClose;

  const BottomErrorDisplay({super.key, required this.onClose, this.errors = const ["ocuh"]});

  @override
  Widget build(BuildContext context) {
    //if (errors.isEmpty) return const SizedBox.shrink();

      return PanelContainer(
        title: "editor:docks.errors.label".tr(),
        onClose: onClose,
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          shrinkWrap: true, // important for docking panel
          itemCount: errors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final error = errors[index];
            final isWarning = error.toLowerCase().contains("warning"); // simple heuristic
            return InkWell(
              //onTap: () => onErrorTap?.call(error),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isWarning ? Colors.orange.shade700 : Colors.red.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

/*
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: Colors.red.shade600,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (e) => Text(
                  e,
                  style: const TextStyle(color: Colors.white),
                ),
              )
                  .toList(),
            ),
          ),
        ),
      ),
    );
    */
  }
}
