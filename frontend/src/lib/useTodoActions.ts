"use client";

import { useCallback } from "react";
import { api, type Todo, type TodoInput } from "./api";

/** Toggle, edit & hapus todo dengan update optimistis pada list lokal. */
export function useTodoActions(setTodos: React.Dispatch<React.SetStateAction<Todo[]>>, reload: () => void) {
  const toggle = useCallback(
    async (todo: Todo) => {
      setTodos((list) => list.map((t) => (t.id === todo.id ? { ...t, is_completed: !t.is_completed } : t)));
      try {
        const updated = await api.toggleTodo(todo.id);
        setTodos((list) => list.map((t) => (t.id === todo.id ? updated : t)));
      } catch {
        reload();
      }
    },
    [setTodos, reload],
  );

  const remove = useCallback(
    async (todo: Todo) => {
      if (!confirm(`Hapus tugas "${todo.title}"?`)) return;
      setTodos((list) => list.filter((t) => t.id !== todo.id));
      try {
        await api.deleteTodo(todo.id);
      } catch {
        reload();
      }
    },
    [setTodos, reload],
  );

  /** Melempar error agar pemanggil (mis. editor deskripsi) bisa menampilkan pesan. */
  const update = useCallback(
    async (todo: Todo, data: Partial<TodoInput>) => {
      const updated = await api.updateTodo(todo.id, data);
      setTodos((list) => list.map((t) => (t.id === todo.id ? updated : t)));
    },
    [setTodos],
  );

  return { toggle, remove, update };
}
