import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/leave_request.dart';

class RHService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

 
  Stream<List<LeaveRequest>> getPendingForRH() {
    return _firestore
        .collection('leaveRequests')
        .where('statut', isEqualTo: 'ACCEPTE_RESP')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequest.fromFirestore(doc))
            .toList());
  }


  Future<void> validateRequest(String requestId, bool accept,
      {String? comment}) async {
    final newStatus = accept ? 'VALIDE_RH' : 'REFUSE_RH';
    await _firestore.collection('leaveRequests').doc(requestId).update({
      'statut': newStatus,
      'reponseRH': comment ?? '',
      'dateTraitementRH': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createUser(
    String email,
    String password,
    String nom,
    String prenom,
    String matricule,
    String role,
    String? managerId,
  ) async {
    
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    await _auth.setCustomUserClaims(uid, {'role': role});

    
    final newUser = User(
      uid: uid,
      email: email,
      nom: nom,
      prenom: prenom,
      matricule: matricule,
      role: role,
      managerId: managerId,
      soldeConges: 25, 
      dateEmbauche: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(newUser.toFirestore());
  }

  Stream<List<User>> getManagers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'responsable')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  
  Stream<List<User>> getEmployees() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'employe')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }
}