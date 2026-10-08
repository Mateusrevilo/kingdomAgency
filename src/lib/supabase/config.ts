export function getSupabaseConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL. Add it to .env.local using .env.example as a reference.",
    );
  }

  if (!publishableKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY. " +
        "Add it to .env.local using .env.example as a reference.",
    );
  }

  if (!URL.canParse(url)) {
    throw new Error("NEXT_PUBLIC_SUPABASE_URL must be a valid URL.");
  }

  const parsedUrl = new URL(url);
  const isLocalhost = ["localhost", "127.0.0.1", "[::1]"].includes(
    parsedUrl.hostname,
  );

  if (
    parsedUrl.protocol !== "https:" &&
    !(isLocalhost && parsedUrl.protocol === "http:")
  ) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL must use HTTPS, except for localhost.",
    );
  }

  return { url, publishableKey };
}
