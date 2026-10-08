"use client";

import { useEffect, useState } from "react";
import { ApiError, api, type Category } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const COLORS = ["#6366f1", "#ec4899", "#f59e0b", "#10b981", "#0ea5e9", "#ef4444", "#8b5cf6", "#64748b"];

export default function CategoriesPage() {
  const userId = useAuth().user?.id;
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState("");
  const [color, setColor] = useState(COLORS[0]);
  const [error, setError] = useState<string | null>(null);

  const load = () =>
    api
      .categories()
      .then(setCategories)
      .finally(() => setLoading(false));

  useEffect(() => {
    if (userId) load();
  }, [userId]);

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      await api.createCategory({ name: name.trim(), color });
      setName("");
      load();
    } catch (err) {
      setError(err instanceof ApiError ? (err.errors.name?.[0] ?? err.message) : "Gagal menambah kategori.");
    }
  }

  async function handleDelete(c: Category) {
    const extra = c.todos_count ? ` ${c.todos_count} tugas di dalamnya akan dipindah ke "Tanpa Kategori".` : "";
    if (!confirm(`Hapus kategori "${c.name}"?${extra}`)) return;
    setCategories((list) => list.filter((x) => x.id !== c.id));
    await api.deleteCategory(c.id).catch(load);
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Kategori</h1>

      <form onSubmit={handleAdd} className="card space-y-3 p-4">
        <div className="flex gap-3">
          <input
            className="input"
            placeholder="Nama kategori baru…"
            value={name}
            onChange={(e) => setName(e.target.value)}
            maxLength={50}
            required
          />
          <button type="submit" className="btn-primary shrink-0">
            Tambah
          </button>
        </div>
        <div className="flex flex-wrap gap-2" role="radiogroup" aria-label="Warna kategori">
          {COLORS.map((c) => (
            <button
              key={c}
              type="button"
              role="radio"
              aria-checked={color === c}
              aria-label={c}
              onClick={() => setColor(c)}
              className={`h-7 w-7 rounded-full transition ${color === c ? "ring-2 ring-offset-2" : ""}`}
              style={{ background: c, ["--tw-ring-color" as string]: c }}
            />
          ))}
        </div>
        {error && <p className="text-sm text-red-600">{error}</p>}
      </form>

      <section className="card overflow-hidden">
        <ul className="divide-y divide-slate-100">
          <li className="flex items-center gap-3 px-4 py-3">
            <span className="h-3 w-3 rounded-full bg-gray-400" />
            <span className="flex-1 text-sm font-medium">Tanpa Kategori</span>
            <span className="text-xs text-slate-400">Default</span>
          </li>
          {loading ? (
            <li className="p-4 text-center text-sm text-slate-500">Memuat…</li>
          ) : (
            categories.map((c) => (
              <li key={c.id} className="flex items-center gap-3 px-4 py-3">
                <span className="h-3 w-3 rounded-full" style={{ background: c.color }} />
                <span className="flex-1 text-sm font-medium">{c.name}</span>
                <span className="text-xs text-slate-500">
                  {c.pending_count ?? 0} aktif · {c.todos_count ?? 0} total
                </span>
                <button
                  onClick={() => handleDelete(c)}
                  className="rounded-md px-2 py-1 text-xs text-slate-400 hover:bg-red-50 hover:text-red-600"
                >
                  Hapus
                </button>
              </li>
            ))
          )}
        </ul>
      </section>
    </div>
  );
}
