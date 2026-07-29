import 'package:flutter/material.dart';
import '../../core/services/rh_service.dart';
import '../../core/models/leave_request.dart';

class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  final RHService _rhService = RHService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes à valider définitivement')),
      body: StreamBuilder<List<LeaveRequest>>(
        stream: _rhService.getPendingForRH(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune demande en attente de validation RH.'));
          }
          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${req.employeNom} - ${req.type}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Du ${req.dateDebut.toLocal().toString().split(' ')[0]} '
                           'au ${req.dateFin.toLocal().toString().split(' ')[0]}'),
                      Text('Motif : ${req.motif}'),
                      Text('Jours : ${req.nbJoursOuvres}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _showDecisionDialog(req.id, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _showDecisionDialog(req.id, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDecisionDialog(String requestId, bool accept) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(accept ? 'Valider définitivement ?' : 'Refuser ?'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Commentaire (optionnel)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _rhService.validateRequest(
                requestId,
                accept,
                comment: commentController.text.isEmpty ? null : commentController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(accept ? 'Demande validée (solde déduit si payé)' : 'Demande refusée'),
                ),
              );
            },
            child: Text(accept ? 'Valider' : 'Refuser'),
          ),
        ],
      ),
    );
  }
}