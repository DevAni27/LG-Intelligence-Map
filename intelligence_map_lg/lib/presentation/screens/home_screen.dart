import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import '../../presentation/blocs/events/events_bloc.dart';
import '../../presentation/blocs/events/events_event.dart';
import '../../presentation/blocs/events/events_state.dart';
import '../widgets/event_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/top_regions_card.dart';
import '../../core/utils/top_region_helper.dart';
import '../widgets/daily_pulse_card.dart';
import '../widgets/shimmer_loader.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          if (state.status == EventsStatus.loading && state.totalEvents == 0) {
            return _buildLoadingState();
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: const Color(0xFF0D1421),
            onRefresh: () async {
              context.read<EventsBloc>().add(FetchAllEvents());

              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              slivers: [
                //Header
                SliverToBoxAdapter(child: _buildHeader(context)),

                //Hero Banner Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _buildHeroBanner(context, state),
                  ),
                ),

                //Stat Cards Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: _buildStatsGrid(state),
                  ),
                ),

                //Daily Global Pulse Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: DailyPulseCard(),
                  ),
                ),

                //Severity Breakdown card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: _buildSeverityBreakdownCard(state),
                  ),
                ),

                //Top Active Regions card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: TopRegionCard(
                      regions: TopRegionHelper.getTopRegions(
                        state.filteredEvents,
                      ),
                    ),
                  ),
                ),

                //Recent Events Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Events',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Events List
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index >= state.filteredEvents.length) return null;
                      //max 10 recent events
                      if (index >= 10) return null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: EventCard(event: state.filteredEvents[index]),
                      );
                    }, childCount: state.filteredEvents.length.clamp(0, 10)),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Global Pulse',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  fontSize: 28,
                ),
              ),
              Text(
                'Monitoring global events in real-time',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          const ConnectionStatus(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, EventsState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        // Muted, deep gradient — not eye-searing
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E4D6E), Color(0xFF0A3550), Color(0xFF062338)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),

        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ' TOTAL ACTIVE EVENTS',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.totalEvents}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Worldwide right now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.public_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(EventsState state) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.waves,
            label: 'Earthquakes',
            value: '${state.earthquakeCount}',
            iconColor: AppTheme.earthquakeColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Disasters',
            value: '${state.disasterCount}',
            iconColor: AppTheme.wildfireColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.coronavirus_outlined,
            label: 'Disease Alerts',
            value: '${state.diseaseCount}',
            iconColor: AppTheme.diseaseColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBreakdownCard(EventsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Severity Breakdown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSeverityRow(
            label: 'Critical',
            count: state.criticalCount,
            color: const Color(0xFFEF4444),
          ),
          _buildSeverityRow(
            label: 'High',
            count: state.highCount,
            color: const Color(0xFFF97316),
          ),
          _buildSeverityRow(
            label: 'Medium',
            count: state.mediumCount,
            color: const Color(0xFFEAB308),
          ),
          _buildSeverityRow(
            label: 'Low',
            count: state.lowCount,
            color: const Color(0xFF22C55E),
          ),
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
          //colored dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),

          //severity label
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 1),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Expanded(child: SizedBox()),

          //severity count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
          const Icon(Icons.cloud_off, size: 48, color: AppTheme.textTertiary),
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
            onPressed: () => context.read<EventsBloc>().add(FetchAllEvents()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        // Header skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                ShimmerBox(width: 38, height: 38, borderRadius: 10),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 24, borderRadius: 8),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 220, height: 13, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Hero banner skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: ShimmerBox(
              width: double.infinity,
              height: 130,
              borderRadius: 22,
            ),
          ),
        ),

        // Stat grid skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: List.generate(
                4,
                (_) => ShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 18,
                ),
              ),
            ),
          ),
        ),

        // Daily pulse skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ShimmerBox(
              width: double.infinity,
              height: 82,
              borderRadius: 20,
            ),
          ),
        ),

        // Severity skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ShimmerBox(
              width: double.infinity,
              height: 160,
              borderRadius: 20,
            ),
          ),
        ),

        // Events label skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: ShimmerBox(width: 130, height: 20, borderRadius: 8),
          ),
        ),

        // Event card skeletons
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: ShimmerBox(
                width: double.infinity,
                height: 72,
                borderRadius: 18,
              ),
            ),
            childCount: 5,
          ),
        ),

        // Loading message at bottom
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Fetching live events from USGS, NASA & WHO...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
