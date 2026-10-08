"use client";

import { useSyncExternalStore } from "react";
import { todayISO } from "./date";

const subscribe = () => () => {};

/**
 * Tanggal lokal hari ini (YYYY-MM-DD), atau null saat prerender/hydration.
 * Waktu tidak boleh dibaca saat render di server: hasilnya akan "terkunci" di static shell.
 */
export function useToday(): string | null {
  return useSyncExternalStore(subscribe, todayISO, () => null);
}
