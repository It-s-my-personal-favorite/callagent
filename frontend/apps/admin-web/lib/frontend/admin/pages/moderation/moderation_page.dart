import 'package:flutter/material.dart';

import '../../../../domain/admin_models.dart';
import '../../widgets/admin_common_widgets.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({
    super.key,
    required this.blockedCalls,
    required this.onUnblock,
    required this.maskNumber,
  });

  final List<CallSession> blockedCalls;
  final ValueChanged<String> onUnblock;
  final String Function(String) maskNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AdminPageContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moderation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF142246),
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                color:
                    isDark ? const Color(0xFF0D1C43) : const Color(0xFFF8FAFF),
                child: ListView.builder(
                  itemCount: blockedCalls.length,
                  itemBuilder: (context, index) {
                    final call = blockedCalls[index];
                    return ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(maskNumber(call.callerNumber)),
                      subtitle: Text(call.internalReview.note),
                      trailing: TextButton(
                        onPressed: () => onUnblock(call.id),
                        child: const Text('Entsperren'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
