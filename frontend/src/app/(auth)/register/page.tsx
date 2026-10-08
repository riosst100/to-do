"use client";

import Link from "next/link";
import { useState } from "react";
import { AuthCard } from "@/components/AuthCard";
import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";

export default function RegisterPage() {
  const { register } = useAuth();
  const [form, setForm] = useState({ name: "", email: "", password: "", password_confirmation: "" });
  const [errors, setErrors] = useState<Record<string, string[]>>({});
  const [message, setMessage] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const set = (key: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm((f) => ({ ...f, [key]: e.target.value }));

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setErrors({});
    setMessage(null);
    try {
      await register(form.name, form.email, form.password, form.password_confirmation);
    } catch (err) {
      if (err instanceof ApiError) {
        setErrors(err.errors);
        if (!Object.keys(err.errors).length) setMessage(err.message);
      } else setMessage("Gagal mendaftar.");
    } finally {
      setSubmitting(false);
    }
  }

  const fields: { key: keyof typeof form; label: string; type: string }[] = [
    { key: "name", label: "Nama", type: "text" },
    { key: "email", label: "Email", type: "email" },
    { key: "password", label: "Password", type: "password" },
    { key: "password_confirmation", label: "Konfirmasi Password", type: "password" },
  ];

  return (
    <AuthCard title="Daftar" subtitle="Buat akun untuk mulai mencatat tugas">
      <form onSubmit={handleSubmit} className="space-y-4">
        {fields.map((f) => (
          <label key={f.key} className="block space-y-1 text-sm">
            <span className="font-medium">{f.label}</span>
            <input type={f.type} className="input" value={form[f.key]} onChange={set(f.key)} required />
            {errors[f.key] && <span className="text-xs text-red-600">{errors[f.key][0]}</span>}
          </label>
        ))}
        {message && <p className="text-sm text-red-600">{message}</p>}
        <button type="submit" className="btn-primary w-full" disabled={submitting}>
          {submitting ? "Memproses…" : "Daftar"}
        </button>
      </form>
      <p className="mt-4 text-center text-sm text-slate-500">
        Sudah punya akun?{" "}
        <Link href="/login" className="font-medium text-indigo-600 hover:underline">
          Masuk
        </Link>
      </p>
    </AuthCard>
  );
}
