class User {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String matricule;
  final String role; // 'employe', 'responsable', 'rh'
  final String? managerId;
  final double soldeConges;
  final DateTime dateEmbauche;

  User({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.matricule,
    required this.role,
    this.managerId,
    this.soldeConges = 0,
    required this.dateEmbauche,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      matricule: data['matricule'] ?? '',
      role: data['role'] ?? 'employe',
      managerId: data['managerId'],
      soldeConges: (data['soldeConges'] ?? 0).toDouble(),
      dateEmbauche: (data['dateEmbauche'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'matricule': matricule,
      'role': role,
      'managerId': managerId,
      'soldeConges': soldeConges,
      'dateEmbauche': Timestamp.fromDate(dateEmbauche),
    };
  }
}