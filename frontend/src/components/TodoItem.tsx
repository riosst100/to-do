"use client";

import type { Todo } from "@/lib/api";
import { formatDate } from "@/lib/date";

type Props = {
  todo: Todo;
  onToggle: (todo: Todo) => void;
  onDelete: (todo: Todo) => void;
  showDate?: boolean;
  showCategory?: boolean;
};

export function TodoItem({ todo, onToggle, onDelete, showDate = true, showCategory = true }: Props) {
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
        {todo.description && <p className="mt-0.5 text-xs text-slate-500">{todo.description}</p>}
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
      <button
        onClick={() => onDelete(todo)}
        className="rounded-md px-2 py-1 text-xs text-slate-400 opacity-100 transition hover:bg-red-50 hover:text-red-600 sm:opacity-0 sm:group-hover:opacity-100"
        aria-label={`Hapus "${todo.title}"`}
      >
        Hapus
      </button>
    </li>
  );
}
