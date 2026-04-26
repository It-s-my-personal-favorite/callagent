enum PersonaType { student, singleParent, careCase }

class UserProfile {
  UserProfile({
    required this.persona,
    required this.age,
    required this.isStudent,
    required this.isSingleParent,
    required this.childrenCount,
    required this.monthlyIncome,
    required this.forOtherPerson,
    required this.hasCareCaseInFamily,
  });

  final PersonaType persona;
  final int age;
  final bool isStudent;
  final bool isSingleParent;
  final int childrenCount;
  final int monthlyIncome;
  final bool forOtherPerson;
  final bool hasCareCaseInFamily;
}

enum EligibilityConfidence { likely, check, unlikely }

class EligibilityResult {
  EligibilityResult({
    required this.claimId,
    required this.title,
    required this.confidence,
    required this.reason,
  });

  final String claimId;
  final String title;
  final EligibilityConfidence confidence;
  final String reason;
}

class FormQuestion {
  FormQuestion({
    required this.id,
    required this.label,
    this.hint = '',
  });

  final String id;
  final String label;
  final String hint;
}
