-- Tafsir Abu Bakr Zakaria (Bengali)
-- Source: QUL (qul.tarteel.ai/resources/tafsir/33)
-- The most rigorous modern Bengali Quran tafsir, peer-reviewed by Salafi scholars

create table if not exists quran_tafsir (
  id      text primary key,       -- "{surah}:{ayah}"
  surah   smallint not null,
  ayah    smallint not null,
  text    text not null            -- Full Tafsir Abu Bakr Zakaria text (Bengali, HTML-stripped)
);
create index if not exists idx_qt_surah_ayah on quran_tafsir(surah, ayah);

alter table quran_tafsir enable row level security;
create policy "qt_read" on quran_tafsir for select using (true);
