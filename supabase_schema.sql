-- 1. Tabla de Perfiles de la Empresa (vinculada a Auth.Users de Supabase)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text,
  rnc text default '1-01-12345-6',
  phone text default '809-123-4567',
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Habilitar Row Level Security (RLS) para Perfiles
alter table public.profiles enable row level security;

-- Políticas de RLS para Perfiles
create policy "Los usuarios pueden ver su propio perfil" on public.profiles
  for select using (auth.uid() = id);

create policy "Los usuarios pueden actualizar su propio perfil" on public.profiles
  for update using (auth.uid() = id);


-- 2. Tabla de Documentos (Facturas, Comprobantes, Recibos)
create table public.documents (
  id text primary key,
  supplier text not null,
  type text not null, -- Factura, Comprobante, Recibo
  date text not null,
  category text not null,
  amount numeric not null,
  notes text not null,
  format text not null,
  user_id uuid references auth.users on delete cascade not null default auth.uid(),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Habilitar RLS para Documentos
alter table public.documents enable row level security;

-- Políticas de RLS para Documentos
create policy "Los usuarios pueden insertar sus propios documentos" on public.documents
  for insert with check (auth.uid() = user_id);

create policy "Los usuarios pueden ver sus propios documentos" on public.documents
  for select using (auth.uid() = user_id);

create policy "Los usuarios pueden actualizar sus propios documentos" on public.documents
  for update using (auth.uid() = user_id);

create policy "Los usuarios pueden eliminar sus propios documentos" on public.documents
  for delete using (auth.uid() = user_id);


-- 3. Tabla de Recordatorios
create table public.reminders (
  id text primary key,
  title text not null,
  date text not null,
  days_left integer not null,
  urgency text not null, -- Importante, Normal
  status text not null, -- pending, completed
  user_id uuid references auth.users on delete cascade not null default auth.uid(),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Habilitar RLS para Recordatorios
alter table public.reminders enable row level security;

-- Políticas de RLS para Recordatorios
create policy "Los usuarios pueden insertar sus propios recordatorios" on public.reminders
  for insert with check (auth.uid() = user_id);

create policy "Los usuarios pueden ver sus propios recordatorios" on public.reminders
  for select using (auth.uid() = user_id);

create policy "Los usuarios pueden actualizar sus propios recordatorios" on public.reminders
  for update using (auth.uid() = user_id);

create policy "Los usuarios pueden eliminar sus propios recordatorios" on public.reminders
  for delete using (auth.uid() = user_id);


-- 4. Trigger de automatización: crea el perfil de empresa cuando se registra un usuario en Supabase Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, rnc, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'Mi Empresa S.R.L.'),
    coalesce(new.raw_user_meta_data->>'rnc', '1-01-12345-6'),
    coalesce(new.raw_user_meta_data->>'phone', '809-123-4567')
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
