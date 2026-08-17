import 'dart:convert';

abstract class VaultPayload {
  Map<String, dynamic> toJson();
}

class CredentialPayload extends VaultPayload {
  final String username;
  final String password;
  final String? secondaryPassword;
  final String? urlOrApp;
  final String? notes;

  CredentialPayload({
    required this.username,
    required this.password,
    this.secondaryPassword,
    this.urlOrApp,
    this.notes,
  });

  factory CredentialPayload.fromJson(Map<String, dynamic> json) {
    return CredentialPayload(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      secondaryPassword: json['secondaryPassword'],
      urlOrApp: json['urlOrApp'],
      notes: json['notes'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'secondaryPassword': secondaryPassword,
    'urlOrApp': urlOrApp,
    'notes': notes,
  };
}

class CardPayload extends VaultPayload {
  final String bankProvider;
  final String cardNumber;
  final String validFrom;
  final String validTo;
  final String cvv;
  final String pin;
  final String? otherDetails;

  CardPayload({
    required this.bankProvider,
    required this.cardNumber,
    required this.validFrom,
    required this.validTo,
    required this.cvv,
    required this.pin,
    this.otherDetails,
  });

  factory CardPayload.fromJson(Map<String, dynamic> json) {
    return CardPayload(
      bankProvider: json['bankProvider'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
      validFrom: json['validFrom'] ?? '',
      validTo: json['validTo'] ?? '',
      cvv: json['cvv'] ?? '',
      pin: json['pin'] ?? '',
      otherDetails: json['otherDetails'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'bankProvider': bankProvider,
    'cardNumber': cardNumber,
    'validFrom': validFrom,
    'validTo': validTo,
    'cvv': cvv,
    'pin': pin,
    'otherDetails': otherDetails,
  };
}

class DecryptedVaultRecord {
  final String id;
  final String recordType;
  final String recordName;
  final VaultPayload payload;
  final DateTime createdAt;

  DecryptedVaultRecord({
    required this.id,
    required this.recordType,
    required this.recordName,
    required this.payload,
    required this.createdAt,
  });
}
