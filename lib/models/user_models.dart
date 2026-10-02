class UserProfile {
  final String id;
  final String keycloakId;
  final String? email;
  final String? name;
  final List<String> preferredPositions;

  UserProfile({
    required this.id,
    required this.keycloakId,
    this.email,
    this.name,
    required this.preferredPositions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      keycloakId: json['keycloak_id'],
      email: json['email'],
      name: json['name'],
      preferredPositions: List<String>.from(json['preferred_positions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'preferred_positions': preferredPositions,
    };
  }
}

class TeamModel {
  final String id;
  final String name;
  final String boatType;

  TeamModel({
    required this.id,
    required this.name,
    required this.boatType,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'],
      name: json['name'],
      boatType: json['boat_type'],
    );
  }
}
