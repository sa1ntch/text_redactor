import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/material_model.dart';

class StorageService {
  static const _materialsKey = 'saved_materials';

  Future<List<MaterialModel>> loadMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMaterials = prefs.getString(_materialsKey);
    if (rawMaterials == null || rawMaterials.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawMaterials) as List<dynamic>;
    final materials =
        decoded
            .map((item) => MaterialModel.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return materials;
  }

  Future<void> saveMaterial(MaterialModel material) async {
    final materials = await loadMaterials();
    final index = materials.indexWhere((item) => item.id == material.id);

    if (index == -1) {
      materials.add(material);
    } else {
      materials[index] = material;
    }

    await _persist(materials);
  }

  Future<void> deleteMaterial(String id) async {
    final materials = await loadMaterials();
    materials.removeWhere((material) => material.id == id);

    await _persist(materials);
  }

  Future<MaterialModel?> findMaterial(String id) async {
    final materials = await loadMaterials();
    for (final material in materials) {
      if (material.id == id) {
        return material;
      }
    }
    return null;
  }

  Future<void> _persist(List<MaterialModel> materials) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      materials.map((material) => material.toJson()).toList(),
    );
    await prefs.setString(_materialsKey, encoded);
  }
}
