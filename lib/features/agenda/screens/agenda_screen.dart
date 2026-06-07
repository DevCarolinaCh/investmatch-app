import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';

final meetingsProvider = FutureProvider<List<MeetingModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getMeetings();
  return data
      .map((e) => MeetingModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final meetings = ref.watch(meetingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva reunión',
            onPressed: () => _showScheduleSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          meetings.when(
            loading: () => const SizedBox(height: 350),
            error: (_, __) => const SizedBox(height: 350),
            data: (allMeetings) {
              // Mapear meetings por fecha
              final eventMap = <DateTime, List<MeetingModel>>{};
              for (final m in allMeetings) {
                final day = DateTime(
                    m.scheduledAt.year, m.scheduledAt.month, m.scheduledAt.day);
                eventMap[day] = [...(eventMap[day] ?? []), m];
              }

              return TableCalendar<MeetingModel>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  return eventMap[key] ?? [];
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle:
                      const TextStyle(color: AppColors.primary, fontFamily: 'Inter'),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  titleTextStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Lista de reuniones del día seleccionado o próximas
          Expanded(
            child: meetings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allMeetings) {
                final dayMeetings = _selectedDay != null
                    ? allMeetings.where((m) {
                        return isSameDay(m.scheduledAt, _selectedDay!);
                      }).toList()
                    : allMeetings
                        .where((m) =>
                            m.scheduledAt.isAfter(DateTime.now()) &&
                            m.status == MeetingStatus.confirmed)
                        .take(10)
                        .toList();

                if (dayMeetings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          _selectedDay != null
                              ? 'Sin reuniones ese día'
                              : 'No hay próximas reuniones',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _showScheduleSheet(context),
                          child: const Text('Agendar una reunión'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayMeetings.length,
                  itemBuilder: (context, index) =>
                      _MeetingCard(meeting: dayMeetings[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleMeetingSheet(
        onSchedule: (meeting) async {
          final api = ref.read(apiServiceProvider);
          await api.scheduleMeeting(meeting.toJson());
          if (mounted) {
            ref.invalidate(meetingsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reunión agendada correctamente'),
                backgroundColor: AppColors.secondary,
              ),
            );
          }
        },
      ),
    );
  }
}

class _MeetingCard extends ConsumerWidget {
  final MeetingModel meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.watch(authNotifierProvider).valueOrNull?.id ?? '';
    final isRequester = meeting.requesterId == currentUserId;
    final counterpart =
        isRequester ? meeting.receiverName : meeting.requesterName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: meeting.status),
                const Spacer(),
                Text(
                  '${meeting.scheduledAt.day}/${meeting.scheduledAt.month} · ${meeting.scheduledAt.hour.toString().padLeft(2, '0')}:${meeting.scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              meeting.projectTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Con $counterpart · ${meeting.durationMinutes} min',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (meeting.meetingUrl != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Abrir link de reunión
                },
                icon: const Icon(Icons.video_call_outlined, size: 18),
                label: const Text('Unirse a la reunión'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
            if (meeting.status == MeetingStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final api = ref.read(apiServiceProvider);
                        await api.updateMeetingStatus(
                            meeting.id, 'cancelled');
                        ref.invalidate(meetingsProvider);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final api = ref.read(apiServiceProvider);
                        await api.updateMeetingStatus(
                            meeting.id, 'confirmed');
                        ref.invalidate(meetingsProvider);
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40)),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MeetingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MeetingStatus.pending => ('Pendiente', AppColors.warning),
      MeetingStatus.confirmed => ('Confirmada', AppColors.secondary),
      MeetingStatus.cancelled => ('Cancelada', AppColors.error),
      MeetingStatus.completed => ('Completada', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _ScheduleMeetingSheet extends StatefulWidget {
  final ValueChanged<MeetingModel> onSchedule;
  const _ScheduleMeetingSheet({required this.onSchedule});

  @override
  State<_ScheduleMeetingSheet> createState() => _ScheduleMeetingSheetState();
}

class _ScheduleMeetingSheetState extends State<_ScheduleMeetingSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _duration = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Agendar intro call',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          // Fecha
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
            title: Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Seleccionar fecha',
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),

          // Hora
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_outlined, color: AppColors.primary),
            title: Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Seleccionar hora',
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 10, minute: 0),
              );
              if (time != null) setState(() => _selectedTime = time);
            },
          ),

          // Duración
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
            title: const Text('Duración'),
            trailing: DropdownButton<int>(
              value: _duration,
              underline: const SizedBox(),
              items: [15, 30, 45, 60]
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text('$d min'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _duration = v!),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selectedDate == null || _selectedTime == null
                ? null
                : () {
                    Navigator.pop(context);
                    // La lógica real se maneja en el parent
                  },
            child: const Text('Enviar solicitud de reunión'),
          ),
        ],
      ),
    );
  }
}
