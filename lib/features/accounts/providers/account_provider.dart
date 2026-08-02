import 'dart:async'; 
import 'package:drift/drift.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../core/database/app_database.dart'; 
import '../../../core/database/database_provider.dart'; 
import '../services/account_service.dart'; 

final accountServiceProvider = Provider<AccountService>((ref) {   
  final db = ref.watch(databaseProvider);   
  return AccountService(db); 
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {   
  return ref.watch(accountServiceProvider).watchAccounts(); 
});

class AccountActionNotifier extends AsyncNotifier<void> {   
  late AccountService _service;   
  
  @override   
  FutureOr<void> build() {     
    _service = ref.watch(accountServiceProvider);   
  }

  Future<bool> saveAccount({     
    String? existingId,     
    required String name,     
    required String providerName,     
    required String type,     
    required String last4,     
    required double balance,     
    double? creditLimit,     
    int? billDate,     
    int? dueDate,   
  }) async {     
    state = const AsyncLoading();          
    
    state = await AsyncValue.guard(() async {       
      if (existingId == null) {         
        await _service.addAccount(           
          name: name, providerName: providerName, type: type, last4: last4,            
          balance: balance, creditLimit: creditLimit, billDate: billDate, dueDate: dueDate         
        );       
      } else {         
        final db = ref.read(databaseProvider);         
        final existing = await (db.select(db.accounts)..where((t) => t.id.equals(existingId))).getSingle();                  
        
        final updated = existing.copyWith(           
          name: name, providerName: providerName, type: type, last4: last4,           
          balance: balance, creditLimit: Value(creditLimit), billDate: Value(billDate), dueDate: Value(dueDate)         
        );         
        await _service.updateAccount(updated);       
      }     
    });     
    return !state.hasError;   
  }

  Future<void> deleteAccount(String id) async {     
    state = const AsyncLoading();     
    state = await AsyncValue.guard(() => _service.deleteAccount(id));   
  }

  Future<void> reorderAccounts(List<Account> orderedList) async {     
    final updatedAccounts = <Account>[];     
    for (int i = 0; i < orderedList.length; i++) {       
      updatedAccounts.add(orderedList[i].copyWith(displayOrder: i));     
    }          
    await AsyncValue.guard(() => _service.reorderAccounts(updatedAccounts)); 
  }

  // --- NEW: Saves BOTH Order and Visibility states ---
  Future<void> updateAccountPreferences(List<Account> modifiedList) async {
    final updatedAccounts = <Account>[];     
    for (int i = 0; i < modifiedList.length; i++) {       
      // Overwrite displayOrder based on the new index, preserve the isHidden flag
      updatedAccounts.add(modifiedList[i].copyWith(displayOrder: i));     
    }          
    await AsyncValue.guard(() => _service.reorderAccounts(updatedAccounts)); 
  }
}

final accountActionProvider = AsyncNotifierProvider<AccountActionNotifier, void>(   
  () => AccountActionNotifier(), 
);