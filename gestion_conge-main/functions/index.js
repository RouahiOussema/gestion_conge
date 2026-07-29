const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ---------- 1. Acquisition mensuelle de soldes (le 1er de chaque mois) ----------
exports.acquireMonthlyLeave = functions.pubsub
  .schedule('0 0 1 * *')
  .timeZone('Africa/Tunis') // adaptez
  .onRun(async (context) => {
    const usersSnapshot = await admin.firestore().collection('users')
      .where('role', 'in', ['employe', 'responsable'])
      .get();
    
    const batch = admin.firestore().batch();
    const acquisitionRate = 2.08; // jours par mois

    usersSnapshot.docs.forEach((doc) => {
      const currentBalance = doc.data().soldeConges || 0;
      const newBalance = currentBalance + acquisitionRate;
      batch.update(doc.ref, {
        soldeConges: Math.round(newBalance * 100) / 100
      });
    });

    await batch.commit();
    console.log(`${usersSnapshot.size} soldes mis à jour mensuellement.`);
    return null;
  });

// ---------- 2. Déduction automatique lors de la validation RH ----------
exports.deductLeaveOnValidation = functions.firestore
  .document('leaveRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Condition : le statut vient de passer à "VALIDE_RH" ET c'est un congé payé
    if (after.statut === 'VALIDE_RH' && before.statut !== 'VALIDE_RH' && after.type === 'PAYE') {
      const employeRef = admin.firestore().collection('users').doc(after.employeId);
      
      await admin.firestore().runTransaction(async (transaction) => {
        const employeDoc = await transaction.get(employeRef);
        const currentSolde = employeDoc.data().soldeConges || 0;
        const newSolde = currentSolde - after.nbJoursOuvres;
        
        if (newSolde < 0) {
          throw new Error('Solde insuffisant pour valider cette demande');
        }
        
        transaction.update(employeRef, { soldeConges: newSolde });
      });

      // Historique (optionnel)
      await admin.firestore().collection('users').doc(after.employeId)
        .collection('historiqueSoldes').add({
          date: admin.firestore.FieldValue.serverTimestamp(),
          variation: -after.nbJoursOuvres,
          motif: `Demande de congé validée (${after.dateDebut} - ${after.dateFin})`,
        });
    }
    return null;
  });

// ---------- 3. Fonction Callable pour vérifier le solde avant soumission ----------
exports.checkBalance = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Non authentifié');
  const { nbJours } = data;
  
  const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  const solde = userDoc.data().soldeConges || 0;
  
  return { soldeActuel: solde, suffisant: solde >= nbJours };
});

// ---------- 4. Notification à l'employé lors du changement de statut ----------
// Déclenchement sur toute mise à jour de demande (à ajouter dans la même fonction ou une séparée)
exports.sendNotificationOnStatusChange = functions.firestore
  .document('leaveRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Si le statut a changé
    if (before.statut !== after.statut) {
      const employeDoc = await admin.firestore().collection('users').doc(after.employeId).get();
      const fcmToken = employeDoc.data().fcmToken; // vous devez stocker ce token lors de la connexion de l'app

      if (fcmToken) {
        let messageBody = '';
        if (after.statut === 'VALIDE_RH') messageBody = 'Votre demande a été définitivement approuvée par le RH.';
        else if (after.statut === 'REFUSE_RH') messageBody = 'Votre demande a été refusée par le RH.';
        else if (after.statut === 'ACCEPTE_RESP') messageBody = 'Votre responsable a accepté votre demande. En attente de validation RH.';
        else if (after.statut === 'REFUSE_RESP') messageBody = 'Votre responsable a refusé votre demande.';

        const message = {
          notification: {
            title: 'Mise à jour de votre demande de congé',
            body: messageBody,
          },
          token: fcmToken,
        };
        try {
          await admin.messaging().send(message);
        } catch (error) {
          console.log('Erreur envoi FCM:', error);
        }
      }
    }
    return null;
  });