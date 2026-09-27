enum CandidateTab { perfect, similar }

enum CandidateSort {
  recommended('Önerilen'),
  near('En Yakın'),
  rating('Puan');

  const CandidateSort(this.label);

  final String label;

  /// Spec: tapping cycles Önerilen → En Yakın → Puan → Önerilen
  CandidateSort get next => values[(index + 1) % values.length];
}

class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    required this.rating,
    required this.attend,
    required this.km,
    required this.photoUrl,
    required this.online,
    required this.perfect,
    required this.score,
    this.expectedPay,
    this.payMatches,
  });

  factory Candidate.fromJson(Map<String, dynamic> json, {required String Function(String) resolveAsset}) {
    return Candidate(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: json['rating'] as String,
      attend: json['attend'] as String,
      km: json['km'] as String,
      photoUrl: resolveAsset(json['photo'] as String),
      online: json['online'] as bool? ?? false,
      perfect: json['perfect'] as bool,
      score: (json['score'] as num).toInt(),
      expectedPay: (json['expectedPay'] as num?)?.toInt(),
      payMatches: json['payMatches'] as bool?,
    );
  }

  final String id;
  final String name;
  final String rating;
  final String attend;
  final String km;
  final String photoUrl;
  final bool online;
  final bool perfect;
  final int score;

  /// Monthly pay expectation shown in the reference ("₺25.000 / ay").
  final int? expectedPay;
  final bool? payMatches;
}

class CandidatesPage {
  const CandidatesPage({
    required this.totalPerfect,
    required this.totalSimilar,
    required this.candidates,
  });

  final int totalPerfect;
  final int totalSimilar;
  final List<Candidate> candidates;
}
