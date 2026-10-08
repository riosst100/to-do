"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { TodoForm } from "@/components/TodoForm";
import { TodoItem } from "@/components/TodoItem";
import { api, type Category, type Todo, type TodoFilters, type TodoInput } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { useToday } from "@/lib/useToday";
import { useTodoActions } from "@/lib/useTodoActions";

type TimeMode = "all" | "date" | "month" | "year";

export default function TasksPage() {
  const userId = useAuth().user?.id;
  const today = useToday() ?? "";
  const currentYear = Number(today.slice(0, 4)) || 0;
  const [todos, setTodos] = useState<Todo[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [status, setStatus] = useState<"" | "pending" | "completed">("");
  const [timeMode, setTimeMode] = useState<TimeMode>("all");
  // Nilai kosong = default ke hari ini / bulan ini / tahun ini
  const [pickedDate, setDate] = useState("");
  const [pickedMonth, setMonth] = useState(""); // YYYY-MM
  const [pickedYear, setYear] = useState(0);
  const date = pickedDate || today;
  const month = pickedMonth || today.slice(0, 7);
  const year = pickedYear || currentYear;
  const years = currentYear ? Array.from({ length: 7 }, (_, i) => currentYear - 3 + i) : [];

  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(t);
  }, [search]);

  const filters = useMemo<TodoFilters>(() => {
    const f: TodoFilters = { search: debouncedSearch, category_id: categoryId, status: status || undefined };
    if (timeMode === "date" && date) f.date = date;
    if (timeMode === "month" && month) {
      const [y, m] = month.split("-").map(Number);
      f.year = y;
      f.month = m;
    }
    if (timeMode === "year" && year) f.year = year;
    return f;
  }, [debouncedSearch, categoryId, status, timeMode, date, month, year]);

  // Hasil lama tetap tampil selama refetch; "loading" hanya untuk muatan pertama.
  const load = useCallback(() => {
    api
      .todos(filters)
      .then(setTodos)
      .finally(() => setLoading(false));
  }, [filters]);

  useEffect(() => {
    if (userId) load();
  }, [userId, load]);
  useEffect(() => {
    if (userId) api.categories().then(setCategories);
  }, [userId]);

  const { toggle, remove } = useTodoActions(setTodos, load);

  async function handleCreate(data: TodoInput) {
    await api.createTodo(data);
    load();
  }

  // Kelompokkan per kategori; "Tanpa Kategori" selalu di urutan pertama.
  const groups = useMemo(() => {
    const map = new Map<string, { name: string; color: string; todos: Todo[] }>();
    for (const t of todos) {
      const key = t.category.id === null ? "none" : String(t.category.id);
      if (!map.has(key)) map.set(key, { name: t.category.name, color: t.category.color, todos: [] });
      map.get(key)!.todos.push(t);
    }
    return [...map.entries()]
      .sort(([a, x], [b, y]) => (a === "none" ? -1 : b === "none" ? 1 : x.name.localeCompare(y.name)))
      .map(([key, g]) => ({ key, ...g }));
  }, [todos]);

  const hasFilter = search || categoryId || status || timeMode !== "all";

  function resetFilters() {
    setSearch("");
    setCategoryId("");
    setStatus("");
    setTimeMode("all");
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Tugas</h1>
        <button className="btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? "Tutup" : "+ Tugas Baru"}
        </button>
      </div>

      {showForm && (
        <TodoForm
          categories={categories}
          onSubmit={handleCreate}
          defaultCategoryId={categoryId && categoryId !== "none" ? Number(categoryId) : null}
        />
      )}

      <section className="card space-y-3 p-4">
        <input
          type="search"
          className="input"
          placeholder="Cari tugas…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} aria-label="Kategori">
            <option value="">Semua kategori</option>
            <option value="none">Tanpa Kategori</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
          <select
            className="input"
            value={status}
            onChange={(e) => setStatus(e.target.value as typeof status)}
            aria-label="Status"
          >
            <option value="">Semua status</option>
            <option value="pending">Belum selesai</option>
            <option value="completed">Selesai</option>
          </select>
          <select
            className="input"
            value={timeMode}
            onChange={(e) => setTimeMode(e.target.value as TimeMode)}
            aria-label="Filter waktu"
          >
            <option value="all">Semua waktu</option>
            <option value="date">Per tanggal</option>
            <option value="month">Per bulan</option>
            <option value="year">Per tahun</option>
          </select>
          {timeMode === "date" && (
            <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} aria-label="Tanggal" />
          )}
          {timeMode === "month" && (
            <input type="month" className="input" value={month} onChange={(e) => setMonth(e.target.value)} aria-label="Bulan" />
          )}
          {timeMode === "year" && (
            <select className="input" value={year} onChange={(e) => setYear(Number(e.target.value))} aria-label="Tahun">
              {years.map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          )}
        </div>
        {hasFilter && (
          <button onClick={resetFilters} className="text-xs font-medium text-indigo-600 hover:underline">
            Reset filter
          </button>
        )}
      </section>

      {loading ? (
        <p className="py-6 text-center text-sm text-slate-500">Memuat…</p>
      ) : groups.length === 0 ? (
        <p className="card p-6 text-center text-sm text-slate-500">Tidak ada tugas yang cocok.</p>
      ) : (
        groups.map((g) => {
          const done = g.todos.filter((t) => t.is_completed).length;
          return (
            <section key={g.key} className="card overflow-hidden">
              <header className="flex items-center gap-2 border-b border-slate-100 bg-slate-50 px-4 py-2.5">
                <span className="h-2.5 w-2.5 rounded-full" style={{ background: g.color }} />
                <h2 className="flex-1 text-sm font-semibold">{g.name}</h2>
                <span className="text-xs text-slate-500">
                  {done}/{g.todos.length} selesai
                </span>
              </header>
              <ul className="divide-y divide-slate-100">
                {g.todos.map((t) => (
                  <TodoItem key={t.id} todo={t} onToggle={toggle} onDelete={remove} showCategory={false} />
                ))}
              </ul>
            </section>
          );
        })
      )}
    </div>
  );
}
