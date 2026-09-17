import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/auth/auth_service.dart';
import '../../services/device/device_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/medicine_image/medicine_image_service.dart';
import '../../data/repositories/repositories.dart';
import '../../main.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late DateTime _selectedWeekStart;
  String _selectedMedicineFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _selectedTimeSlotFilter = 'All';

  final List<String> _weekDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Monday of current week
    _selectedWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final List<MedicationEvent> allEvents = state.events;

        // Apply time range filter matching our _selectedWeekStart (Mon 00:00 to Sun 23:59)
        final DateTime weekEnd = _selectedWeekStart.add(const Duration(days: 7));
        List<MedicationEvent> weekEvents = allEvents.where((e) {
          return e.scheduledTime.isAfter(_selectedWeekStart.subtract(const Duration(seconds: 1))) &&
                 e.scheduledTime.isBefore(weekEnd);
        }).toList();

        // Get unique medicine names for dropdown filter list
        final List<String> medNames = ['All'] + state.medicines.map((m) => m.name).toSet().toList();

        // Apply medication dropdown filter
        if (_selectedMedicineFilter != 'All') {
          weekEvents = weekEvents.where((e) => e.medicineName == _selectedMedicineFilter).toList();
        }

        // Apply time-slot filter (Morning, Afternoon, Evening, Night)
        if (_selectedTimeSlotFilter != 'All') {
          weekEvents = weekEvents.where((e) => e.timeSlot == _selectedTimeSlotFilter).toList();
        }

        // Apply status filter
        if (_selectedStatusFilter != 'All') {
          weekEvents = weekEvents.where((e) {
            switch (_selectedStatusFilter) {
              case 'Recorded':
              case 'Completed':
                return e.status == MedicationStatus.medicationEventRecorded;
              case 'Due Soon':
                return e.status == MedicationStatus.due || e.status == MedicationStatus.scheduled;
              case 'Missed':
                return e.status == MedicationStatus.missed;
              case 'Unconfirmed':
                return e.status == MedicationStatus.unconfirmed;
              default:
                return true;
            }
          }).toList();
        }

        // Group events by schedule hours (HH:MM) to create the planning matrix
        final Map<String, List<MedicationEvent>> groupedByHour = {};
        for (var event in weekEvents) {
          final timeKey = DateFormat('hh:mm a').format(event.scheduledTime);
          if (!groupedByHour.containsKey(timeKey)) {
            groupedByHour[timeKey] = [];
          }
          groupedByHour[timeKey]!.add(event);
        }

        final List<String> sortedHours = groupedByHour.keys.toList()
          ..sort((a, b) {
            final aTime = DateFormat('hh:mm a').parse(a);
            final bTime = DateFormat('hh:mm a').parse(b);
            return aTime.compareTo(bTime);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Weekly Medication Plan'),
            actions: [
              IconButton(
                tooltip: 'Go to current week',
                icon: const Icon(Icons.today_outlined),
                onPressed: () {
                  setState(() {
                    final now = DateTime.now();
                    _selectedWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Week Navigator (Previous / Next)
              _buildWeekNavigator(),
              
              // Filter Toolbar
              _buildFilterToolbar(medNames),

              // Planning Matrix Grid
              Expanded(
                child: weekEvents.isEmpty
                    ? _buildEmptyState(state)
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Days Header Row (MON to SUN)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 76, 
                                    child: Text('TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                                  ),
                                  ...List.generate(7, (index) {
                                    final dayText = _weekDays[index];
                                    final dayDate = _selectedWeekStart.add(Duration(days: index));
                                    final isToday = dayDate.day == DateTime.now().day &&
                                                    dayDate.month == DateTime.now().month &&
                                                    dayDate.year == DateTime.now().year;
                                    return Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            dayText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                              color: isToday ? AppColors.brandStart : AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isToday ? AppColors.brandStart : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${dayDate.day}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isToday ? Colors.white : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const Divider(color: AppColors.border),

                            // Grid Matrix Rows by Hour
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedHours.length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                              itemBuilder: (context, idx) {
                                final hourKey = sortedHours[idx];
                                final rowEvents = groupedByHour[hourKey]!;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 76,
                                        child: Text(
                                          hourKey,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                        ),
                                      ),
                                      ...List.generate(7, (dayIdx) {
                                        final dayOfWeek = dayIdx + 1; // 1 = Monday, 7 = Sunday
                                        final matchingEvents = rowEvents.where((e) => e.scheduledTime.weekday == dayOfWeek).toList();

                                        if (matchingEvents.isEmpty) {
                                          return const Expanded(
                                            child: Center(
                                              child: Text('—', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            ),
                                          );
                                        }

                                        return Expanded(
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 2,
                                            runSpacing: 2,
                                            children: matchingEvents.map((event) {
                                              return GestureDetector(
                                                onTap: () => _showEventDetailsSheet(context, event, state),
                                                child: _buildStatusBubble(event),
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            // Status Legend
                            const SizedBox(height: 24),
                            _buildLegendCard(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekNavigator() {
    final endOfWeek = _selectedWeekStart.add(const Duration(days: 6));
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final String label = '${formatter.format(_selectedWeekStart)} - ${formatter.format(endOfWeek)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Week',
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const Text(
                '4 Containers Reused Mon–Sun',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Week',
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(List<String> medicines) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          DropdownButton<String>(
            value: _selectedMedicineFilter,
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            underline: const SizedBox(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedMedicineFilter = newValue);
              }
            },
            items: medicines.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedTimeSlotFilter,
            icon: const Icon(Icons.access_time, size: 16),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            underline: const SizedBox(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedTimeSlotFilter = newValue);
              }
            },
            items: ['All', 'Morning', 'Afternoon', 'Evening', 'Night'].map<DropdownMenuItem<String>>((String slot) {
              return DropdownMenuItem<String>(
                value: slot,
                child: Text(slot == 'All' ? 'All Slots' : slot),
              );
            }).toList(),
          ),
          const SizedBox(width: 12),
          ...['All', 'Recorded', 'Due Soon', 'Missed', 'Unconfirmed'].map((status) {
            final isSelected = _selectedStatusFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedStatusFilter = status);
                },
                selectedColor: AppColors.brandStart.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.brandStart : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSelected ? AppColors.brandStart : AppColors.border),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBubble(MedicationEvent event) {
    Color bg = AppColors.statusUpcomingBg;
    Color fg = AppColors.statusUpcomingText;

    switch (event.status) {
      case MedicationStatus.medicationEventRecorded:
        bg = AppColors.statusCompletedBg;
        fg = AppColors.statusCompleted;
        break;
      case MedicationStatus.due:
        bg = AppColors.statusDueBg;
        fg = AppColors.statusDue;
        break;
      case MedicationStatus.missed:
        bg = AppColors.statusMissedBg;
        fg = AppColors.statusMissed;
        break;
      case MedicationStatus.unconfirmed:
        bg = AppColors.statusUnconfirmed;
        fg = AppColors.statusUnconfirmedText;
        break;
      case MedicationStatus.snoozed:
        bg = AppColors.statusDueBg;
        fg = AppColors.statusDue;
        break;
      default:
        bg = AppColors.statusUpcomingBg;
        fg = AppColors.statusUpcoming;
        break;
    }

    final initialChar = event.medicineName.substring(0, 1).toUpperCase();

    return Tooltip(
      message: '${event.medicineName}\nContainer ${event.containerId} · ${event.timeSlot}\nStatus: ${_formatStatusName(event.status)}',
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Text(
          initialChar,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  String _formatStatusName(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.medicationEventRecorded:
        return 'Medication Event Recorded';
      case MedicationStatus.unconfirmed:
        return 'Unconfirmed Event';
      case MedicationStatus.missed:
        return 'Missed Event';
      case MedicationStatus.due:
        return 'Due Soon';
      case MedicationStatus.snoozed:
        return 'Snoozed';
      case MedicationStatus.interactionDetected:
        return 'Container Interaction Detected';
      case MedicationStatus.weightChangeDetected:
        return 'Weight Change Detected';
      case MedicationStatus.scheduled:
        return 'Scheduled Event';
    }
  }

  Widget _buildLegendCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PLAN STATUS LEGEND',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Event Recorded', AppColors.statusCompleted, Icons.check_circle),
                _buildLegendItem('Due Soon', AppColors.statusDue, Icons.priority_high),
                _buildLegendItem('Missed', AppColors.statusMissed, Icons.cancel),
                _buildLegendItem('Upcoming', AppColors.statusUpcoming, Icons.watch_later_outlined),
                _buildLegendItem('Unconfirmed', AppColors.statusUnconfirmedText, Icons.help_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyState(AppState state) {
    final hasFilters = _selectedMedicineFilter != 'All' || 
                       _selectedTimeSlotFilter != 'All' || 
                       _selectedStatusFilter != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No Scheduled Events For This Filter' : 'No medications scheduled for this week.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters 
                  ? 'Try clearing your active filters or changing the selected week.'
                  : 'Add your medicines to automatically schedule your weekly plan across the 4 physical containers.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (hasFilters)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedMedicineFilter = 'All';
                    _selectedTimeSlotFilter = 'All';
                    _selectedStatusFilter = 'All';
                  });
                },
                child: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to the Medicines tab to add your medications.')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Medicine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandStart,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEventDetailsSheet(BuildContext context, MedicationEvent event, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(event.scheduledTime);
        final formattedTime = DateFormat('hh:mm a').format(event.scheduledTime);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.medicineName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                '${event.medicineStrength} • ${event.dose}',
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const Divider(height: 28, color: AppColors.border),
              
              _buildDetailRow(Icons.calendar_month, 'Scheduled Day', formattedDate),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.access_time, 'Scheduled Time', formattedTime),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.inventory_2_outlined, 
                'Physical Container', 
                'Container ${event.containerId} · ${event.timeSlot}',
                valueColor: AppColors.brandStart,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.info_outline, 
                'Status', 
                event.status == MedicationStatus.medicationEventRecorded 
                    ? 'Medication event recorded' 
                    : (event.status == MedicationStatus.unconfirmed ? 'Unconfirmed event' : event.status.name),
                valueColor: event.status == MedicationStatus.medicationEventRecorded 
                    ? AppColors.statusCompleted 
                    : (event.status == MedicationStatus.missed ? AppColors.statusMissed : AppColors.statusDue),
              ),
              
              if (event.weightChange != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(Icons.scale_outlined, 'Measured Weight Delta', '${event.weightChange} g'),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        state.updateEventStatus(
                          event.id,
                          MedicationStatus.missed,
                        );
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.statusMissed),
                        foregroundColor: AppColors.statusMissed,
                      ),
                      child: const Text('Mark Missed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        state.updateEventStatus(
                          event.id,
                          MedicationStatus.medicationEventRecorded,
                          source: 'Manual',
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandStart,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark Recorded'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

// Fallback preview
class _StaticState {
  static final cleanState = AppState(
    authService: MockAuthService(seedTestAccount: false),
    notificationService: MockNotificationService(),
    imageService: MockMedicineImageService(),
    deviceService: MockDeviceService(),
    medicineRepository: InMemoryMedicineRepository(),
    eventRepository: InMemoryEventRepository(),
    caretakerRepository: InMemoryCaretakerRepository(),
  );
}
