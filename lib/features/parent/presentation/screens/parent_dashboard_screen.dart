import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/parent_repository.dart';
import '../providers/parent_provider.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/parent-login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(childInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Icon(Icons.school_rounded, color: Color(0xFF002B5B), size: 24),
              SizedBox(width: 10),
              Text(
                'SMAN 07 Kab. Tangerang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF002B5B),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF747780)),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: childAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFC4C6D0)),
              const SizedBox(height: 12),
              const Text('Gagal memuat data anak.',
                  style: TextStyle(color: Color(0xFF43474F))),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(childInfoProvider),
                child: const Text('Coba Lagi',
                    style: TextStyle(color: Color(0xFF006A63))),
              ),
            ],
          ),
        ),
        data: (child) {
          if (child == null) return const _NoChildState();
          final attendanceCountAsync =
              ref.watch(childAttendanceThisMonthProvider);
          final attendanceStr = attendanceCountAsync.when(
            data: (c) => '$c',
            loading: () => '…',
            error: (_, __) => '-',
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Row 1: Profile + Attendance count
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _ProfileCard(child: child)
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 300.ms)
                          .slideY(begin: 0.08, end: 0, duration: 350.ms),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttendanceCard(
                        countStr: attendanceStr,
                        onTap: () => context.push('/parent-history'),
                      )
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 300.ms)
                          .slideY(begin: 0.08, end: 0, duration: 350.ms),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Row 2: Today's attendance
              _TodayAttendanceCard(child: child)
                  .animate()
                  .fadeIn(delay: 220.ms, duration: 300.ms)
                  .slideY(begin: 0.08, end: 0, duration: 350.ms),
              const SizedBox(height: 12),

              // Row 3: Grades summary (UTS + UAS)
              _GradesSummaryCard(child: child)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms)
                  .slideY(begin: 0.08, end: 0, duration: 350.ms),
              const SizedBox(height: 12),

              // Row 4: Leave requests
              _LeaveRequestsCard(child: child)
                  .animate()
                  .fadeIn(delay: 380.ms, duration: 300.ms)
                  .slideY(begin: 0.08, end: 0, duration: 350.ms),
            ],
          );
        },
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});
  final ChildStudentInfo child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4C6D0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFF002B5B)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFD6E3FF),
                      child: Text(
                        child.initials,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF002B5B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            child.fullname,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191C1E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined,
                                  size: 12, color: Color(0xFF43474F)),
                              const SizedBox(width: 3),
                              Text(
                                child.className,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF43474F)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.pin_outlined,
                                  size: 12, color: Color(0xFF43474F)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'NISN: ${child.nisn}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF43474F)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attendance Card ───────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.countStr, required this.onTap});
  final String countStr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC4C6D0)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFF006A63)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KEHADIRAN\nBULAN INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF43474F),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          countStr,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, color: Color(0xFFECEEF0)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: Color(0xFF006A63)),
                            SizedBox(width: 3),
                            Text(
                              'Lihat Riwayat',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF006A63),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today Attendance Card ─────────────────────────────────────────────────────

class _TodayAttendanceCard extends ConsumerWidget {
  const _TodayAttendanceCard({required this.child});
  final ChildStudentInfo child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(childTodayAttendanceProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4C6D0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.today_rounded,
                      size: 18, color: Color(0xFF002B5B)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Absensi Hari Ini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ),
                _TodayDateChip(),
              ],
            ),
            const SizedBox(height: 12),
            todayAsync.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const Text('Gagal memuat data.',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
              data: (today) => Row(
                children: [
                  Expanded(
                    child: _AttendanceTimeChip(
                      label: 'MASUK',
                      time: today.timeIn,
                      color: const Color(0xFF006A63),
                      icon: Icons.login_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AttendanceTimeChip(
                      label: 'PULANG',
                      time: today.timeOut,
                      color: const Color(0xFFF5B800),
                      icon: Icons.logout_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayDateChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final label = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF002B5B),
        ),
      ),
    );
  }
}

class _AttendanceTimeChip extends StatelessWidget {
  const _AttendanceTimeChip({
    required this.label,
    required this.time,
    required this.color,
    required this.icon,
  });

  final String label;
  final String? time;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasTime = time != null && time!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasTime
            ? color.withValues(alpha: 0.08)
            : const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasTime ? color.withValues(alpha: 0.3) : const Color(0xFFE0E3E5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: hasTime ? color : const Color(0xFFC4C6D0)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF747780),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasTime ? time! : '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasTime ? color : const Color(0xFFC4C6D0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grades Summary Card ───────────────────────────────────────────────────────

class _GradesSummaryCard extends ConsumerWidget {
  const _GradesSummaryCard({required this.child});
  final ChildStudentInfo child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(childGradesSummaryProvider);
    final avgAsync = ref.watch(childOverallAverageProvider);
    final attendanceAsync = ref.watch(childAttendanceThisMonthProvider);
    final attendanceStr = attendanceAsync.when(
      data: (c) => '$c',
      loading: () => '…',
      error: (_, __) => '-',
    );

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4C6D0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFF47FBEB)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ringkasan Nilai',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEEF0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'UTS + UAS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF43474F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _AvgMiniCard(avgAsync: avgAsync)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _AttendanceMiniCard(
                                countStr: attendanceStr)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    gradesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Gagal memuat nilai.',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                      data: (grades) => grades.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Nilai belum diinput oleh admin.',
                                  style: TextStyle(
                                      color: Color(0xFF747780),
                                      fontSize: 13),
                                ),
                              ),
                            )
                          : _GradeTable(grades: grades),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvgMiniCard extends StatelessWidget {
  const _AvgMiniCard({required this.avgAsync});
  final AsyncValue<double?> avgAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E3E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RATA-RATA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: Color(0xFF43474F),
                  ),
                ),
                const SizedBox(height: 4),
                avgAsync.when(
                  loading: () => const SizedBox(
                    height: 22,
                    child: LinearProgressIndicator(
                      color: Color(0xFF002B5B),
                      backgroundColor: Color(0xFFE0E3E5),
                    ),
                  ),
                  error: (_, __) => const Text('-',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF002B5B))),
                  data: (avg) => Text(
                    avg != null ? avg.toStringAsFixed(1) : '-',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF002B5B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFD6E3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined,
                size: 18, color: Color(0xFF002B5B)),
          ),
        ],
      ),
    );
  }
}

class _AttendanceMiniCard extends StatelessWidget {
  const _AttendanceMiniCard({required this.countStr});
  final String countStr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E3E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HADIR\nBULAN INI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: Color(0xFF43474F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countStr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF002B5B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF006A63).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fact_check_outlined,
                size: 18, color: Color(0xFF006A63)),
          ),
        ],
      ),
    );
  }
}

class _GradeTable extends StatelessWidget {
  const _GradeTable({required this.grades});
  final List<ChildGradeRow> grades;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFECEEF0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF002B5B),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'MATA PELAJARAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'UTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'UAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...grades.asMap().entries.map((e) {
            final isEven = e.key.isEven;
            final row = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isEven ? Colors.white : const Color(0xFFF7F9FB),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.subject,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF191C1E)),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      row.utsScore != null
                          ? row.utsScore!.toStringAsFixed(0)
                          : '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (row.utsScore ?? 0) >= 88
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: (row.utsScore ?? 0) >= 88
                            ? const Color(0xFF006A63)
                            : const Color(0xFF191C1E),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      row.uasScore != null
                          ? row.uasScore!.toStringAsFixed(0)
                          : '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (row.uasScore ?? 0) >= 88
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: (row.uasScore ?? 0) >= 88
                            ? const Color(0xFF006A63)
                            : const Color(0xFF191C1E),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Leave Requests Card ───────────────────────────────────────────────────────

class _LeaveRequestsCard extends ConsumerWidget {
  const _LeaveRequestsCard({required this.child});
  final ChildStudentInfo child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(childLeaveRequestsProvider);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4C6D0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFFF5B800)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pengajuan Izin / Sakit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    leavesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Text('Gagal memuat data.',
                          style:
                              TextStyle(color: Colors.red, fontSize: 12)),
                      data: (leaves) => leaves.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  'Belum ada pengajuan izin.',
                                  style: TextStyle(
                                      color: Color(0xFF747780),
                                      fontSize: 13),
                                ),
                              ),
                            )
                          : Column(
                              children: leaves
                                  .map((l) => _LeaveItem(leave: l))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveItem extends StatelessWidget {
  const _LeaveItem({required this.leave});
  final ChildLeaveRequest leave;

  @override
  Widget build(BuildContext context) {
    final statusColor = leave.isApproved
        ? const Color(0xFF006A63)
        : leave.isRejected
            ? const Color(0xFFBA1A1A)
            : const Color(0xFFF5B800);
    final statusBg = leave.isApproved
        ? const Color(0xFFE8F5E9)
        : leave.isRejected
            ? const Color(0xFFFFDAD6)
            : const Color(0xFFFFF8E1);
    final statusLabel = leave.isApproved
        ? 'Disetujui'
        : leave.isRejected
            ? 'Ditolak'
            : 'Menunggu';
    final typeLabel = leave.type == 'sakit' ? 'Sakit' : 'Izin';
    final typeColor = leave.type == 'sakit'
        ? const Color(0xFF0B5CFF)
        : const Color(0xFFF5B800);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E3E5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${leave.dateFrom} — ${leave.dateTo}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1E)),
                  ),
                  if (leave.reason != null && leave.reason!.isNotEmpty)
                    Text(
                      leave.reason!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF747780)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No child linked ───────────────────────────────────────────────────────────

class _NoChildState extends StatelessWidget {
  const _NoChildState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded,
                size: 64, color: Color(0xFFC4C6D0)),
            SizedBox(height: 12),
            Text(
              'Data anak belum terhubung.',
              style: TextStyle(
                  color: Color(0xFF43474F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Hubungi admin sekolah untuk menghubungkan akun orang tua.',
              style: TextStyle(color: Color(0xFF747780), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
