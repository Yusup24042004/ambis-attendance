-- ============================================================================
-- Izinkan ORANG TUA (role 'ortu') membaca data ANAKNYA.
--
-- Masalah: RLS lama hanya mengizinkan user membaca baris miliknya sendiri
-- (id / student_id = auth.uid()). Akibatnya dashboard ortu GAGAL MEMUAT:
-- getChildInfo() memanggil .single() pada tabel `users` dengan id = id anak
-- (bukan id ortu) -> 0 baris -> exception -> "Gagal memuat data anak".
--
-- Policy di bawah bersifat ADITIF (PostgreSQL menggabungkan policy SELECT
-- dengan OR), jadi TIDAK mengubah/menghapus akses siswa maupun admin.
-- Relasi: students.parent_id = auth.uid() menandakan "anak dari ortu ini".
-- ============================================================================

-- users: ortu boleh baca baris user milik anaknya
drop policy if exists "ortu_read_child_user" on public.users;
create policy "ortu_read_child_user"
on public.users for select to authenticated
using (
  exists (
    select 1 from public.students s
    where s.id = public.users.id
      and s.parent_id = auth.uid()
  )
);

-- students: ortu boleh baca baris siswa anaknya
drop policy if exists "ortu_read_child_student" on public.students;
create policy "ortu_read_child_student"
on public.students for select to authenticated
using ( parent_id = auth.uid() );

-- attendance: ortu boleh baca absensi anaknya
drop policy if exists "ortu_read_child_attendance" on public.attendance;
create policy "ortu_read_child_attendance"
on public.attendance for select to authenticated
using (
  exists (
    select 1 from public.students s
    where s.id = public.attendance.student_id
      and s.parent_id = auth.uid()
  )
);

-- grades: ortu boleh baca nilai anaknya
drop policy if exists "ortu_read_child_grades" on public.grades;
create policy "ortu_read_child_grades"
on public.grades for select to authenticated
using (
  exists (
    select 1 from public.students s
    where s.id = public.grades.student_id
      and s.parent_id = auth.uid()
  )
);

-- leave_requests: ortu boleh baca pengajuan izin/sakit anaknya
drop policy if exists "ortu_read_child_leave" on public.leave_requests;
create policy "ortu_read_child_leave"
on public.leave_requests for select to authenticated
using (
  exists (
    select 1 from public.students s
    where s.id = public.leave_requests.student_id
      and s.parent_id = auth.uid()
  )
);