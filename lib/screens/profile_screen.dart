import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../services/api_service.dart';
import '../utils/result.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserProfile? _profile;
  
  final List<String> _availablePositions = [
    'Bakboord',
    'Stuurboord',
    'Slag',
    'Stuur / Coach'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final apiService = context.read<ApiService>();
    final result = await apiService.fetchUserProfile();
    
    if (mounted) {
      switch (result) {
        case Success(value: final profile):
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        case Failure(exception: final e):
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij laden profiel: $e')),
          );
      }
    }
  }



  Future<void> _togglePosition(String position, bool isSelected) async {
    if (_profile == null) return;
    
    // 1. Optimistic UI update
    setState(() {
      if (isSelected) {
        if (!_profile!.preferredPositions.contains(position)) {
          _profile!.preferredPositions.add(position);
        }
      } else {
        _profile!.preferredPositions.remove(position);
      }
    });

    // 2. Perform API Call on the background
    final apiService = context.read<ApiService>();
    final result = await apiService.updateUserProfile(_profile!);
    
    if (mounted) {
      switch (result) {
        case Success(value: final updated):
          // Silent success, keep the updated profile reference from server
          setState(() {
            _profile = updated;
          });
        case Failure(exception: final e):
          // 3. Revert on failure
          setState(() {
            if (isSelected) {
              _profile!.preferredPositions.remove(position);
            } else {
              _profile!.preferredPositions.add(position);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij opslaan, wijziging ongedaan gemaakt: $e')),
          );
      }
    }
  }

  Future<void> _editName() async {
    if (_profile == null) return;
    
    final TextEditingController controller = TextEditingController(text: _profile!.name ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naam wijzigen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Jouw naam'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text), 
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim() != (_profile!.name ?? '')) {
      if (!mounted) return;
      
      final updatedProfile = UserProfile(
        id: _profile!.id,
        keycloakId: _profile!.keycloakId,
        email: _profile!.email,
        name: newName.trim(),
        preferredPositions: _profile!.preferredPositions,
      );
      
      setState(() => _isLoading = true);
      final apiService = context.read<ApiService>();
      final result = await apiService.updateUserProfile(updatedProfile);
      
      if (mounted) {
        setState(() => _isLoading = false);
        switch (result) {
          case Success(value: final p):
            setState(() => _profile = p);
          case Failure(exception: final e):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fout bij opslaan naam: $e'))
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Profiel'),
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
          : _profile == null
              ? const Center(child: Text('Geen profiel gevonden.'))
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profile!.name != null && _profile!.name!.trim().isNotEmpty
                                      ? 'Welkom, ${_profile!.name}!'
                                      : 'Welkom!',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profile!.email ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF1D3261)),
                            tooltip: 'Naam bewerken',
                            onPressed: _editName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Jouw voorkeursposities',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecteer alle posities die je kunt vervullen in de boot:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _availablePositions.map((pos) {
                          final isSelected = _profile!.preferredPositions.contains(pos);
                          return FilterChip(
                            label: Text(pos),
                            selected: isSelected,
                            onSelected: (selected) => _togglePosition(pos, selected),
                            selectedColor: Colors.blue.shade100,
                            checkmarkColor: Colors.blue.shade900,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
