import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/config/production_config.dart';
import 'legal_documents.dart';

enum LegalDocKind { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.kind,
    this.production = ProductionConfig.unconfigured,
  });

  final LegalDocKind kind;
  final ProductionConfig production;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = kind == LegalDocKind.privacy;
    final title =
        isPrivacy ? LegalPlaceholders.privacyTitle : LegalPlaceholders.termsTitle;
    final body =
        isPrivacy ? LegalPlaceholders.privacyBody : LegalPlaceholders.termsBody;
    final url = isPrivacy
        ? production.privacyPolicyUrl
        : production.termsOfServiceUrl;

    return Scaffold(
      appBar: AppBar(title: Text(isPrivacy ? 'Privacy' : 'Terms')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MergeEmpireTheme.caramel.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MergeEmpireTheme.roast),
            ),
            child: Text(
              url.isEmpty
                  ? 'No owner URL configured — showing PLACEHOLDER text only.'
                  : 'Owner URL (verify before release): $url',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}
