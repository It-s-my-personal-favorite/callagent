import '../../domain/claims_models.dart';

class GuidedForms {
  static List<FormQuestion> questionsForClaim(String claimId) {
    switch (claimId) {
      case 'bafoeg':
        return [
          FormQuestion(id: 'fullName', label: 'Wie ist dein voller Name?'),
          FormQuestion(id: 'uni', label: 'An welcher Hochschule studierst du?'),
          FormQuestion(id: 'semester', label: 'In welchem Semester bist du?'),
          FormQuestion(id: 'income', label: 'Wie hoch ist dein monatliches Einkommen?'),
        ];
      case 'kindergeld':
        return [
          FormQuestion(id: 'fullName', label: 'Wie ist dein voller Name?'),
          FormQuestion(id: 'childName', label: 'Wie heisst dein Kind?'),
          FormQuestion(id: 'childBirth', label: 'Geburtsdatum des Kindes?'),
          FormQuestion(id: 'address', label: 'Deine Adresse?'),
        ];
      case 'kinderzuschlag':
        return [
          FormQuestion(id: 'fullName', label: 'Wie ist dein voller Name?'),
          FormQuestion(id: 'childrenCount', label: 'Wie viele Kinder leben im Haushalt?'),
          FormQuestion(id: 'rent', label: 'Wie hoch ist eure Warmmiete?'),
          FormQuestion(id: 'income', label: 'Monatliches Haushaltsnettoeinkommen?'),
        ];
      case 'pflege':
        return [
          FormQuestion(id: 'carePerson', label: 'Für wen wird Pflege beantragt?'),
          FormQuestion(id: 'relation', label: 'In welchem Verhältnis stehst du zur Person?'),
          FormQuestion(id: 'careLevel', label: 'Ist ein Pflegegrad bekannt?'),
          FormQuestion(id: 'supportNeed', label: 'Welche Unterstützung wird benötigt?'),
        ];
      default:
        return [
          FormQuestion(id: 'fullName', label: 'Wie ist dein voller Name?'),
        ];
    }
  }
}
