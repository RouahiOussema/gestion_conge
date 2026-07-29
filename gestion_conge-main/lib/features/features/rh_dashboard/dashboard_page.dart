import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord RH')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Demandes totales',
              Icons.list,
              Colors.blue,
              FirebaseFirestore.instance.collection('leaveRequests'),
            ),
            _buildStatCard(
              'En attente RH',
              Icons.pending,
              Colors.orange,
              FirebaseFirestore.instance
                  .collection('leaveRequests')
                  .where('statut', isEqualTo: 'ACCEPTE_RESP'),
            ),
            _buildStatCard(
              'Employés',
              Icons.people,
              Colors.green,
              FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'employe'),
            ),
            _buildStatCard(
              'Responsables',
              Icons.manage_accounts,
              Colors.purple,
              FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'responsable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, IconData icon, Color color, Query query) {
    return Card(
      elevation: 3,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(label, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}