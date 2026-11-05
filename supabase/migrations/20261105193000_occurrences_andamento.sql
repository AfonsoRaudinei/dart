alter table public.occurrences
  add column if not exists andamento text,
  add column if not exists responsavel_nome text;

update public.occurrences
set andamento = 'aberta'
where andamento is null or trim(andamento) = '';
