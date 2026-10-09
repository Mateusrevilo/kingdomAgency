begin;

create schema if not exists app_private;
revoke all on schema app_private from public;
grant usage on schema app_private to authenticated, service_role;

create table public.churches (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 1 and 160),
  slug text not null unique
    check (slug = lower(slug) and slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.people (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete restrict,
  full_name text not null check (length(btrim(full_name)) between 1 and 200),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (church_id, id)
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  person_id uuid unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (person_id) references public.people(id) on delete restrict
);

create table public.church_memberships (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete restrict,
  person_id uuid not null unique,
  status text not null default 'active'
    check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (church_id, id),
  foreign key (church_id, person_id)
    references public.people(church_id, id) on delete restrict
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  key text not null unique
    check (key in ('senior', 'secondary', 'member')),
  label text not null,
  created_at timestamptz not null default now()
);

create table public.church_user_roles (
  church_id uuid not null references public.churches(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  role_id uuid not null references public.roles(id) on delete restrict,
  status text not null default 'active'
    check (status in ('active', 'inactive')),
  granted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (church_id, user_id)
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  description text not null,
  created_at timestamptz not null default now()
);

create table public.permission_packages (
  id uuid primary key default gen_random_uuid(),
  key text not null unique
    check (key in (
      'secretariat',
      'programming',
      'groups',
      'content',
      'finance_high_privilege'
    )),
  label text not null,
  created_at timestamptz not null default now()
);

create table public.package_permissions (
  package_id uuid not null references public.permission_packages(id) on delete restrict,
  permission_id uuid not null references public.permissions(id) on delete restrict,
  primary key (package_id, permission_id)
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete restrict,
  permission_id uuid not null references public.permissions(id) on delete restrict,
  primary key (role_id, permission_id)
);

create table public.admin_package_assignments (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null,
  user_id uuid not null,
  package_id uuid not null references public.permission_packages(id) on delete restrict,
  granted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  foreign key (church_id, user_id)
    references public.church_user_roles(church_id, user_id) on delete restrict,
  check (revoked_at is null or revoked_at >= created_at)
);

create unique index admin_package_assignments_active_unique
  on public.admin_package_assignments (church_id, user_id, package_id)
  where revoked_at is null;

create table public.admin_permission_overrides (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null,
  user_id uuid not null,
  permission_id uuid not null references public.permissions(id) on delete restrict,
  effect text not null check (effect in ('grant', 'deny')),
  granted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  foreign key (church_id, user_id)
    references public.church_user_roles(church_id, user_id) on delete restrict,
  check (revoked_at is null or revoked_at >= created_at)
);

create unique index admin_permission_overrides_active_unique
  on public.admin_permission_overrides (church_id, user_id, permission_id)
  where revoked_at is null;

create table public.admin_member_limits (
  church_id uuid not null,
  admin_user_id uuid not null,
  max_members integer not null check (max_members >= 0),
  changed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (church_id, admin_user_id),
  foreign key (church_id, admin_user_id)
    references public.church_user_roles(church_id, user_id) on delete restrict
);

create table public.member_assignments (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null,
  membership_id uuid not null,
  admin_user_id uuid not null,
  assigned_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_by uuid references auth.users(id) on delete set null,
  end_reason text check (end_reason in ('transferred', 'removed')),
  foreign key (church_id, membership_id)
    references public.church_memberships(church_id, id) on delete restrict,
  foreign key (church_id, admin_user_id)
    references public.church_user_roles(church_id, user_id) on delete restrict,
  check (
    (ended_at is null and ended_by is null and end_reason is null)
    or
    (ended_at is not null and end_reason is not null)
  )
);

create unique index member_assignments_current_unique
  on public.member_assignments (church_id, membership_id)
  where ended_at is null;

create index member_assignments_admin_current_idx
  on public.member_assignments (church_id, admin_user_id)
  where ended_at is null;

create table public.audit_logs (
  id bigint generated always as identity primary key,
  church_id uuid not null references public.churches(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null check (length(btrim(action)) between 1 and 120),
  target_table text,
  target_id uuid,
  details jsonb not null default '{}'::jsonb
    check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);

create index audit_logs_church_created_idx
  on public.audit_logs (church_id, created_at desc);

insert into public.roles (key, label)
values
  ('senior', 'Administrador Sênior'),
  ('secondary', 'Administrador Secundário'),
  ('member', 'Membro')
on conflict (key) do update set label = excluded.label;

insert into public.permissions (key, description)
values
  ('members.read_own', 'Consultar os próprios dados de membro'),
  ('members.update_own', 'Atualizar campos próprios permitidos'),
  ('members.read_assigned', 'Consultar membros atualmente atribuídos'),
  ('members.create', 'Cadastrar membro com atribuição inicial'),
  ('members.update_assigned', 'Atualizar membros atualmente atribuídos'),
  ('visitors.manage', 'Gerir registros internos de visitantes'),
  ('worship_services.manage', 'Gerir cultos e agenda de cultos'),
  ('events.manage', 'Gerir eventos e inscrições'),
  ('services.manage', 'Gerir oportunidades de serviço'),
  ('groups.manage', 'Gerir grupos'),
  ('group_memberships.manage', 'Gerir participação em grupos'),
  ('volunteer.manage', 'Gerir voluntariado'),
  ('public_content.manage', 'Gerir publicação de conteúdo público'),
  ('media_content.manage', 'Gerir mídias'),
  ('event_registrations.manage_own', 'Gerir inscrições próprias em eventos'),
  ('service_participations.manage_own', 'Gerir participações próprias em serviços'),
  ('group_memberships.read_own', 'Consultar participação própria em grupos'),
  ('contributions.read_own', 'Consultar declarações próprias de contribuição'),
  ('contributions.declare', 'Registrar declaração própria de contribuição'),
  ('contributions.read_all', 'Consultar contribuições da igreja'),
  ('contributions.confirm', 'Confirmar recebimentos da tesouraria'),
  ('treasury_entries.create', 'Registrar recebimentos na tesouraria'),
  ('treasury_entries.adjust', 'Estornar ou corrigir lançamentos da tesouraria')
on conflict (key) do update set description = excluded.description;

insert into public.permission_packages (key, label)
values
  ('secretariat', 'Secretaria'),
  ('programming', 'Programação'),
  ('groups', 'Grupos e voluntariado'),
  ('content', 'Conteúdo público'),
  ('finance_high_privilege', 'Finanças - alto privilégio')
on conflict (key) do update set label = excluded.label;

insert into public.package_permissions (package_id, permission_id)
select pp.id, p.id
from (values
  ('secretariat', 'members.read_assigned'),
  ('secretariat', 'members.create'),
  ('secretariat', 'members.update_assigned'),
  ('secretariat', 'visitors.manage'),
  ('programming', 'worship_services.manage'),
  ('programming', 'events.manage'),
  ('programming', 'services.manage'),
  ('groups', 'groups.manage'),
  ('groups', 'group_memberships.manage'),
  ('groups', 'volunteer.manage'),
  ('content', 'public_content.manage'),
  ('content', 'media_content.manage'),
  ('finance_high_privilege', 'contributions.read_all'),
  ('finance_high_privilege', 'contributions.confirm'),
  ('finance_high_privilege', 'treasury_entries.create'),
  ('finance_high_privilege', 'treasury_entries.adjust')
) as mapping(package_key, permission_key)
join public.permission_packages pp on pp.key = mapping.package_key
join public.permissions p on p.key = mapping.permission_key
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.key = 'member'
  and p.key in (
    'members.read_own',
    'members.update_own',
    'event_registrations.manage_own',
    'service_participations.manage_own',
    'group_memberships.read_own',
    'contributions.read_own',
    'contributions.declare'
  )
on conflict do nothing;

create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

revoke all on function app_private.touch_updated_at() from public, anon, authenticated;

create trigger churches_touch_updated_at
before update on public.churches
for each row execute function app_private.touch_updated_at();

create trigger people_touch_updated_at
before update on public.people
for each row execute function app_private.touch_updated_at();

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function app_private.touch_updated_at();

create trigger church_memberships_touch_updated_at
before update on public.church_memberships
for each row execute function app_private.touch_updated_at();

create trigger church_user_roles_touch_updated_at
before update on public.church_user_roles
for each row execute function app_private.touch_updated_at();

create trigger admin_member_limits_touch_updated_at
before update on public.admin_member_limits
for each row execute function app_private.touch_updated_at();

create or replace function app_private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function app_private.handle_new_auth_user() from public, anon, authenticated;

create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function app_private.handle_new_auth_user();

insert into public.profiles (id)
select users.id
from auth.users as users
on conflict (id) do nothing;

create or replace function app_private.is_church_senior(p_church_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.church_user_roles as church_role
    join public.roles as role on role.id = church_role.role_id
    where church_role.church_id = p_church_id
      and church_role.user_id = (select auth.uid())
      and church_role.status = 'active'
      and role.key = 'senior'
  );
$$;

create or replace function app_private.is_church_user(p_church_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.church_user_roles as church_role
    where church_role.church_id = p_church_id
      and church_role.user_id = (select auth.uid())
      and church_role.status = 'active'
  ) or exists (
    select 1
    from public.profiles as profile
    join public.church_memberships as membership
      on membership.person_id = profile.person_id
    where profile.id = (select auth.uid())
      and membership.church_id = p_church_id
      and membership.status = 'active'
  );
$$;

create or replace function app_private.has_permission(
  p_church_id uuid,
  p_permission_key text
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select case
    when app_private.is_church_senior(p_church_id) then true
    else exists (
      select 1
      from public.church_user_roles as church_role
      join public.roles as role on role.id = church_role.role_id
      join public.admin_permission_overrides as permission_override
        on permission_override.church_id = church_role.church_id
        and permission_override.user_id = church_role.user_id
        and permission_override.revoked_at is null
      join public.permissions as permission
        on permission.id = permission_override.permission_id
        and permission.key = p_permission_key
      where church_role.church_id = p_church_id
        and church_role.user_id = (select auth.uid())
        and church_role.status = 'active'
        and role.key = 'secondary'
        and permission_override.effect = 'grant'
    ) or (
      not exists (
        select 1
        from public.admin_permission_overrides as permission_override
        join public.permissions as permission
          on permission.id = permission_override.permission_id
        where permission_override.church_id = p_church_id
          and permission_override.user_id = (select auth.uid())
          and permission_override.revoked_at is null
          and permission.key = p_permission_key
      )
      and exists (
        select 1
        from public.church_user_roles as church_role
        join public.roles as role on role.id = church_role.role_id
        join public.admin_package_assignments as package_assignment
          on package_assignment.church_id = church_role.church_id
          and package_assignment.user_id = church_role.user_id
          and package_assignment.revoked_at is null
        join public.package_permissions as package_permission
          on package_permission.package_id = package_assignment.package_id
        join public.permissions as permission
          on permission.id = package_permission.permission_id
          and permission.key = p_permission_key
        where church_role.church_id = p_church_id
          and church_role.user_id = (select auth.uid())
          and church_role.status = 'active'
          and role.key = 'secondary'
      )
    )
  end;
$$;

create or replace function app_private.can_read_member(
  p_church_id uuid,
  p_person_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select app_private.is_church_senior(p_church_id)
    or exists (
      select 1
      from public.profiles as profile
      where profile.id = (select auth.uid())
        and profile.person_id = p_person_id
    )
    or (
      app_private.has_permission(p_church_id, 'members.read_assigned')
      and exists (
        select 1
        from public.church_memberships as membership
        join public.member_assignments as assignment
          on assignment.church_id = membership.church_id
          and assignment.membership_id = membership.id
          and assignment.ended_at is null
        where membership.church_id = p_church_id
          and membership.person_id = p_person_id
          and assignment.admin_user_id = (select auth.uid())
      )
    );
$$;

revoke all on function app_private.is_church_senior(uuid) from public, anon;
revoke all on function app_private.is_church_user(uuid) from public, anon;
revoke all on function app_private.has_permission(uuid, text) from public, anon;
revoke all on function app_private.can_read_member(uuid, uuid) from public, anon;
grant execute on function app_private.is_church_senior(uuid) to authenticated, service_role;
grant execute on function app_private.is_church_user(uuid) to authenticated, service_role;
grant execute on function app_private.has_permission(uuid, text) to authenticated, service_role;
grant execute on function app_private.can_read_member(uuid, uuid) to authenticated, service_role;

alter table public.churches enable row level security;
alter table public.people enable row level security;
alter table public.profiles enable row level security;
alter table public.church_memberships enable row level security;
alter table public.roles enable row level security;
alter table public.church_user_roles enable row level security;
alter table public.permissions enable row level security;
alter table public.permission_packages enable row level security;
alter table public.package_permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.admin_package_assignments enable row level security;
alter table public.admin_permission_overrides enable row level security;
alter table public.admin_member_limits enable row level security;
alter table public.member_assignments enable row level security;
alter table public.audit_logs enable row level security;

create policy churches_read_same_tenant
on public.churches for select to authenticated
using (app_private.is_church_user(id));

create policy people_read_authorized
on public.people for select to authenticated
using (app_private.can_read_member(church_id, id));

create policy profiles_read_self
on public.profiles for select to authenticated
using (id = (select auth.uid()));

create policy memberships_read_authorized
on public.church_memberships for select to authenticated
using (app_private.can_read_member(church_id, person_id));

create policy roles_read_authenticated
on public.roles for select to authenticated
using (true);

create policy church_user_roles_read_self_or_senior
on public.church_user_roles for select to authenticated
using (
  user_id = (select auth.uid())
  or app_private.is_church_senior(church_id)
);

create policy permissions_read_authenticated
on public.permissions for select to authenticated
using (true);

create policy permission_packages_read_authenticated
on public.permission_packages for select to authenticated
using (true);

create policy package_permissions_read_authenticated
on public.package_permissions for select to authenticated
using (true);

create policy role_permissions_read_authenticated
on public.role_permissions for select to authenticated
using (true);

create policy admin_package_assignments_read_self_or_senior
on public.admin_package_assignments for select to authenticated
using (
  user_id = (select auth.uid())
  or app_private.is_church_senior(church_id)
);

create policy admin_permission_overrides_read_self_or_senior
on public.admin_permission_overrides for select to authenticated
using (
  user_id = (select auth.uid())
  or app_private.is_church_senior(church_id)
);

create policy admin_member_limits_read_self_or_senior
on public.admin_member_limits for select to authenticated
using (
  admin_user_id = (select auth.uid())
  or app_private.is_church_senior(church_id)
);

create policy member_assignments_read_related
on public.member_assignments for select to authenticated
using (
  admin_user_id = (select auth.uid())
  or app_private.is_church_senior(church_id)
  or exists (
    select 1
    from public.church_memberships as membership
    join public.profiles as profile on profile.person_id = membership.person_id
    where membership.church_id = member_assignments.church_id
      and membership.id = member_assignments.membership_id
      and profile.id = (select auth.uid())
  )
);

create policy audit_logs_read_senior
on public.audit_logs for select to authenticated
using (app_private.is_church_senior(church_id));

revoke all on table
  public.churches,
  public.people,
  public.profiles,
  public.church_memberships,
  public.roles,
  public.church_user_roles,
  public.permissions,
  public.permission_packages,
  public.package_permissions,
  public.role_permissions,
  public.admin_package_assignments,
  public.admin_permission_overrides,
  public.admin_member_limits,
  public.member_assignments,
  public.audit_logs
from anon, authenticated;

grant select on table
  public.churches,
  public.people,
  public.profiles,
  public.church_memberships,
  public.roles,
  public.church_user_roles,
  public.permissions,
  public.permission_packages,
  public.package_permissions,
  public.role_permissions,
  public.admin_package_assignments,
  public.admin_permission_overrides,
  public.admin_member_limits,
  public.member_assignments,
  public.audit_logs
to authenticated;

grant all on table
  public.churches,
  public.people,
  public.profiles,
  public.church_memberships,
  public.roles,
  public.church_user_roles,
  public.permissions,
  public.permission_packages,
  public.package_permissions,
  public.role_permissions,
  public.admin_package_assignments,
  public.admin_permission_overrides,
  public.admin_member_limits,
  public.member_assignments,
  public.audit_logs
to service_role;

grant usage, select on sequence public.audit_logs_id_seq to service_role;

commit;
