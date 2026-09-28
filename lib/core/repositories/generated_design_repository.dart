import '../models/generated_design.dart';

abstract class GeneratedDesignRepository {
  Future<List<GeneratedDesign>> getDesigns({String? companyId});
  Future<GeneratedDesign?> getDesignById(String id);
  Future<GeneratedDesign> createDesign(GeneratedDesign design);
  Future<GeneratedDesign> updateDesign(GeneratedDesign design);
  Future<void> deleteDesign(String id);
  Stream<List<GeneratedDesign>> watchDesigns({String? companyId});
}
