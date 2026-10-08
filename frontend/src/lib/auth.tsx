"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { api, type User } from "./api";

type AuthState = {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string, passwordConfirmation: string) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Bersihkan token lama dari versi sebelumnya (sekarang pakai cookie session)
    try {
      localStorage.removeItem("todo_token");
    } catch {}

    // Session cookie dikirim otomatis; 401 berarti belum login
    api
      .me()
      .then((r) => setUser(r.user))
      .catch(() => setUser(null))
      .finally(() => setLoading(false));

    const onUnauthorized = () => setUser(null);
    window.addEventListener("auth:unauthorized", onUnauthorized);
    return () => window.removeEventListener("auth:unauthorized", onUnauthorized);
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const r = await api.login({ email, password, remember: true });
    setUser(r.user);
  }, []);

  const register = useCallback(
    async (name: string, email: string, password: string, password_confirmation: string) => {
      const r = await api.register({ name, email, password, password_confirmation });
      setUser(r.user);
    },
    [],
  );

  const logout = useCallback(async () => {
    await api.logout().catch(() => {});
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>{children}</AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth harus di dalam AuthProvider");
  return ctx;
}
