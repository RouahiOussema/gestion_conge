import 'package:flutter/material.dart';
import '../../core/services/rh_service.dart';
import '../../core/models/user.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final RHService _rhService = RHService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _matriculeController = TextEditingController();
  String _selectedRole = 'employe';
  String? _selectedManagerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des utilisateurs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v!.contains('@') ? null : 'Email invalide',
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Mot de passe'),
                        obscureText: true,
                        validator: (v) => v!.length >= 6 ? null : 'Minimum 6 caractères',
                      ),
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      TextFormField(
                        controller: _prenomController,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                      ),
                      TextFormField(
                        controller: _matriculeController,
                        decoration: const InputDecoration(labelText: 'Matricule'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'employe', child: Text('Employé')),
                          DropdownMenuItem(value: 'responsable', child: Text('Responsable')),
                        ],
                        onChanged: (val) => setState(() => _selectedRole = val!),
                        decoration: const InputDecoration(labelText: 'Rôle'),
                      ),
                      if (_selectedRole == 'employe')
                        StreamBuilder<List<User>>(
                          stream: _rhService.getManagers(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final managers = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              value: _selectedManagerId,
                              hint: const Text('Choisir un responsable'),
                              items: managers.map((m) {
                                return DropdownMenuItem(
                                  value: m.uid,
                                  child: Text('${m.prenom} ${m.nom} (${m.matricule})'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedManagerId = val),
                              decoration: const InputDecoration(labelText: 'Responsable parent'),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _createUser,
                        child: const Text('Créer l\'utilisateur'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<User>>(
                stream: _rhService.getEmployees(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        title: Text('${u.prenom} ${u.nom}'),
                        subtitle: Text('Matricule: ${u.matricule} - Rôle: ${u.role}'),
                        trailing: Text('Solde: ${u.soldeConges} jours'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _rhService.createUser(
        _emailController.text,
        _passwordController.text,
        _nomController.text,
        _prenomController.text,
        _matriculeController.text,
        _selectedRole,
        _selectedRole == 'employe' ? _selectedManagerId : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur créé avec succès')),
      );
      // Réinitialiser les champs
      _emailController.clear();
      _passwordController.clear();
      _nomController.clear();
      _prenomController.clear();
      _matriculeController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}