export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api";

const TOKEN_KEY = "todo_token";

export type User = { id: number; name: string; email: string };

export type Category = {
  id: number;
  name: string;
  color: string;
  todos_count?: number;
  pending_count?: number;
};

export type Todo = {
  id: number;
  title: string;
  description: string | null;
  due_date: string; // YYYY-MM-DD
  is_completed: boolean;
  completed_at: string | null;
  category_id: number | null;
  category: { id: number | null; name: string; color: string };
};

export type TodoInput = {
  title: string;
  description?: string | null;
  due_date: string;
  category_id: number | null;
};

export type TodoFilters = {
  search?: string;
  category_id?: string; // id atau "none"
  date?: string;
  month?: number;
  year?: number;
  status?: "pending" | "completed";
};

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public errors: Record<string, string[]> = {},
  ) {
    super(message);
  }
}

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string | null) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
  });

  const body = res.status === 204 ? null : await res.json().catch(() => null);

  if (!res.ok) {
    if (res.status === 401) {
      setToken(null);
      window.dispatchEvent(new Event("auth:unauthorized"));
    }
    throw new ApiError(body?.message ?? "Terjadi kesalahan.", res.status, body?.errors ?? {});
  }
  return body as T;
}

function query(params: Record<string, string | number | undefined>) {
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== "") qs.set(k, String(v));
  }
  const s = qs.toString();
  return s ? `?${s}` : "";
}

export const api = {
  register: (data: { name: string; email: string; password: string; password_confirmation: string }) =>
    request<{ user: User; token: string }>("/register", { method: "POST", body: JSON.stringify(data) }),
  login: (data: { email: string; password: string }) =>
    request<{ user: User; token: string }>("/login", { method: "POST", body: JSON.stringify(data) }),
  me: () => request<{ user: User }>("/me"),
  logout: () => request("/logout", { method: "POST" }),

  categories: () => request<{ data: Category[] }>("/categories").then((r) => r.data),
  createCategory: (data: { name: string; color: string }) =>
    request<{ data: Category }>("/categories", { method: "POST", body: JSON.stringify(data) }).then((r) => r.data),
  deleteCategory: (id: number) => request(`/categories/${id}`, { method: "DELETE" }),

  todos: (filters: TodoFilters = {}) =>
    request<{ data: Todo[] }>(`/todos${query(filters)}`).then((r) => r.data),
  todayTodos: (date: string) => request<{ data: Todo[] }>(`/todos/today${query({ date })}`).then((r) => r.data),
  createTodo: (data: TodoInput) =>
    request<{ data: Todo }>("/todos", { method: "POST", body: JSON.stringify(data) }).then((r) => r.data),
  toggleTodo: (id: number) =>
    request<{ data: Todo }>(`/todos/${id}/toggle`, { method: "PATCH" }).then((r) => r.data),
  deleteTodo: (id: number) => request(`/todos/${id}`, { method: "DELETE" }),
};
