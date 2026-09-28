import '../models/plate_template.dart';

abstract class TemplateRepository {
  Future<List<PlateTemplate>> getTemplates({String? category, String? status});
  Future<PlateTemplate?> getTemplateById(String id);
  Future<PlateTemplate> createTemplate(PlateTemplate template);
  Future<PlateTemplate> updateTemplate(PlateTemplate template);
  Future<void> deleteTemplate(String id);
  Stream<List<PlateTemplate>> watchTemplates();
}
