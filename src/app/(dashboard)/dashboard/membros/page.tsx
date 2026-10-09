import Link from "next/link";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { AssignmentControls } from "./assignment-controls";

type MembersPageProps = {
  searchParams: Promise<{ igreja?: string | string[] }>;
};

export default async function MembersPage({ searchParams }: MembersPageProps) {
  const supabase = await createSupabaseServerClient();
  const { data: claimsData, error: claimsError } =
    await supabase.auth.getClaims();

  if (claimsError) {
    throw claimsError;
  }

  const userId = claimsData?.claims?.sub;
  if (typeof userId !== "string") {
    redirect("/login");
  }

  const { data: ownRoles, error: ownRolesError } = await supabase
    .from("church_user_roles")
    .select("church_id, role_id")
    .eq("user_id", userId)
    .eq("status", "active");

  if (ownRolesError) {
    throw ownRolesError;
  }

  const roleIds = [...new Set((ownRoles ?? []).map((role) => role.role_id))];
  const { data: roles, error: rolesError } =
    roleIds.length > 0
      ? await supabase.from("roles").select("id, key").in("id", roleIds)
      : { data: [], error: null };

  if (rolesError) {
    throw rolesError;
  }

  const seniorRoleIds = new Set(
    (roles ?? []).filter((role) => role.key === "senior").map((role) => role.id),
  );
  const seniorChurchIds = [
    ...new Set(
      (ownRoles ?? [])
        .filter((role) => seniorRoleIds.has(role.role_id))
        .map((role) => role.church_id),
    ),
  ];

  const { data: churchRows, error: churchesError } =
    seniorChurchIds.length > 0
      ? await supabase
          .from("churches")
          .select("id, name")
          .in("id", seniorChurchIds)
          .order("name")
      : { data: [], error: null };

  if (churchesError) {
    throw churchesError;
  }

  const churches = churchRows ?? [];
  const params = await searchParams;
  const requestedChurchId = params.igreja;
  const invalidChurchSelection =
    requestedChurchId !== undefined &&
    (typeof requestedChurchId !== "string" ||
      !churches.some((church) => church.id === requestedChurchId));
  const selectedChurch = invalidChurchSelection
    ? undefined
    : churches.find((church) => church.id === requestedChurchId) ??
      churches[0];

  let assignments: {
    id: string;
    membership_id: string;
    admin_user_id: string;
    memberName: string;
    membershipStatus: string;
  }[] = [];
  let secondaryAdmins: string[] = [];

  if (selectedChurch) {
    const [
      { data: churchRoles, error: churchRolesError },
      { data: memberships, error: membershipsError },
      { data: currentAssignments, error: assignmentsError },
    ] = await Promise.all([
      supabase
        .from("church_user_roles")
        .select("user_id, role_id")
        .eq("church_id", selectedChurch.id)
        .eq("status", "active"),
      supabase
        .from("church_memberships")
        .select("id, person_id, status")
        .eq("church_id", selectedChurch.id),
      supabase
        .from("member_assignments")
        .select("id, membership_id, admin_user_id")
        .eq("church_id", selectedChurch.id)
        .is("ended_at", null),
    ]);

    if (churchRolesError) {
      throw churchRolesError;
    }

    if (membershipsError) {
      throw membershipsError;
    }

    if (assignmentsError) {
      throw assignmentsError;
    }

    const secondaryRoleId = (roles ?? []).find(
      (role) => role.key === "secondary",
    )?.id;
    secondaryAdmins = [
      ...new Set(
        (churchRoles ?? [])
          .filter((role) => role.role_id === secondaryRoleId)
          .map((role) => role.user_id),
      ),
    ].sort();

    const personIds = [
      ...new Set((memberships ?? []).map((membership) => membership.person_id)),
    ];
    const { data: people, error: peopleError } =
      personIds.length > 0
        ? await supabase
            .from("people")
            .select("id, full_name")
            .eq("church_id", selectedChurch.id)
            .in("id", personIds)
        : { data: [], error: null };

    if (peopleError) {
      throw peopleError;
    }

    const membershipById = new Map(
      (memberships ?? []).map((membership) => [membership.id, membership]),
    );
    const personNameById = new Map(
      (people ?? []).map((person) => [person.id, person.full_name]),
    );

    assignments = (currentAssignments ?? []).map((assignment) => {
      const membership = membershipById.get(assignment.membership_id);
      const memberName = membership
        ? personNameById.get(membership.person_id)
        : undefined;

      if (!membership || !memberName) {
        throw new Error(
          "Não foi possível relacionar uma atribuição ao cadastro do membro.",
        );
      }

      return {
        id: assignment.id,
        membership_id: assignment.membership_id,
        admin_user_id: assignment.admin_user_id,
        memberName,
        membershipStatus: membership.status,
      };
    });
  }

  return (
    <main className="min-h-screen bg-background px-6 py-10 text-foreground sm:px-10">
      <div className="mx-auto max-w-5xl">
        <Link
          className="text-sm font-medium text-emerald-800 hover:underline"
          href="/dashboard"
        >
          Voltar ao painel
        </Link>
        <header className="mt-5">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-800">
            Administração da igreja
          </p>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight">
            Membros e responsáveis
          </h1>
          <p className="mt-2 max-w-2xl leading-7 text-slate-600">
            Transfira ou remova atribuições atuais. A transferência respeita o
            limite do novo Administrador Secundário; a remoção libera uma vaga
            e mantém o histórico.
          </p>
        </header>

        {churches.length === 0 ? (
          <section className="mt-8 rounded-2xl border border-slate-200 bg-white p-6">
            <p className="font-medium">Nenhuma igreja administrada como Sênior.</p>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Esta área está disponível somente para Administradores Sêniores
              ativos.
            </p>
          </section>
        ) : (
          <>
            <form
              action="/dashboard/membros"
              className="mt-8 flex max-w-xl flex-wrap items-end gap-3"
              method="get"
            >
              <div className="min-w-56 flex-1">
                <label
                  className="block text-sm font-medium text-slate-700"
                  htmlFor="igreja"
                >
                  Igreja
                </label>
                <select
                  className="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-slate-900 focus:border-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-700/20"
                  defaultValue={selectedChurch?.id ?? ""}
                  id="igreja"
                  name="igreja"
                >
                  {churches.map((church) => (
                    <option key={church.id} value={church.id}>
                      {church.name}
                    </option>
                  ))}
                </select>
              </div>
              <button
                className="rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
                type="submit"
              >
                Abrir igreja
              </button>
            </form>

            {invalidChurchSelection ? (
              <p className="mt-4 text-sm text-red-700" role="alert">
                A igreja selecionada não está disponível para sua conta.
              </p>
            ) : null}

            {selectedChurch ? (
              <section className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
                <h2 className="text-xl font-semibold">{selectedChurch.name}</h2>
                <p className="mt-1 text-sm text-slate-600">
                  {assignments.length}{" "}
                  {assignments.length === 1
                    ? "atribuição atual"
                    : "atribuições atuais"}
                </p>

                {assignments.length === 0 ? (
                  <p className="mt-6 rounded-lg bg-slate-50 p-4 text-sm text-slate-600">
                    Não há atribuições atuais para esta igreja.
                  </p>
                ) : (
                  <ul className="mt-6 divide-y divide-slate-200">
                    {assignments.map((assignment) => (
                      <li
                        className="grid gap-5 py-5 first:pt-0 last:pb-0 md:grid-cols-[minmax(12rem,1fr)_minmax(18rem,1.2fr)]"
                        key={assignment.id}
                      >
                        <div>
                          <p className="font-medium">{assignment.memberName}</p>
                          {assignment.membershipStatus === "inactive" ? (
                            <p className="mt-1 text-sm text-amber-800">
                              Vínculo de membro inativo; a atribuição continua
                              ocupando uma vaga.
                            </p>
                          ) : null}
                          <p className="mt-2 break-all text-xs text-slate-500">
                            Responsável atual:{" "}
                            {assignment.admin_user_id}
                          </p>
                        </div>
                        <AssignmentControls
                          adminOptions={secondaryAdmins
                            .filter(
                              (adminId) =>
                                adminId !== assignment.admin_user_id,
                            )
                            .map((adminId) => ({
                              id: adminId,
                              label: `Administrador Secundário ${adminId}`,
                            }))}
                          churchId={selectedChurch.id}
                          membershipId={assignment.membership_id}
                        />
                      </li>
                    ))}
                  </ul>
                )}
              </section>
            ) : null}
          </>
        )}
      </div>
    </main>
  );
}
