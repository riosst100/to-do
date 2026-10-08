# Todo App

Monorepo berisi:

- `backend/` — REST API **Laravel 13** + **Sanctum** (token auth, siap dipakai web & mobile)
- `frontend/` — Web **Next.js 16** (App Router, Tailwind v4)

## Fitur

- Register / login / logout user (belum ada admin)
- Tambah & hapus kategori (dengan warna). Kategori bawaan: **Tanpa Kategori** (`category_id = null`)
- Tambah & hapus tugas, wajib tanggal; kategori opsional → default *Tanpa Kategori*
- Ceklis untuk menyelesaikan tugas (toggle)
- Beranda: daftar tugas hari ini + progres
- Menu Tugas: dikelompokkan per kategori, pencarian, filter kategori, status, tanggal / bulan / tahun
- Menghapus kategori **tidak** menghapus tugasnya — tugas pindah ke *Tanpa Kategori*

## Menjalankan dengan Docker (disarankan, WSL)

```bash
cp .env.example .env         # atur port / UID kalau perlu
docker compose up -d --build
```

| Service | URL |
|---|---|
| Web (Next.js, hot reload) | http://localhost:3020 |
| API (Laravel) | http://localhost:8020/api |
| PostgreSQL 17 | `127.0.0.1:5442` (user/db `todo`, password `secret`) |

Saat start, container backend otomatis `composer install` (bila belum), `key:generate`, dan `migrate`.
Source code di-mount, jadi edit di WSL langsung terlihat. Port default sengaja tidak memakai 3000/8000/5432
karena sudah dipakai project lain.

Perintah berguna:

```bash
docker compose logs -f backend frontend
docker compose exec backend php artisan test
docker compose exec backend php artisan migrate:fresh
docker compose exec frontend npm install <paket>
docker compose down          # tambah -v untuk menghapus data Postgres
```

Untuk testing dari HP/emulator (versi mobile), set `BACKEND_BIND=0.0.0.0` di `.env`, lalu akses API lewat IP
komputer (emulator Android: `http://10.0.2.2:8020/api`). Di WSL2 mungkin perlu port forwarding / mirrored networking.

## Menjalankan tanpa Docker

### Backend

```bash
cd backend
composer install
cp .env.example .env        # sudah ada jika dari scaffold ini
php artisan key:generate
php artisan migrate         # default SQLite (database/database.sqlite)
php artisan serve           # http://localhost:8000
php artisan test            # feature test API
```

Env penting: `APP_TIMEZONE` (default `Asia/Jakarta`), `CORS_ALLOWED_ORIGINS` (pisahkan dengan koma).
Untuk MySQL/PostgreSQL cukup ganti `DB_*` di `.env`.

### Frontend

```bash
cd frontend
npm install
cp .env.example .env.local  # NEXT_PUBLIC_API_URL=http://localhost:8000/api
npm run dev                 # http://localhost:3000
```

## API (untuk web & mobile)

Base URL: `/api`. Selalu kirim `Accept: application/json`.
Endpoint selain register/login butuh header `Authorization: Bearer <token>`.

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/register` | `name, email, password, password_confirmation, device_name?` → `{ user, token }` |
| POST | `/login` | `email, password, device_name?` → `{ user, token }` |
| GET | `/me` | user aktif |
| POST | `/logout` | cabut token saat ini |
| GET | `/categories` | daftar kategori + `todos_count`, `pending_count` |
| POST | `/categories` | `name, color?` (`#RRGGBB`) |
| DELETE | `/categories/{id}` | tugas di dalamnya → Tanpa Kategori |
| GET | `/todos` | filter query: `search`, `category_id` (id atau `none`), `date` (Y-m-d), `month` (1-12), `year`, `status` (`pending`/`completed`) |
| GET | `/todos/today?date=Y-m-d` | tugas pada tanggal tsb (kirim tanggal lokal device; default tanggal server) |
| POST | `/todos` | `title, due_date (Y-m-d), description?, category_id?` |
| GET | `/todos/{id}` | detail |
| PUT/PATCH | `/todos/{id}` | ubah sebagian field |
| PATCH | `/todos/{id}/toggle` | tandai selesai / belum |
| DELETE | `/todos/{id}` | hapus |

Bentuk objek todo:

```json
{
  "id": 1,
  "title": "Kirim laporan",
  "description": null,
  "due_date": "2026-10-08",
  "is_completed": false,
  "completed_at": null,
  "category_id": null,
  "category": { "id": null, "name": "Tanpa Kategori", "color": "#9ca3af" }
}
```

Error validasi → HTTP 422 `{ message, errors: { field: [..] } }`; token tidak valid → 401.

Untuk mobile, simpan token di secure storage dan kirim `device_name` (mis. `"android"`) saat login agar token per perangkat bisa dicabut terpisah.
