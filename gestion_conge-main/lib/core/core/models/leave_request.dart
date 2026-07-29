class LeaveRequest {
  final String id;
  final String employeId;
  final String employeNom;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String motif;
  final String type; // 'PAYE' ou 'NON_PAYE'
  final String statut; // 'EN_ATTENTE', 'ACCEPTE_RESP', 'REFUSE_RESP', 'VALIDE_RH', 'REFUSE_RH'
  final String? reponseResponsable;
  final String? reponseRH;
  final DateTime dateSoumission;
  final double nbJoursOuvres;

  LeaveRequest({
    required this.id,
    required this.employeId,
    required this.employeNom,
    required this.dateDebut,
    required this.dateFin,
    required this.motif,
    required this.type,
    required this.statut,
    this.reponseResponsable,
    this.reponseRH,
    required this.dateSoumission,
    required this.nbJoursOuvres,
  });

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveRequest(
      id: doc.id,
      employeId: data['employeId'] ?? '',
      employeNom: data['employeNom'] ?? '',
      dateDebut: (data['dateDebut'] as Timestamp).toDate(),
      dateFin: (data['dateFin'] as Timestamp).toDate(),
      motif: data['motif'] ?? '',
      type: data['type'] ?? 'PAYE',
      statut: data['statut'] ?? 'EN_ATTENTE',
      reponseResponsable: data['reponseResponsable'],
      reponseRH: data['reponseRH'],
      dateSoumission: (data['dateSoumission'] as Timestamp).toDate(),
      nbJoursOuvres: (data['nbJoursOuvres'] ?? 0).toDouble(),
    );
  }
}