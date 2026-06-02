-- Add exam support fields to lessons table
alter table lessons add column if not exists is_exam boolean default false;
alter table lessons add column if not exists gem_reward int default 0;
