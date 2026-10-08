import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Gestão da Igreja",
  description: "Sistema de gerenciamento para igrejas.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="pt-BR">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
