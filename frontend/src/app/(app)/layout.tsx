"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { useAuth } from "@/lib/auth";

const NAV = [
  { href: "/", label: "Beranda" },
  { href: "/tasks", label: "Tugas" },
  { href: "/categories", label: "Kategori" },
];

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!loading && !user) router.replace("/login");
  }, [loading, user, router]);

  return (
    <>
      <header className="sticky top-0 z-10 border-b border-slate-200 bg-white/90 backdrop-blur">
        <div className="mx-auto flex max-w-3xl items-center gap-2 px-4 py-3">
          <Link href="/" className="mr-2 flex items-center gap-2 font-semibold">
            <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-indigo-600 text-sm text-white">✓</span>
            <span className="hidden sm:inline">Todo</span>
          </Link>
          <nav className="flex flex-1 gap-1">
            {NAV.map((n) => (
              <Link
                key={n.href}
                href={n.href}
                className={`rounded-lg px-3 py-1.5 text-sm font-medium transition ${
                  pathname === n.href ? "bg-indigo-50 text-indigo-700" : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                {n.label}
              </Link>
            ))}
          </nav>
          {user && (
            <>
              <span className="hidden text-sm text-slate-500 md:inline">{user.name}</span>
              <button onClick={logout} className="btn-ghost px-3 py-1.5">
                Keluar
              </button>
            </>
          )}
        </div>
      </header>
      {/* Children selalu dirender (syarat validasi instant navigation); halaman baru fetch data setelah user siap. */}
      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-6">{children}</main>
    </>
  );
}
