import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/company.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/company_card_icons.dart';

/// Tela S03 — Lista de Empresas do NFC Ops.
/// Reproduz rigorosamente o layout e a geometria da Prancha 01.
class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ativa'; // 'ativa', 'todas', 'lead', 'inativa'
  String? _selectedCategory;
  String? _selectedCity;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesStreamProvider);
    final allCompanies = companiesAsync.value ?? [];

    // Aplica filtro de busca, status, categoria e cidade em tempo real
    final filteredCompanies = allCompanies.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesName = c.tradeName.toLowerCase().contains(q);
        final matchesCategory = c.category.toLowerCase().contains(q);
        final matchesCity = c.city?.toLowerCase().contains(q) ?? false;
        final cleanPhone = c.phone?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
        final cleanQ = q.replaceAll(RegExp(r'[^\d]'), '');
        final matchesPhone = cleanQ.isNotEmpty && cleanPhone.contains(cleanQ);
        if (!matchesName && !matchesCategory && !matchesCity && !matchesPhone) {
          return false;
        }
      }
      if (_selectedCategory != null &&
          c.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
        return false;
      }
      if (_selectedCity != null &&
          (c.city == null || c.city!.toLowerCase() != _selectedCity!.toLowerCase())) {
        return false;
      }
      if (_selectedStatusFilter == 'ativa') {
        final st = c.status.toLowerCase();
        if (st == 'cancelado' || st == 'inativo' || st == 'pausado') {
          return false;
        }
      } else if (_selectedStatusFilter != 'todas') {
        if (c.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabeçalho: "Empresas", "18 cadastradas" e sino de notificações
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 27, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Empresas',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${allCompanies.length} cadastradas',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/activities'),
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222422),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF333333),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 27),

            // 2. Barra de pesquisa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF161815),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: const Color(0xFF242623),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nome, telefone ou código',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFFB3B7B7),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 3. Chips de filtro: Ativas, Categoria, Cidade
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: _selectedStatusFilter == 'ativa' ? 'Ativas' : 'Todas',
                      isSelected: true,
                      onTap: () {
                        setState(() {
                          _selectedStatusFilter =
                              _selectedStatusFilter == 'ativa' ? 'todas' : 'ativa';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: _selectedCategory ?? 'Categoria',
                      isSelected: _selectedCategory != null,
                      onTap: () => _showCategoryFilterModal(context, allCompanies),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: _selectedCity ?? 'Cidade',
                      isSelected: _selectedCity != null,
                      onTap: () => _showCityFilterModal(context, allCompanies),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 4. Lista de empresas
            Expanded(
              child: allCompanies.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161715),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF282A26)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.orangeAction.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.building2,
                                  color: AppColors.orangeAction,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma empresa cadastrada',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Cadastre sua primeira parceira para gerenciar serviços, placas NFC e pedidos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => context.push('/companies/new'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orangeAction,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  '+ Cadastrar Empresa',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : filteredCompanies.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma empresa encontrada para o filtro selecionado.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredCompanies.length,
                          itemBuilder: (context, index) {
                            final company = filteredCompanies[index];
                            final isFeatured = index == 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: _buildCompanyCard(
                                context: context,
                                company: company,
                                isFeatured: isFeatured,
                              ),
                            );
                          },
                        ),
            ),

            // 5. Botão inferior Laranja: "+ Nova empresa"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Semantics(
                button: true,
                label: 'Nova empresa',
                child: Material(
                  color: AppColors.orangeAction,
                  borderRadius: BorderRadius.circular(27),
                  child: InkWell(
                    onTap: () => context.push('/companies/new'),
                    borderRadius: BorderRadius.circular(27),
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Nova empresa',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF1E201D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF2C2F2A),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF10110F) : const Color(0xFFECEBDE),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected ? const Color(0xFF10110F) : const Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIcon(Company company, bool isFeatured) {
    final cat = company.category.toLowerCase();
    final name = company.tradeName.toLowerCase();
    final iconColor = isFeatured ? const Color(0xFF10110F) : const Color(0xFFECEBDE);

    if (cat.contains('oficina') || cat.contains('mecânica') || name.contains('auto center')) {
      return CrossedWrenchesWidget(color: iconColor, size: 34);
    }
    if (cat.contains('café') || cat.contains('cafeteria') || name.contains('aurora')) {
      return CoffeeCupWidget(color: iconColor, size: 34);
    }
    if (cat.contains('barbearia') || cat.contains('corte') || name.contains('norte')) {
      return VerticalScissorsWidget(color: iconColor, size: 34);
    }
    if (cat.contains('pet') || cat.contains('veterinária') || name.contains('vila')) {
      return PawPrintWidget(color: iconColor, size: 34);
    }
    return Icon(
      LucideIcons.building2,
      color: iconColor,
      size: 28,
    );
  }

  Widget _buildCompanyCard({
    required BuildContext context,
    required Company company,
    required bool isFeatured,
  }) {
    final isLead = company.status.toLowerCase() == 'lead';

    if (isFeatured) {
      // Card destacado Warm Cream (#ECEBDE)
      return InkWell(
        onTap: () => context.push('/companies/${company.id}'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 100,
          padding: const EdgeInsets.only(left: 7, right: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCream,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.orangeAction,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _buildCardIcon(company, true),
                ),
              ),
              const SizedBox(width: 27),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      company.tradeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10110F),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${company.category} • ${company.city ?? "Barueri"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5C5E5A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4DC621),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${company.servicesCount} serviços • ',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5C5E5A),
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Ativa',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF757575),
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    // Card Dark (#171816)
    return InkWell(
      onTap: () => context.push('/companies/${company.id}'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 100,
        padding: const EdgeInsets.only(left: 7, right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF171816),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF242623),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF121311),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF20221E),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: _buildCardIcon(company, false),
              ),
            ),
            const SizedBox(width: 27),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    company.tradeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${company.category} • ${company.city ?? "Barueri"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isLead ? const Color(0xFFF59E0B) : const Color(0xFF4DC621),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${company.servicesCount} serviços • ',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              TextSpan(
                                text: isLead ? 'Lead' : 'Ativa',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isLead ? const Color(0xFFFBBF24) : const Color(0xFF4ADE80),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterModal(BuildContext context, List<Company> allCompanies) {
    final categories = allCompanies.map((c) => c.category).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161815),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar por Categoria',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedCategory != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedCategory = null);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Limpar',
                            style: TextStyle(color: AppColors.orangeAction),
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Todas as categorias', style: TextStyle(color: Colors.white)),
                        trailing: _selectedCategory == null
                            ? const Icon(Icons.check, color: Color(0xFFFACC15))
                            : null,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          Navigator.pop(ctx);
                        },
                      ),
                      ...categories.map((cat) {
                        final isSel = _selectedCategory?.toLowerCase() == cat.toLowerCase();
                        return ListTile(
                          title: Text(cat, style: const TextStyle(color: Colors.white)),
                          trailing: isSel ? const Icon(Icons.check, color: Color(0xFFFACC15)) : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCityFilterModal(BuildContext context, List<Company> allCompanies) {
    final cities = allCompanies
        .map((c) => c.city)
        .where((city) => city != null && city.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161815),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar por Cidade',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedCity != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedCity = null);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Limpar',
                            style: TextStyle(color: AppColors.orangeAction),
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Todas as cidades', style: TextStyle(color: Colors.white)),
                        trailing: _selectedCity == null
                            ? const Icon(Icons.check, color: Color(0xFFFACC15))
                            : null,
                        onTap: () {
                          setState(() => _selectedCity = null);
                          Navigator.pop(ctx);
                        },
                      ),
                      ...cities.map((city) {
                        final isSel = _selectedCity?.toLowerCase() == city.toLowerCase();
                        return ListTile(
                          title: Text(city, style: const TextStyle(color: Colors.white)),
                          trailing: isSel ? const Icon(Icons.check, color: Color(0xFFFACC15)) : null,
                          onTap: () {
                            setState(() => _selectedCity = city);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
