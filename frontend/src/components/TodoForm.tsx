"use client";

import { useState } from "react";
import { ApiError, DESCRIPTION_MAX, type Category, type TodoInput } from "@/lib/api";
import { useToday } from "@/lib/useToday";

type Props = {
  categories: Category[];
  onSubmit: (data: TodoInput) => Promise<void>;
  defaultDate?: string;
  defaultCategoryId?: number | null;
};

export function TodoForm({ categories, onSubmit, defaultDate, defaultCategoryId = null }: Props) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const today = useToday();
  // Kosong = ikut tanggal hari ini (dibaca di client, bukan saat prerender)
  const [pickedDate, setDueDate] = useState(defaultDate ?? "");
  const dueDate = pickedDate || today || "";
  const [categoryId, setCategoryId] = useState<string>(defaultCategoryId ? String(defaultCategoryId) : "");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await onSubmit({
        title: title.trim(),
        description: description.trim() || null,
        due_date: dueDate,
        category_id: categoryId ? Number(categoryId) : null,
      });
      setTitle("");
      setDescription("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal menyimpan tugas.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="card space-y-3 p-4">
      <input
        className="input"
        placeholder="Tambah tugas baru…"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        required
      />
      <div>
        <textarea
          className="input min-h-28 resize-y"
          placeholder="Deskripsi tugas (opsional) — detail, langkah-langkah, tautan, dll."
          value={description}
          maxLength={DESCRIPTION_MAX}
          onChange={(e) => setDescription(e.target.value)}
        />
        <p className="mt-1 text-right text-xs text-slate-400">
          {description.length.toLocaleString("id-ID")}/{DESCRIPTION_MAX.toLocaleString("id-ID")}
        </p>
      </div>
      <div className="flex flex-col gap-3 sm:flex-row">
        <select className="input sm:w-auto sm:flex-1" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
          <option value="">Tanpa Kategori</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <input
          type="date"
          className="input sm:w-auto"
          value={dueDate}
          onChange={(e) => setDueDate(e.target.value)}
          required
        />
        <button type="submit" className="btn-primary" disabled={saving}>
          {saving ? "Menyimpan…" : "Tambah"}
        </button>
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
    </form>
  );
}
