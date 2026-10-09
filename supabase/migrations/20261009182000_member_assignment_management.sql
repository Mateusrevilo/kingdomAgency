begin;

create or replace function public.transfer_member_assignment(
  p_church_id uuid,
  p_membership_id uuid,
  p_new_admin_user_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, app_private, auth
as $$
declare
  v_actor_id uuid := auth.uid();
  v_current_assignment_id uuid;
  v_current_admin_user_id uuid;
  v_new_admin_role text;
  v_max_members integer;
  v_current_assignments bigint;
  v_new_assignment_id uuid;
begin
  if v_actor_id is null then
    raise exception 'Autenticação necessária para transferir uma atribuição.'
      using errcode = '28000';
  end if;

  if p_church_id is null
     or p_membership_id is null
     or p_new_admin_user_id is null then
    raise exception 'Igreja, membro e novo responsável são obrigatórios.'
      using errcode = '22023';
  end if;

  if not app_private.is_church_senior(p_church_id) then
    raise exception 'Somente o Administrador Sênior pode transferir atribuições.'
      using errcode = '42501';
  end if;

  perform membership.id
  from public.church_memberships as membership
  where membership.church_id = p_church_id
    and membership.id = p_membership_id
  for update;

  if not found then
    raise exception 'Membro não encontrado nesta igreja.'
      using errcode = '22023';
  end if;

  select assignment.id, assignment.admin_user_id
  into v_current_assignment_id, v_current_admin_user_id
  from public.member_assignments as assignment
  where assignment.church_id = p_church_id
    and assignment.membership_id = p_membership_id
    and assignment.ended_at is null
  for update;

  if not found then
    raise exception 'O membro não possui uma atribuição atual para transferir.'
      using errcode = '22023';
  end if;

  if p_new_admin_user_id = v_current_admin_user_id then
    raise exception 'O novo responsável deve ser diferente do responsável atual.'
      using errcode = '22023';
  end if;

  perform church_role.user_id
  from public.church_user_roles as church_role
  where church_role.church_id = p_church_id
    and church_role.user_id in (
      v_current_admin_user_id,
      p_new_admin_user_id
    )
  order by church_role.user_id
  for share of church_role;

  select role.key
  into v_new_admin_role
  from public.church_user_roles as church_role
  join public.roles as role on role.id = church_role.role_id
  where church_role.church_id = p_church_id
    and church_role.user_id = p_new_admin_user_id
    and church_role.status = 'active'
  for share of church_role;

  if v_new_admin_role is distinct from 'secondary' then
    raise exception 'O novo responsável deve ser um Administrador Secundário ativo da igreja.'
      using errcode = '22023';
  end if;

  perform admin_limit.admin_user_id
  from public.admin_member_limits as admin_limit
  where admin_limit.church_id = p_church_id
    and admin_limit.admin_user_id in (
      v_current_admin_user_id,
      p_new_admin_user_id
    )
  order by admin_limit.admin_user_id
  for update of admin_limit;

  select admin_limit.max_members
  into v_max_members
  from public.admin_member_limits as admin_limit
  where admin_limit.church_id = p_church_id
    and admin_limit.admin_user_id = p_new_admin_user_id;

  if not found then
    raise exception 'O novo responsável ainda não possui limite configurado.'
      using errcode = '55000';
  end if;

  select count(*)
  into v_current_assignments
  from public.member_assignments as assignment
  where assignment.church_id = p_church_id
    and assignment.admin_user_id = p_new_admin_user_id
    and assignment.ended_at is null;

  if v_current_assignments >= v_max_members then
    raise exception 'Limite de membros do novo responsável atingido.'
      using errcode = '23514';
  end if;

  update public.member_assignments
  set ended_at = now(),
      ended_by = v_actor_id,
      end_reason = 'transferred'
  where id = v_current_assignment_id;

  insert into public.member_assignments (
    church_id,
    membership_id,
    admin_user_id,
    assigned_by
  )
  values (
    p_church_id,
    p_membership_id,
    p_new_admin_user_id,
    v_actor_id
  )
  returning id into v_new_assignment_id;

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
    'member.assignment.transferred',
    'member_assignments',
    v_new_assignment_id,
    jsonb_build_object(
      'membership_id', p_membership_id,
      'previous_assignment_id', v_current_assignment_id,
      'from_admin_user_id', v_current_admin_user_id,
      'to_admin_user_id', p_new_admin_user_id
    )
  );

  return v_new_assignment_id;
end;
$$;

create or replace function public.remove_member_assignment(
  p_church_id uuid,
  p_membership_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, app_private, auth
as $$
declare
  v_actor_id uuid := auth.uid();
  v_assignment_id uuid;
  v_admin_user_id uuid;
begin
  if v_actor_id is null then
    raise exception 'Autenticação necessária para remover uma atribuição.'
      using errcode = '28000';
  end if;

  if p_church_id is null or p_membership_id is null then
    raise exception 'Igreja e membro são obrigatórios.'
      using errcode = '22023';
  end if;

  if not app_private.is_church_senior(p_church_id) then
    raise exception 'Somente o Administrador Sênior pode remover atribuições.'
      using errcode = '42501';
  end if;

  perform membership.id
  from public.church_memberships as membership
  where membership.church_id = p_church_id
    and membership.id = p_membership_id
  for update;

  if not found then
    raise exception 'Membro não encontrado nesta igreja.'
      using errcode = '22023';
  end if;

  select assignment.id, assignment.admin_user_id
  into v_assignment_id, v_admin_user_id
  from public.member_assignments as assignment
  where assignment.church_id = p_church_id
    and assignment.membership_id = p_membership_id
    and assignment.ended_at is null
  for update;

  if not found then
    raise exception 'O membro não possui uma atribuição atual para remover.'
      using errcode = '22023';
  end if;

  perform 1
  from public.admin_member_limits as admin_limit
  where admin_limit.church_id = p_church_id
    and admin_limit.admin_user_id = v_admin_user_id
  for update;

  if not found then
    raise exception 'Limite do responsável atual não encontrado.'
      using errcode = '55000';
  end if;

  update public.member_assignments
  set ended_at = now(),
      ended_by = v_actor_id,
      end_reason = 'removed'
  where id = v_assignment_id;

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
    'member.assignment.removed',
    'member_assignments',
    v_assignment_id,
    jsonb_build_object(
      'membership_id', p_membership_id,
      'admin_user_id', v_admin_user_id
    )
  );

  return v_assignment_id;
end;
$$;

revoke all on function public.transfer_member_assignment(uuid, uuid, uuid)
  from public, anon;
revoke all on function public.remove_member_assignment(uuid, uuid)
  from public, anon;

grant execute on function public.transfer_member_assignment(uuid, uuid, uuid)
  to authenticated;
grant execute on function public.remove_member_assignment(uuid, uuid)
  to authenticated;

commit;
