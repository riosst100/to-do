/** Tanggal lokal (bukan UTC) dalam format YYYY-MM-DD. */
export function todayISO(): string {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export function formatDate(iso: string, opts: Intl.DateTimeFormatOptions = { day: "numeric", month: "short", year: "numeric" }) {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y, m - 1, d).toLocaleDateString("id-ID", opts);
}

export function formatLongDate(iso: string) {
  return formatDate(iso, { weekday: "long", day: "numeric", month: "long", year: "numeric" });
}
