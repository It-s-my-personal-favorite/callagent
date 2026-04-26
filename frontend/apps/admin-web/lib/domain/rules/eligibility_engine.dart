import '../claims_models.dart';

class EligibilityEngine {
  List<EligibilityResult> evaluate(UserProfile profile) {
    final results = <EligibilityResult>[];

    if (profile.isStudent && profile.age <= 35 && profile.monthlyIncome < 1400) {
      results.add(
        EligibilityResult(
          claimId: 'bafoeg',
          title: 'BAföG',
          confidence: EligibilityConfidence.likely,
          reason: 'Studium und Einkommen sprechen für eine mögliche Förderung.',
        ),
      );
    } else if (profile.isStudent) {
      results.add(
        EligibilityResult(
          claimId: 'bafoeg',
          title: 'BAföG',
          confidence: EligibilityConfidence.check,
          reason: 'Studium vorhanden, aber Einkommen/Alter sollte genau geprüft werden.',
        ),
      );
    }

    if (profile.isSingleParent && profile.childrenCount > 0) {
      results.add(
        EligibilityResult(
          claimId: 'kindergeld',
          title: 'Kindergeld',
          confidence: EligibilityConfidence.likely,
          reason: 'Alleinerziehend mit Kind(ern) ist ein starker Indikator.',
        ),
      );

      results.add(
        EligibilityResult(
          claimId: 'kinderzuschlag',
          title: 'Kinderzuschlag',
          confidence: profile.monthlyIncome < 2500
              ? EligibilityConfidence.check
              : EligibilityConfidence.unlikely,
          reason: profile.monthlyIncome < 2500
              ? 'Einkommenslage sollte geprüft werden.'
              : 'Bei höherem Einkommen meist nicht prioritär.',
        ),
      );
    }

    if (profile.hasCareCaseInFamily) {
      results.add(
        EligibilityResult(
          claimId: 'pflege',
          title: 'Pflege-Unterstützung',
          confidence: EligibilityConfidence.check,
          reason: 'Pflegefall erkannt, Anspruch sollte fallbezogen geprüft werden.',
        ),
      );
    }

    return results;
  }
}
