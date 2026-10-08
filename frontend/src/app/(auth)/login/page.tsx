"use client";

import Link from "next/link";
import { useState } from "react";
import { AuthCard } from "@/components/AuthCard";
import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";

export default function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await login(email, password);
    } catch (err) {
      setError(err instanceof ApiError ? (err.errors.email?.[0] ?? err.message) : "Gagal login.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthCard title="Masuk" subtitle="Kelola tugas harianmu">
      <form onSubmit={handleSubmit} className="space-y-4">
        <label className="block space-y-1 text-sm">
          <span className="font-medium">Email</span>
          <input type="email" className="input" value={email} onChange={(e) => setEmail(e.target.value)} required autoFocus />
        </label>
        <label className="block space-y-1 text-sm">
          <span className="font-medium">Password</span>
          <input type="password" className="input" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </label>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button type="submit" className="btn-primary w-full" disabled={submitting}>
          {submitting ? "Memproses…" : "Masuk"}
        </button>
      </form>
      <p className="mt-4 text-center text-sm text-slate-500">
        Belum punya akun?{" "}
        <Link href="/register" className="font-medium text-indigo-600 hover:underline">
          Daftar
        </Link>
      </p>
    </AuthCard>
  );
}
