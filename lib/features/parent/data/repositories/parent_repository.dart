import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// ── Student info ──────────────────────────────────────────────────────────────

class ChildStudentInfo {
  const ChildStudentInfo({
    required this.studentId,
    required this.fullname,
    required this.nisn,
    required this.className,
  });

  final String studentId;
  final String fullname;
  final String nisn;
  final String className;

  String get initials {
    final parts =
        fullname.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Grades ────────────────────────────────────────────────────────────────────

class ChildGradeRow {
  const ChildGradeRow({
    required this.subject,
    this.utsScore,
    this.uasScore,
  });

  final String subject;
  final double? utsScore;
  final double? uasScore;
}

// ── Today Attendance ──────────────────────────────────────────────────────────

class ChildTodayAttendance {
  const ChildTodayAttendance({
    this.timeIn,
    this.timeOut,
    this.isPresent = false,
  });

  final String? timeIn;
  final String? timeOut;
  final bool isPresent;
}

// ── Leave Requests ────────────────────────────────────────────────────────────

class ChildLeaveRequest {
  const ChildLeaveRequest({
    required this.id,
    required this.type,
    required this.dateFrom,
    required this.dateTo,
    required this.status,
    this.reason,
  });

  final String id;
  final String type;   // 'izin' | 'sakit'
  final String dateFrom;
  final String dateTo;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reason;

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

// ── Attendance ────────────────────────────────────────────────────────────────

enum ParentAttendanceStatus { hadir, terlambat, izin, sakit, alfa }

class ParentAttendanceDay {
  const ParentAttendanceDay({
    required this.date,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.leaveType,
  });

  /// ISO date string: 'YYYY-MM-DD'
  final String date;
  final ParentAttendanceStatus status;
  final String? timeIn;
  final String? timeOut;

  /// 'izin' | 'sakit' when status is [ParentAttendanceStatus.izin] or [ParentAttendanceStatus.sakit]
  final String? leaveType;
}

class ParentAttendanceSummary {
  const ParentAttendanceSummary({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
    required this.records,
  });

  /// Hadir includes terlambat (late but present).
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;
  final List<ParentAttendanceDay> records;

  static const empty = ParentAttendanceSummary(
      hadir: 0, izin: 0, sakit: 0, alfa: 0, records: []);
}

// ── Repository ────────────────────────────────────────────────────────────────

class ParentRepository {
  ParentRepository(this._client);

  final sb.SupabaseClient _client;

  // ── Child info ──────────────────────────────────────────────────────────────

  /// Returns the child student linked to [parentUserId] via students.parent_id.
  /// Returns null if no child is found. Throws on network/DB error.
  Future<ChildStudentInfo?> getChildInfo(String parentUserId) async {
    final List<dynamic> rows = await _client
        .from('students')
        .select('id, nisn, class')
        .eq('parent_id', parentUserId)
        .limit(1);

    if (rows.isEmpty) return null;

    final student = rows.first as Map<String, dynamic>;
    final studentId = student['id'] as String;

    // maybeSingle (bukan single) agar tidak melempar exception bila baris
    // users anak tak terbaca (mis. RLS belum mengizinkan). Dashboard tetap
    // tampil; nama jatuh ke fallback alih-alih seluruh layar error.
    final Map<String, dynamic>? userRow = await _client
        .from('users')
        .select('fullname')
        .eq('id', studentId)
        .maybeSingle();

    return ChildStudentInfo(
      studentId: studentId,
      fullname: userRow?['fullname'] as String? ?? 'Siswa',
      nisn: student['nisn'] as String? ?? '-',
      className: student['class'] as String? ?? '-',
    );
  }

  // ── Grades ──────────────────────────────────────────────────────────────────

  /// Returns grades for [studentId] pivoted by subject (UTS + UAS per row).
  Future<List<ChildGradeRow>> getChildGradesSummary(String studentId) async {
    final List<dynamic> rows = await _client
        .from('grades')
        .select('subject, type, score')
        .eq('student_id', studentId)
        .order('subject');

    // Pivot by subject so each row has both UTS and UAS.
    final map = <String, Map<String, double?>>{};
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final subject = r['subject'] as String;
      final type    = r['type']    as String;
      final score   = (r['score']  as num).toDouble();
      map.putIfAbsent(subject, () => {'UTS': null, 'UAS': null});
      if (type == 'UTS') map[subject]!['UTS'] = score;
      if (type == 'UAS') map[subject]!['UAS'] = score;
    }

    return map.entries
        .map((e) => ChildGradeRow(
              subject: e.key,
              utsScore: e.value['UTS'],
              uasScore: e.value['UAS'],
            ))
        .toList()
      ..sort((a, b) => a.subject.compareTo(b.subject));
  }

  /// Returns the overall average (all UTS + UAS scores) for [studentId].
  Future<double?> getChildOverallAverage(String studentId) async {
    final List<dynamic> rows = await _client
        .from('grades')
        .select('score')
        .eq('student_id', studentId);

    if (rows.isEmpty) return null;
    final total =
        rows.fold<double>(0, (sum, r) => sum + (r['score'] as num).toDouble());
    return total / rows.length;
  }

  // ── Today Attendance ────────────────────────────────────────────────────────

  /// Returns today's check-in / check-out for [studentId], or null if absent.
  Future<ChildTodayAttendance> getChildTodayAttendance(
      String studentId) async {
    final today = DateTime.now();
    final mm  = today.month.toString().padLeft(2, '0');
    final dd  = today.day.toString().padLeft(2, '0');
    final dateStr = '${today.year}-$mm-$dd';

    final List<dynamic> rows = await _client
        .from('attendance')
        .select('time_in, time_out')
        .eq('student_id', studentId)
        .eq('date', dateStr)
        .limit(1);

    if (rows.isEmpty) return const ChildTodayAttendance();
    final row = rows.first as Map<String, dynamic>;
    return ChildTodayAttendance(
      timeIn:    row['time_in']  as String?,
      timeOut:   row['time_out'] as String?,
      isPresent: true,
    );
  }

  // ── Leave Requests ──────────────────────────────────────────────────────────

  /// Returns the 5 most recent leave requests for [studentId].
  Future<List<ChildLeaveRequest>> getChildLeaveRequests(
      String studentId) async {
    final List<dynamic> rows = await _client
        .from('leave_requests')
        .select('id, type, date_from, date_to, status, reason')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(5);

    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => ChildLeaveRequest(
              id:       r['id']        as String,
              type:     r['type']      as String,
              dateFrom: r['date_from'] as String,
              dateTo:   r['date_to']   as String,
              status:   r['status']    as String,
              reason:   r['reason']    as String?,
            ))
        .toList();
  }

  // ── Attendance ──────────────────────────────────────────────────────────────

  /// Returns count of attended days for [studentId] in the given month.
  Future<int> getChildAttendanceCountThisMonth(
      String studentId, int year, int month) async {
    final mm = month.toString().padLeft(2, '0');
    final List<dynamic> rows = await _client
        .from('attendance')
        .select('id')
        .eq('student_id', studentId)
        .like('date', '$year-$mm-%');
    return rows.length;
  }

  /// Fetches full attendance data for [studentId] in the given month,
  /// merging approved leave requests to determine daily status.
  Future<ParentAttendanceSummary> getChildAttendanceForMonth(
      String studentId, int year, int month) async {
    final mm = month.toString().padLeft(2, '0');
    final lastDay = _daysInMonth(year, month);
    final monthStart = '$year-$mm-01';
    final monthEnd = '$year-$mm-${lastDay.toString().padLeft(2, '0')}';

    final List<dynamic> attendanceRows = await _client
        .from('attendance')
        .select('date, time_in, time_out')
        .eq('student_id', studentId)
        .gte('date', monthStart)
        .lte('date', monthEnd)
        .order('date');

    final List<dynamic> leaveRows = await _client
        .from('leave_requests')
        .select('type, date_from, date_to')
        .eq('student_id', studentId)
        .eq('status', 'approved')
        .lte('date_from', monthEnd)
        .gte('date_to', monthStart);

    final attendanceByDate = <String, Map<String, dynamic>>{
      for (final r in attendanceRows.cast<Map<String, dynamic>>())
        r['date'] as String: r,
    };

    String? leaveTypeForDate(String dateStr) {
      for (final l in leaveRows.cast<Map<String, dynamic>>()) {
        final from = l['date_from'] as String?;
        final to = l['date_to'] as String?;
        if (from == null || to == null) continue;
        if (dateStr.compareTo(from) >= 0 && dateStr.compareTo(to) <= 0) {
          return l['type'] as String?;
        }
      }
      return null;
    }

    final today = DateTime.now();
    final records = <ParentAttendanceDay>[];
    int hadir = 0, izin = 0, sakit = 0, alfa = 0;

    for (int day = 1; day <= lastDay; day++) {
      final date = DateTime(year, month, day);
      if (date.isAfter(today)) continue;
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

      final dateStr = '$year-$mm-${day.toString().padLeft(2, '0')}';
      final row = attendanceByDate[dateStr];

      ParentAttendanceStatus status;
      String? timeIn;
      String? timeOut;
      String? leaveType;

      if (row != null) {
        timeIn = row['time_in'] as String?;
        timeOut = row['time_out'] as String?;
        if (timeIn != null && timeIn.compareTo('07:30') > 0) {
          status = ParentAttendanceStatus.terlambat;
        } else {
          status = ParentAttendanceStatus.hadir;
        }
        hadir++;
      } else {
        final lt = leaveTypeForDate(dateStr);
        if (lt == 'sakit') {
          status = ParentAttendanceStatus.sakit;
          leaveType = 'sakit';
          sakit++;
        } else if (lt == 'izin') {
          status = ParentAttendanceStatus.izin;
          leaveType = 'izin';
          izin++;
        } else {
          status = ParentAttendanceStatus.alfa;
          alfa++;
        }
      }

      records.add(ParentAttendanceDay(
        date: dateStr,
        status: status,
        timeIn: timeIn,
        timeOut: timeOut,
        leaveType: leaveType,
      ));
    }

    return ParentAttendanceSummary(
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alfa: alfa,
      records: records,
    );
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(sb.Supabase.instance.client);
});
