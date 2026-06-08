-- Quran word-by-word data
-- Arabic: QPC Hafs Uthmani (api.alquran.cloud / quran-uthmani edition)
-- Bengali word meanings: GreenTech Foundation / GTAF (from QUL)
-- Audio: Mishary Al-Afasy via cdn.islamic.network (streaming)

create table if not exists quran_words (
  id           text primary key,
  surah        smallint not null,
  ayah         smallint not null,
  position     smallint not null,
  arabic       text not null,
  meaning_bn   text             -- GTAF word-level Bengali meaning
);
create index if not exists idx_qw_surah_ayah on quran_words(surah, ayah, position);

create table if not exists quran_surahs (
  number       smallint primary key,
  name_ar      text not null,
  name_en      text not null,
  name_bn      text not null,
  ayah_count   smallint not null,
  revelation   text not null check (revelation in ('meccan','medinan'))
);

alter table quran_words  enable row level security;
alter table quran_surahs enable row level security;
create policy "qw_read"  on quran_words  for select using (true);
create policy "qs_read"  on quran_surahs for select using (true);
