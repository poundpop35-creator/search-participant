-- ============================================================
--  DMSc Event Check-in System — Database Schema Backup
--  รันในหน้า SQL Editor ของ Supabase โปรเจกต์ใหม่
--  (Project → SQL Editor → New query → วาง → Run)
-- ============================================================

-- ──────────────────────────────────────────
-- 1. TABLE: participants
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS participants (
  id                  BIGSERIAL PRIMARY KEY,
  event_year          TEXT,
  id_card             TEXT,
  passport            TEXT,
  qr_idcard           TEXT,
  qr_passport         TEXT,
  prefix              TEXT,
  first_name          TEXT,
  last_name           TEXT,
  dept                TEXT,
  ext_dept            TEXT,
  internal_external   TEXT,
  participation_type  TEXT,
  tag                 TEXT,
  items               TEXT,
  province            TEXT,
  is_walkin           BOOLEAN DEFAULT false,
  bag_received        BOOLEAN DEFAULT false,
  bag_received_date   TIMESTAMPTZ,
  bag_received_by     TEXT,
  bag_scanned_by      TEXT,
  shirt_size          TEXT,
  shirt_received      BOOLEAN DEFAULT false,
  shirt_received_date TIMESTAMPTZ,
  shirt_received_by   TEXT,
  shirt_scanned_by    TEXT
);

-- ──────────────────────────────────────────
-- 2. TABLE: checkins
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS checkins (
  id             BIGSERIAL PRIMARY KEY,
  participant_id BIGINT REFERENCES participants(id) ON DELETE CASCADE,
  day            INTEGER,
  event_year     TEXT,
  checkin_time   TIMESTAMPTZ DEFAULT now(),
  scanned_by     TEXT
);

-- ──────────────────────────────────────────
-- 3. TABLE: presenter_checkins
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS presenter_checkins (
  id             BIGSERIAL PRIMARY KEY,
  participant_id BIGINT REFERENCES participants(id) ON DELETE CASCADE,
  type           TEXT,
  checkin_time   TIMESTAMPTZ DEFAULT now(),
  scanned_by     TEXT
);

-- ──────────────────────────────────────────
-- 4. TABLE: staff_sessions
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS staff_sessions (
  username      TEXT PRIMARY KEY,
  logged_in_at  TIMESTAMPTZ DEFAULT now(),
  last_active   TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────
-- 5. TABLE: app_settings
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
  key   TEXT PRIMARY KEY,
  value TEXT
);

-- ──────────────────────────────────────────
-- Indexes
-- ──────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_participants_event_year  ON participants(event_year);
CREATE INDEX IF NOT EXISTS idx_participants_id_card     ON participants(id_card);
CREATE INDEX IF NOT EXISTS idx_participants_qr_idcard   ON participants(qr_idcard);
CREATE INDEX IF NOT EXISTS idx_checkins_participant_id  ON checkins(participant_id);
CREATE INDEX IF NOT EXISTS idx_checkins_event_year      ON checkins(event_year);
CREATE INDEX IF NOT EXISTS idx_presenter_participant_id ON presenter_checkins(participant_id);

-- ──────────────────────────────────────────
-- RLS (Row Level Security)
-- ──────────────────────────────────────────
-- service_role key จะ bypass RLS โดยอัตโนมัติ
-- anon key ใช้ Policy ด้านล่างนี้

ALTER TABLE participants        ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkins            ENABLE ROW LEVEL SECURITY;
ALTER TABLE presenter_checkins  ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings        ENABLE ROW LEVEL SECURITY;

-- อนุญาต anon อ่าน/เขียนทุก table (ระบบใช้ session-based auth เอง)
CREATE POLICY "anon_all_participants"       ON participants       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_checkins"           ON checkins           FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_presenter_checkins" ON presenter_checkins FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_staff_sessions"     ON staff_sessions     FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_app_settings"       ON app_settings       FOR ALL TO anon USING (true) WITH CHECK (true);

-- ──────────────────────────────────────────
-- Default app_settings (ปรับค่าตามงานจริง)
-- ──────────────────────────────────────────
INSERT INTO app_settings (key, value) VALUES
  ('event_year',       '2569'),
  ('event_name',       'วิชาการกรมวิทยาศาสตร์การแพทย์'),
  ('event_years_list', '2569'),
  ('theme',            '1'),
  ('text_color',       ''),
  ('page_bg',          ''),
  ('bg_url',           ''),
  ('public_bg',        ''),
  ('staff_accounts',   '[]'),
  ('vip_depts',        '["อธิบดีกรมวิทยาศาสตร์การแพทย์","รองอธิบดีกรมวิทยาศาสตร์การแพทย์"]'),
  ('exempt_depts',     '["กองแผนงานและวิชาการ"]'),
  ('network_depts',    '[]')
ON CONFLICT (key) DO NOTHING;

-- ──────────────────────────────────────────
-- หมายเหตุ
-- ──────────────────────────────────────────
-- หลังจาก run SQL นี้แล้ว:
-- 1. ไปที่ Project Settings → API → คัดลอก URL, anon key, service_role key
-- 2. เปิด checkin/admin-control.html → แท็บ "ตั้งค่าระบบ" → การ์ด "การเชื่อมต่อฐานข้อมูล"
-- 3. ใส่ค่าใหม่และกด "บันทึกการเชื่อมต่อ" → ระบบทั้งหมดจะใช้โปรเจกต์ใหม่ทันที
-- 4. นำเข้าข้อมูลผู้เข้าร่วมปีใหม่ผ่านแท็บ "นำเข้าข้อมูล"
