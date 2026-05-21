import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_data.dart';
import '../../widgets/themed_app_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token != null) {
      await context.read<DashboardProvider>().fetchDashboardData(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'TABLEAU DE BORD ADMIN'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.masYellow,
          child: Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.stats == null) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.masYellow));
              }

              if (provider.error != null && provider.stats == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur: ${provider.error}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _refreshData, child: const Text('Réessayer')),
                    ],
                  ),
                );
              }

              final stats = provider.stats;
              if (stats == null) return const SizedBox.shrink();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    _buildKPIGrid(stats),
                    const SizedBox(height: 24),

                    // Evolution Chart
                    _buildChartSection(
                      title: 'Évolution des Adhérents',
                      chart: _buildLineChart(provider.evolution),
                    ),
                    const SizedBox(height: 24),

                    // Revenue Chart
                    _buildChartSection(
                      title: 'Revenus Mensuels (DH)',
                      chart: _buildBarChart(provider.revenus),
                    ),
                    const SizedBox(height: 24),

                    // Top Players / Active Players placeholder
                    const Text(
                      'Dernières Activités',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.masYellow,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(DashboardStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard('Joueurs', stats.totalJoueurs.toString(), Icons.people),
        _buildKPICard('Équipes', stats.totalEquipes.toString(), Icons.groups),
        _buildKPICard('Entraînements', stats.totalEntrainements.toString(), Icons.fitness_center),
        _buildKPICard('Revenus', '${stats.totalRevenus.round()} DH', Icons.account_balance_wallet_outlined),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon) {
    return Container(
      decoration: AppTheme.containerDecoration(context, borderRadius: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.masYellow, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.containerDecoration(context, borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<EvolutionData> data) {
    if (data.isEmpty) return const Center(child: Text('Pas de données'));
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(data[index].mois, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
            isCurved: true,
            color: AppTheme.masYellow,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.masYellow.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<RevenuData> data) {
    if (data.isEmpty) return const Center(child: Text('Pas de données'));
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(data[index].mois, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.montant,
                color: AppTheme.masYellow,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.masYellow,
              child: Icon(Icons.flash_on, color: AppTheme.masBlack),
            ),
            title: Text(
              'Activité ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Détails de l\'activité administrative...'),
            trailing: const Text('1h', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ),
        );
      },
    );
  }
}
