import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/models/percentage_config_model.dart';

class SettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<PercentageConfig> getPercentageConfig() async {
    final doc = await _db
        .collection(FirebaseConstants.settings)
        .doc('percentages')
        .get();
    if (doc.exists) {
      return PercentageConfig.fromFirestore(doc);
    } else {
      return PercentageConfig.defaultConfig();
    }
  }

  Future<void> setPercentageConfig(PercentageConfig config) {
    return _db
        .collection(FirebaseConstants.settings)
        .doc('percentages')
        .set(config.toMap());
  }
}
