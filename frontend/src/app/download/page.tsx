import type { Metadata } from "next";
import Link from "next/link";
import { stat } from "node:fs/promises";
import path from "node:path";

export const metadata: Metadata = {
  title: "Unduh Aplikasi Android — Todo App",
  description: "Unduh aplikasi Todo untuk Android (APK).",
};

// File di public/downloads; ganti file ini & APP_VERSION (dari mobile/pubspec.yaml) saat merilis versi baru
const APK_URL = "/downloads/todo-app.apk";
const APP_VERSION = "1.0.0";

async function apkSize(): Promise<string | null> {
  // File hanya berubah saat deploy (build ulang), jadi aman di-cache saat prerender
  "use cache";
  try {
    const { size } = await stat(path.join(process.cwd(), "public", APK_URL));
    return `${(size / 1024 / 1024).toLocaleString("id-ID", { maximumFractionDigits: 1 })} MB`;
  } catch {
    return null;
  }
}

const STEPS = [
  "Ketuk tombol Unduh APK di bawah dari HP Android.",
  "Buka file todo-app.apk setelah unduhan selesai.",
  "Jika diminta, izinkan browser/file manager untuk “Instal aplikasi tak dikenal”.",
  "Ketuk Instal, lalu buka aplikasi Todo dan masuk dengan akun yang sama seperti di web.",
];

export default async function DownloadPage() {
  const size = await apkSize();

  return (
    <main className="flex flex-1 items-center justify-center px-4 py-12">
      <div className="card w-full max-w-md p-6">
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-indigo-600 text-2xl font-bold text-white">
            ✓
          </div>
          <h1 className="text-xl font-semibold">Todo untuk Android</h1>
          <p className="mt-1 text-sm text-slate-500">
            Kelola tugas harian dari HP — data tersinkron dengan versi web.
          </p>
        </div>

        <a href={APK_URL} download className="btn-primary w-full py-3 text-base">
          Unduh APK
        </a>
        <p className="mt-2 text-center text-xs text-slate-500">
          Versi {APP_VERSION}
          {size && ` · ${size}`} · Android 7.0 ke atas
        </p>

        <h2 className="mt-8 text-sm font-semibold">Cara memasang</h2>
        <ol className="mt-2 list-decimal space-y-1.5 pl-5 text-sm text-slate-600">
          {STEPS.map((s) => (
            <li key={s}>{s}</li>
          ))}
        </ol>

        <p className="mt-8 text-center text-sm text-slate-500">
          <Link href="/" className="font-medium text-indigo-600 hover:underline">
            Buka versi web
          </Link>
        </p>
      </div>
    </main>
  );
}
