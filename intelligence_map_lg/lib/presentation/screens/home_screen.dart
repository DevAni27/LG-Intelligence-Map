import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../logic/blocs/events/events_event.dart';
import '../../logic/blocs/events/events_state.dart';
import '../widgets/event_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/top_regions_card.dart';
import '../../core/utils/top_region_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<EventsBloc>().add(FetchAllEvents());
              // Wait a bit for the fetch to complete
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global Pulse',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitoring global events in real-time',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const ConnectionStatus(),
                      ],
                    ),
                  ),
                ),

                // ── Stat Cards Grid ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildStatsGrid(state),
                  ),
                ),

                //Severity Breakdown card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildSeverityBreakdownCard(state),
                  ),
                ),

                //Top Active Regions card

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TopRegionCard(
                      regions: TopRegionHelper.getTopRegions(state.filteredEvents),
                    ),
                  ),
                ),
            

                // ── Daily Global Pulse Card ─────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildDailyPulseCard(context),
                  ),
                ),

                // ── Recent Events Header ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Events',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to full events list
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Events List or Loading ──────────────────
                if (state.status == EventsStatus.loading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (state.status == EventsStatus.error)
                  SliverToBoxAdapter(
                    child: _buildErrorWidget(context, state.errorMessage),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.filteredEvents.length) return null;
                        // Show max 10 recent events on the home screen
                        if (index >= 10) return null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: EventCard(event: state.filteredEvents[index]),
                        );
                      },
                      childCount:
                          state.filteredEvents.length.clamp(0, 10),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(EventsState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        StatCard(
          icon: Icons.public,
          label: 'Active Events',
          value: '${state.totalEvents}',
          iconColor: AppTheme.primary,
        ),
        StatCard(
          icon: Icons.waves,
          label: 'Earthquakes',
          value: '${state.earthquakeCount}',
          iconColor: AppTheme.earthquakeColor,
        ),
        StatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Disasters',
          value: '${state.disasterCount}',
          iconColor: AppTheme.wildfireColor,
        ),
        StatCard(
          icon: Icons.coronavirus_outlined,
          label: 'Disease Alerts',
          value: '${state.diseaseCount}',
          iconColor: AppTheme.diseaseColor,
        ),
      ],
    );
  }

  Widget _buildSeverityBreakdownCard(EventsState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardColor,         
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.06),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Severity Breakdown",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 2,
          ),
        ),
        _buildSeverityRow(label: 'Critical', count: state.criticalCount, color: const Color(0xFFEF4444)),
        _buildSeverityRow(label: 'High',     count: state.highCount,     color: const Color(0xFFF97316)),
        _buildSeverityRow(label: 'Medium',   count: state.mediumCount,   color: const Color(0xFFEAB308)),
        _buildSeverityRow(label: 'Low',      count: state.lowCount,      color: const Color(0xFF22C55E)),
      ],
    ),
  );
}

  Widget _buildSeverityRow({
  required String label,
  required int count,
  required Color color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        //the colored dot
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),

        //the severity label
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 17),
        ),

        
        const Expanded(child: SizedBox()),

        // the severity count
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDailyPulseCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Global Pulse',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-generated 60s briefing',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Coming in Phase 4',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String? message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Check your internet connection and try again.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<EventsBloc>().add(FetchAllEvents());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
