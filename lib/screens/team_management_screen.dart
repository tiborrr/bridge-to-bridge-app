import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../services/api_service.dart';
import '../utils/result.dart';
import '../widgets/app_drawer.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  bool _isLoading = true;
  List<TeamModel> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final apiService = context.read<ApiService>();
    final result = await apiService.fetchMyTeams();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case Success(value: final teams):
            _teams = teams;
          case Failure(exception: final e):
            // Fallback for errors
            debugPrint('Fout bij laden teams: $e');
        }
      });
    }
  }

  void _showInviteDialog(TeamModel team) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Nodig lid uit voor ${team.name}'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'E-mailadres',
              hintText: 'bijv. roeier@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                
                Navigator.pop(ctx);
                _inviteMember(team.id, email);
              },
              child: const Text('Uitnodigen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _inviteMember(String teamId, String email) async {
    setState(() {
      _isLoading = true;
    });
    
    final apiService = context.read<ApiService>();
    final result = await apiService.inviteTeamMember(teamId, email);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      switch (result) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uitnodiging verstuurd naar $email!')),
          );
        case Failure():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Er is een fout opgetreden bij het uitnodigen.')),
          );
      }
    }
  }

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();
    String selectedBoatType = '8+'; // Default
    final boatTypes = ['1x', '2x', '2-', '4x', '4-', '4+', '8+'];

    final apiService = context.read<ApiService>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Nieuw Team'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Team Naam'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBoatType,
                    decoration: const InputDecoration(labelText: 'Boot Type'),
                    items: boatTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedBoatType = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuleren'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    Navigator.pop(dialogContext); // Close dialog
                    setState(() => _isLoading = true);
                    
                    final result = await apiService.createTeam(nameController.text, selectedBoatType);
                    
                    if (mounted) {
                      switch (result) {
                        case Success():
                          await _loadTeams();
                        case Failure(exception: final e):
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Er is een fout opgetreden bij het aanmaken van het team: $e'))
                          );
                      }
                    }
                  },
                  child: const Text('Aanmaken'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Team'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1D3261)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Je zit nog niet in een team.'),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _showCreateTeamDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF021C4B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Maak een Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text('Type: ${team.boatType}'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.people, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Text('Teamleden'),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _showInviteDialog(team),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('+ Nodig uit'),
                                ),
                              ],
                            ),
                            // In a full implementation we would also list the members here by calling fetchTeamMembers.
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
