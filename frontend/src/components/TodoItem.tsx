"use client";

import { useState } from "react";
import { ApiError, DESCRIPTION_MAX, type Todo, type TodoInput } from "@/lib/api";
import { formatDate } from "@/lib/date";

type Props = {
  todo: Todo;
  onToggle: (todo: Todo) => void;
  onDelete: (todo: Todo) => void;
  onUpdate?: (todo: Todo, data: Partial<TodoInput>) => Promise<void>;
  showDate?: boolean;
  showCategory?: boolean;
};

// Deskripsi lebih panjang dari ini dipotong (line-clamp) sampai diklik "Selengkapnya"
const COLLAPSE_CHARS = 180;
const COLLAPSE_LINES = 3;

export function TodoItem({ todo, onToggle, onDelete, onUpdate, showDate = true, showCategory = true }: Props) {
  const [expanded, setExpanded] = useState(false);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const description = todo.description ?? "";
  const isLong = description.length > COLLAPSE_CHARS || description.split("\n").length > COLLAPSE_LINES;

  function startEdit() {
    setDraft(description);
    setError(null);
    setEditing(true);
  }

  async function saveEdit() {
    if (!onUpdate) return;
    setSaving(true);
    setError(null);
    try {
      await onUpdate(todo, { description: draft.trim() || null });
      setEditing(false);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal menyimpan deskripsi.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <li className="group flex items-start gap-3 px-4 py-3">
      <input
        type="checkbox"
        checked={todo.is_completed}
        onChange={() => onToggle(todo)}
        className="mt-0.5 h-5 w-5 shrink-0 cursor-pointer accent-indigo-600"
        aria-label={`Tandai "${todo.title}" selesai`}
      />
      <div className="min-w-0 flex-1">
        <p className={`text-sm font-medium ${todo.is_completed ? "text-slate-400 line-through" : "text-slate-800"}`}>
          {todo.title}
        </p>

        {editing ? (
          <div className="mt-2 space-y-2">
            <textarea
              className="input min-h-32 resize-y"
              placeholder="Deskripsi tugas — detail, langkah-langkah, tautan, dll."
              value={draft}
              maxLength={DESCRIPTION_MAX}
              onChange={(e) => setDraft(e.target.value)}
              autoFocus
            />
            <div className="flex items-center gap-2">
              <button type="button" className="btn-primary px-3 py-1 text-xs" onClick={saveEdit} disabled={saving}>
                {saving ? "Menyimpan…" : "Simpan"}
              </button>
              <button type="button" className="btn-ghost px-3 py-1 text-xs" onClick={() => setEditing(false)}>
                Batal
              </button>
              <span className="ml-auto text-xs text-slate-400">
                {draft.length.toLocaleString("id-ID")}/{DESCRIPTION_MAX.toLocaleString("id-ID")}
              </span>
            </div>
            {error && <p className="text-xs text-red-600">{error}</p>}
          </div>
        ) : (
          description && (
            <div className="mt-1">
              <p
                className={`whitespace-pre-line break-words text-xs leading-relaxed text-slate-500 ${
                  isLong && !expanded ? "line-clamp-3" : ""
                }`}
              >
                {description}
              </p>
              {isLong && (
                <button
                  type="button"
                  onClick={() => setExpanded((v) => !v)}
                  className="mt-0.5 text-xs font-medium text-indigo-600 hover:underline"
                >
                  {expanded ? "Ringkas" : "Selengkapnya"}
                </button>
              )}
            </div>
          )
        )}

        <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-slate-500">
          {showCategory && (
            <span className="inline-flex items-center gap-1">
              <span className="h-2 w-2 rounded-full" style={{ background: todo.category.color }} />
              {todo.category.name}
            </span>
          )}
          {showDate && <span>{formatDate(todo.due_date)}</span>}
        </div>
      </div>
      <div className="flex shrink-0 gap-1 opacity-100 transition sm:opacity-0 sm:group-hover:opacity-100 sm:group-focus-within:opacity-100">
        {onUpdate && !editing && (
          <button
            onClick={startEdit}
            className="rounded-md px-2 py-1 text-xs text-slate-400 hover:bg-indigo-50 hover:text-indigo-600"
            aria-label={`${description ? "Ubah" : "Tambah"} deskripsi "${todo.title}"`}
          >
            {description ? "Ubah deskripsi" : "+ Deskripsi"}
          </button>
        )}
        <button
          onClick={() => onDelete(todo)}
          className="rounded-md px-2 py-1 text-xs text-slate-400 hover:bg-red-50 hover:text-red-600"
          aria-label={`Hapus "${todo.title}"`}
        >
          Hapus
        </button>
      </div>
    </li>
  );
}
