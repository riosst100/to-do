"use client";

import { useCallback, useEffect, useState } from "react";
import { TodoForm } from "@/components/TodoForm";
import { TodoItem } from "@/components/TodoItem";
import { api, type Category, type Todo, type TodoInput } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { formatLongDate } from "@/lib/date";
import { useToday } from "@/lib/useToday";
import { useTodoActions } from "@/lib/useTodoActions";

export default function HomePage() {
  const { user } = useAuth();
  const today = useToday();
  const [todos, setTodos] = useState<Todo[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(() => {
    if (!today) return;
    Promise.all([api.todayTodos(today), api.categories()])
      .then(([t, c]) => {
        setTodos(t);
        setCategories(c);
      })
      .finally(() => setLoading(false));
  }, [today]);

  const userId = user?.id;
  useEffect(() => {
    if (userId) load();
  }, [userId, load]);

  const { toggle, remove } = useTodoActions(setTodos, load);

  async function handleCreate(data: TodoInput) {
    const todo = await api.createTodo(data);
    if (todo.due_date === today) setTodos((list) => [todo, ...list]);
  }

  const done = todos.filter((t) => t.is_completed).length;
  const progress = todos.length ? Math.round((done / todos.length) * 100) : 0;

  return (
    <div className="space-y-6">
      <section>
        <p className="h-5 text-sm text-slate-500">{today && formatLongDate(today)}</p>
        <h1 className="text-2xl font-semibold">Halo{user ? `, ${user.name.split(" ")[0]}` : ""} 👋</h1>
      </section>

      <section className="card p-4">
        <div className="flex items-baseline justify-between">
          <h2 className="font-medium">Tugas hari ini</h2>
          <span className="text-sm text-slate-500">
            {done}/{todos.length} selesai
          </span>
        </div>
        <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-100">
          <div className="h-full rounded-full bg-indigo-600 transition-all" style={{ width: `${progress}%` }} />
        </div>
      </section>

      <TodoForm categories={categories} onSubmit={handleCreate} />

      <section className="card overflow-hidden">
        {loading ? (
          <p className="p-6 text-center text-sm text-slate-500">Memuat…</p>
        ) : todos.length === 0 ? (
          <p className="p-6 text-center text-sm text-slate-500">Tidak ada tugas untuk hari ini. 🎉</p>
        ) : (
          <ul className="divide-y divide-slate-100">
            {todos.map((t) => (
              <TodoItem key={t.id} todo={t} onToggle={toggle} onDelete={remove} showDate={false} />
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
