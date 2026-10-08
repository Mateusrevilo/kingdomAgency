import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseConfig } from "@/lib/supabase/config";

export async function proxy(request: NextRequest) {
  const { url, publishableKey } = getSupabaseConfig();
  let response = NextResponse.next({ request });

  const supabase = createServerClient(url, publishableKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet, headers) {
        cookiesToSet.forEach(({ name, value }) => {
          request.cookies.set(name, value);
        });

        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => {
          response.cookies.set(name, value, options);
        });

        for (const header of ["cache-control", "expires", "pragma"] as const) {
          const value = headers[header];
          if (value) {
            response.headers.set(header, value);
          }
        }
      },
    },
  });

  const { data, error } = await supabase.auth.getClaims();
  if (error) {
    throw error;
  }

  const isDashboardRoute = request.nextUrl.pathname.startsWith("/dashboard");
  const hasVerifiedSession = Boolean(data?.claims);
  const redirectPath = isDashboardRoute
    ? hasVerifiedSession
      ? null
      : "/login"
    : hasVerifiedSession
      ? "/dashboard"
      : null;

  if (redirectPath) {
    const redirectResponse = NextResponse.redirect(
      new URL(redirectPath, request.url),
    );

    response.cookies.getAll().forEach((cookie) => {
      redirectResponse.cookies.set(cookie);
    });

    for (const header of ["cache-control", "expires", "pragma"] as const) {
      const value = response.headers.get(header);
      if (value) {
        redirectResponse.headers.set(header, value);
      }
    }

    return redirectResponse;
  }

  return response;
}

export const config = {
  matcher: ["/dashboard/:path*", "/login"],
};
