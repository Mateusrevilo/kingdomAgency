begin;

create or replace function app_private.prevent_last_senior_removal()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_church_id uuid;
  v_removing_senior boolean;
  v_next_is_senior boolean;
  v_other_active_seniors bigint;
begin
  v_church_id := old.church_id;

  select role.key = 'senior' and old.status = 'active'
  into v_removing_senior
  from public.roles as role
  where role.id = old.role_id;

  if not coalesce(v_removing_senior, false) then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_op = 'UPDATE' then
    select role.key = 'senior' and new.status = 'active'
    into v_next_is_senior
    from public.roles as role
    where role.id = new.role_id;

    if coalesce(v_next_is_senior, false) then
      return new;
    end if;
  end if;

  perform 1
  from public.churches as church
  where church.id = v_church_id
  for update;

  select count(*)
  into v_other_active_seniors
  from public.church_user_roles as church_role
  join public.roles as role on role.id = church_role.role_id
  where church_role.church_id = v_church_id
    and church_role.user_id <> old.user_id
    and church_role.status = 'active'
    and role.key = 'senior';

  if v_other_active_seniors = 0 then
    raise exception 'A igreja deve manter pelo menos um Administrador Sênior ativo.'
      using errcode = '23514';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

revoke all on function app_private.prevent_last_senior_removal()
  from public, anon, authenticated;

alter table public.member_assignments
  add constraint member_assignments_requires_member_limit
  foreign key (church_id, admin_user_id)
  references public.admin_member_limits(church_id, admin_user_id)
  on delete restrict
  not valid;

alter table public.member_assignments
  validate constraint member_assignments_requires_member_limit;

create trigger church_user_roles_prevent_last_senior_removal
before update of role_id, status or delete
on public.church_user_roles
for each row
execute function app_private.prevent_last_senior_removal();

create or replace function public.create_church(
  p_name text,
  p_slug text,
  p_owner_full_name text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, app_private, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_person_id uuid;
  v_church_id uuid;
  v_senior_role_id uuid;
  v_existing_person_id uuid;
begin
  if v_user_id is null then
    raise exception 'Autenticação necessária para criar uma igreja.'
      using errcode = '28000';
  end if;

  select profile.person_id
  into v_existing_person_id
  from public.profiles as profile
  where profile.id = v_user_id
  for update;

  if not found then
    raise exception 'Perfil de aplicação não encontrado para a conta autenticada.'
      using errcode = '55000';
  end if;

  if v_existing_person_id is not null then
    raise exception 'A conta já está vinculada a uma pessoa e não pode criar outra igreja.'
      using errcode = '23505';
  end if;

  if exists (
    select 1
    from public.church_user_roles as church_role
    where church_role.user_id = v_user_id
      and church_role.status = 'active'
  ) then
    raise exception 'A conta já possui papel administrativo ativo em uma igreja.'
      using errcode = '23505';
  end if;

  select role.id
  into v_senior_role_id
  from public.roles as role
  where role.key = 'senior';

  if v_senior_role_id is null then
    raise exception 'Papel de Administrador Sênior não está configurado.'
      using errcode = '55000';
  end if;

  insert into public.churches (name, slug)
  values (p_name, p_slug)
  returning id into v_church_id;

  insert into public.people (church_id, full_name, created_by)
  values (v_church_id, p_owner_full_name, v_user_id)
  returning id into v_person_id;

  update public.profiles
  set person_id = v_person_id
  where id = v_user_id;

  insert into public.church_user_roles (
    church_id,
    user_id,
    role_id,
    granted_by
  )
  values (
    v_church_id,
    v_user_id,
    v_senior_role_id,
    v_user_id
  );

  insert into public.audit_logs (
    church_id,
    actor_user_id,
    action,
    target_table,
    target_id,
    details
  )
  values (
    v_church_id,
    v_user_id,
    'church.created',
    'churches',
    v_church_id,
    jsonb_build_object('slug', p_slug)
  );

  return v_church_id;
end;
$$;

create or replace function public.create_member(
  p_church_id uuid,
  p_full_name text,
  p_assigned_admin_user_id uuid default null
)
returns table (
  person_id uuid,
  membership_id uuid,
  assignment_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public, app_private, auth
as $$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_assignee_id uuid;
  v_assignee_role text;
  v_max_members integer;
  v_current_assignments bigint;
  v_person_id uuid;
  v_membership_id uuid;
  v_assignment_id uuid;
begin
  if v_actor_id is null then
    raise exception 'Autenticação necessária para cadastrar um membro.'
      using errcode = '28000';
  end if;

  select role.key
  into v_actor_role
  from public.church_user_roles as church_role
  join public.roles as role on role.id = church_role.role_id
  where church_role.church_id = p_church_id
    and church_role.user_id = v_actor_id
    and church_role.status = 'active'
  for update of church_role;

  if not found then
    raise exception 'A conta não possui papel ativo nesta igreja.'
      using errcode = '42501';
  end if;

  if v_actor_role = 'secondary' then
    if not app_private.has_permission(p_church_id, 'members.create') then
      raise exception 'Permissão para cadastrar membros não concedida.'
        using errcode = '42501';
    end if;

    if p_assigned_admin_user_id is not null
       and p_assigned_admin_user_id <> v_actor_id then
      raise exception 'Administrador Secundário só pode atribuir o cadastro a si mesmo.'
        using errcode = '42501';
    end if;

    v_assignee_id := v_actor_id;
  elsif v_actor_role = 'senior' then
    if p_assigned_admin_user_id is null then
      raise exception 'Informe o Administrador Secundário responsável pelo membro.'
        using errcode = '22023';
    end if;

    v_assignee_id := p_assigned_admin_user_id;
  else
    raise exception 'Somente Administradores podem cadastrar membros.'
      using errcode = '42501';
  end if;

  select role.key
  into v_assignee_role
  from public.church_user_roles as church_role
  join public.roles as role on role.id = church_role.role_id
  where church_role.church_id = p_church_id
    and church_role.user_id = v_assignee_id
    and church_role.status = 'active'
  for share of church_role;

  if v_assignee_role is distinct from 'secondary' then
    raise exception 'O responsável deve ser um Administrador Secundário ativo da igreja.'
      using errcode = '22023';
  end if;

  select admin_limit.max_members
  into v_max_members
  from public.admin_member_limits as admin_limit
  where admin_limit.church_id = p_church_id
    and admin_limit.admin_user_id = v_assignee_id
  for update;

  if not found then
    raise exception 'O Administrador Secundário ainda não possui limite configurado.'
      using errcode = '55000';
  end if;

  select count(*)
  into v_current_assignments
  from public.member_assignments as assignment
  where assignment.church_id = p_church_id
    and assignment.admin_user_id = v_assignee_id
    and assignment.ended_at is null;

  if v_current_assignments >= v_max_members then
    raise exception 'Limite de membros do Administrador Secundário atingido.'
      using errcode = '23514';
  end if;

  insert into public.people (church_id, full_name, created_by)
  values (p_church_id, p_full_name, v_actor_id)
  returning id into v_person_id;

  insert into public.church_memberships (church_id, person_id)
  values (p_church_id, v_person_id)
  returning id into v_membership_id;

  insert into public.member_assignments (
    church_id,
    membership_id,
    admin_user_id,
    assigned_by
  )
  values (
    p_church_id,
    v_membership_id,
    v_assignee_id,
    v_actor_id
  )
  returning id into v_assignment_id;

  insert into public.audit_logs (
    church_id,
    actor_user_id,
    action,
    target_table,
    target_id,
    details
  )
  values (
    p_church_id,
    v_actor_id,
    'member.created',
    'church_memberships',
    v_membership_id,
    jsonb_build_object(
      'person_id', v_person_id,
      'admin_user_id', v_assignee_id,
      'assignment_id', v_assignment_id
    )
  );

  return query
  select v_person_id, v_membership_id, v_assignment_id;
end;
$$;

create or replace function public.configure_secondary_admin(
  p_church_id uuid,
  p_user_id uuid,
  p_max_members integer,
  p_package_keys text[] default '{}'::text[]
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, app_private, auth
as $$
declare
  v_actor_id uuid := auth.uid();
  v_current_role text;
  v_secondary_role_id uuid;
  v_package_keys text[] := coalesce(p_package_keys, '{}'::text[]);
begin
  if v_actor_id is null then
    raise exception 'Autenticação necessária para configurar um Administrador Secundário.'
      using errcode = '28000';
  end if;

  if not app_private.is_church_senior(p_church_id) then
    raise exception 'Somente o Administrador Sênior pode configurar Secundários.'
      using errcode = '42501';
  end if;

  if p_user_id = v_actor_id then
    raise exception 'O Administrador Sênior não pode configurar a própria conta como Secundário.'
      using errcode = '22023';
  end if;

  if p_max_members is null or p_max_members < 0 then
    raise exception 'O limite de membros deve ser um inteiro não negativo.'
      using errcode = '22023';
  end if;

  select role.key
  into v_current_role
  from public.church_user_roles as church_role
  join public.roles as role on role.id = church_role.role_id
  where church_role.church_id = p_church_id
    and church_role.user_id = p_user_id
  for update of church_role;

  if v_current_role = 'senior' then
    raise exception 'Um Administrador Sênior não pode ser rebaixado por esta operação.'
      using errcode = '42501';
  end if;

  if exists (
    select 1
    from unnest(v_package_keys) as requested(package_key)
    left join public.permission_packages as package
      on package.key = requested.package_key
    where package.id is null
  ) then
    raise exception 'Um ou mais pacotes de permissão informados não existem.'
      using errcode = '22023';
  end if;

  select role.id
  into v_secondary_role_id
  from public.roles as role
  where role.key = 'secondary';

  if v_secondary_role_id is null then
    raise exception 'Papel de Administrador Secundário não está configurado.'
      using errcode = '55000';
  end if;

  insert into public.church_user_roles (
    church_id,
    user_id,
    role_id,
    status,
    granted_by
  )
  values (
    p_church_id,
    p_user_id,
    v_secondary_role_id,
    'active',
    v_actor_id
  )
  on conflict (church_id, user_id)
  do update set
    role_id = excluded.role_id,
    status = 'active',
    granted_by = excluded.granted_by,
    updated_at = now();

  insert into public.admin_member_limits (
    church_id,
    admin_user_id,
    max_members,
    changed_by
  )
  values (
    p_church_id,
    p_user_id,
    p_max_members,
    v_actor_id
  )
  on conflict (church_id, admin_user_id)
  do update set
    max_members = excluded.max_members,
    changed_by = excluded.changed_by,
    updated_at = now();

  update public.admin_package_assignments as assignment
  set revoked_at = now()
  where assignment.church_id = p_church_id
    and assignment.user_id = p_user_id
    and assignment.revoked_at is null
    and not exists (
      select 1
      from public.permission_packages as package
      where package.id = assignment.package_id
        and package.key = any (v_package_keys)
    );

  insert into public.admin_package_assignments (
    church_id,
    user_id,
    package_id,
    granted_by
  )
  select p_church_id, p_user_id, package.id, v_actor_id
  from public.permission_packages as package
  where package.key = any (v_package_keys)
  on conflict (church_id, user_id, package_id)
    where revoked_at is null
  do nothing;

  update public.admin_permission_overrides as permission_override
  set revoked_at = now()
  from public.permissions as permission
  where permission_override.church_id = p_church_id
    and permission_override.user_id = p_user_id
    and permission_override.permission_id = permission.id
    and permission_override.revoked_at is null
    and permission_override.effect = 'grant'
    and (
      permission.key like 'contributions.%'
      or permission.key like 'treasury_entries.%'
    )
    and not exists (
      select 1
      from public.admin_package_assignments as assignment
      join public.permission_packages as package
        on package.id = assignment.package_id
      where assignment.church_id = p_church_id
        and assignment.user_id = p_user_id
        and assignment.revoked_at is null
        and package.key = 'finance_high_privilege'
    );

  insert into public.audit_logs (
    church_id,
    actor_user_id,
    action,
    target_table,
    target_id,
    details
  )
  values (
    p_church_id,
    v_actor_id,
    'admin.secondary.configured',
    'church_user_roles',
    null,
    jsonb_build_object(
      'user_id', p_user_id,
      'max_members', p_max_members,
      'package_keys', to_jsonb(v_package_keys)
    )
  );
end;
$$;

create or replace function public.set_admin_permission_override(
  p_church_id uuid,
  p_user_id uuid,
  p_permission_key text,
  p_effect text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, app_private, auth
as $$
declare
  v_actor_id uuid := auth.uid();
  v_user_role text;
  v_permission_id uuid;
  v_updated_rows integer;
begin
  if v_actor_id is null then
    raise exception 'Autenticação necessária para ajustar uma permissão.'
      using errcode = '28000';
  end if;

  if not app_private.is_church_senior(p_church_id) then
    raise exception 'Somente o Administrador Sênior pode ajustar permissões.'
      using errcode = '42501';
  end if;

  select role.key
  into v_user_role
  from public.church_user_roles as church_role
  join public.roles as role on role.id = church_role.role_id
  where church_role.church_id = p_church_id
    and church_role.user_id = p_user_id
    and church_role.status = 'active'
  for update of church_role;

  if v_user_role is distinct from 'secondary' then
    raise exception 'As exceções de permissão só se aplicam a Administradores Secundários ativos.'
      using errcode = '22023';
  end if;

  if p_effect is null then
    update public.admin_permission_overrides as permission_override
    set revoked_at = now()
    from public.permissions as permission
    where permission_override.church_id = p_church_id
      and permission_override.user_id = p_user_id
      and permission_override.permission_id = permission.id
      and permission.key = p_permission_key
      and permission_override.revoked_at is null;

    get diagnostics v_updated_rows = row_count;
    if v_updated_rows > 0 then
      insert into public.audit_logs (
        church_id,
        actor_user_id,
        action,
        target_table,
        details
      )
      values (
        p_church_id,
        v_actor_id,
        'admin.permission_override.cleared',
        'admin_permission_overrides',
        jsonb_build_object('user_id', p_user_id, 'permission_key', p_permission_key)
      );
    end if;

    return;
  end if;

  if p_effect not in ('grant', 'deny') then
    raise exception 'Efeito de permissão inválido; use grant, deny ou null para remover a exceção.'
      using errcode = '22023';
  end if;

  select permission.id
  into v_permission_id
  from public.permissions as permission
  where permission.key = p_permission_key;

  if v_permission_id is null then
    raise exception 'Permissão não encontrada.'
      using errcode = '22023';
  end if;

  if p_effect = 'grant'
     and (p_permission_key like 'contributions.%'
       or p_permission_key like 'treasury_entries.%')
     and not exists (
       select 1
       from public.admin_package_assignments as assignment
       join public.permission_packages as package
         on package.id = assignment.package_id
       where assignment.church_id = p_church_id
         and assignment.user_id = p_user_id
         and assignment.revoked_at is null
         and package.key = 'finance_high_privilege'
     ) then
    raise exception 'Para conceder permissão financeira, atribua primeiro o pacote de alto privilégio.'
      using errcode = '42501';
  end if;

  update public.admin_permission_overrides as permission_override
  set effect = p_effect,
      granted_by = v_actor_id,
      created_at = now()
  where permission_override.church_id = p_church_id
    and permission_override.user_id = p_user_id
    and permission_override.permission_id = v_permission_id
    and permission_override.revoked_at is null;

  get diagnostics v_updated_rows = row_count;
  if v_updated_rows = 0 then
    insert into public.admin_permission_overrides (
      church_id,
      user_id,
      permission_id,
      effect,
      granted_by
    )
    values (
      p_church_id,
      p_user_id,
      v_permission_id,
      p_effect,
      v_actor_id
    );
  end if;

  insert into public.audit_logs (
    church_id,
    actor_user_id,
    action,
    target_table,
    details
  )
  values (
    p_church_id,
    v_actor_id,
    'admin.permission_override.changed',
    'admin_permission_overrides',
    jsonb_build_object(
      'user_id', p_user_id,
      'permission_key', p_permission_key,
      'effect', p_effect
    )
  );
end;
$$;

revoke all on function public.create_church(text, text, text)
  from public, anon;
revoke all on function public.create_member(uuid, text, uuid)
  from public, anon;
revoke all on function public.configure_secondary_admin(uuid, uuid, integer, text[])
  from public, anon;
revoke all on function public.set_admin_permission_override(uuid, uuid, text, text)
  from public, anon;

grant execute on function public.create_church(text, text, text)
  to authenticated;
grant execute on function public.create_member(uuid, text, uuid)
  to authenticated;
grant execute on function public.configure_secondary_admin(uuid, uuid, integer, text[])
  to authenticated;
grant execute on function public.set_admin_permission_override(uuid, uuid, text, text)
  to authenticated;

commit;
