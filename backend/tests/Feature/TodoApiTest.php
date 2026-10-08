<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TodoApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_login_and_logout(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Rio', 'email' => 'rio@example.com',
            'password' => 'password123', 'password_confirmation' => 'password123',
        ])->assertCreated()->assertJsonStructure(['user', 'token']);

        $this->postJson('/api/login', ['email' => 'rio@example.com', 'password' => 'salah'])
            ->assertUnprocessable();

        $token = $this->postJson('/api/login', ['email' => 'rio@example.com', 'password' => 'password123'])
            ->assertOk()->json('token');

        $this->withToken($token)->getJson('/api/me')->assertOk()->assertJsonPath('user.email', 'rio@example.com');
        $this->withToken($token)->postJson('/api/logout')->assertOk();
    }

    public function test_spa_login_uses_session_cookie_with_remember_me(): void
    {
        User::factory()->create(['email' => 'rio@example.com', 'password' => 'password123']);
        $this->withHeader('Origin', 'http://localhost:3000');

        $response = $this->postJson('/api/login', ['email' => 'rio@example.com', 'password' => 'password123'])
            ->assertOk()
            ->assertJsonMissingPath('token');

        $rememberCookie = collect($response->headers->getCookies())
            ->first(fn ($c) => str_starts_with($c->getName(), 'remember_web_'));
        $this->assertNotNull($rememberCookie, 'Cookie remember me harus diset');
        $this->assertTrue($rememberCookie->isHttpOnly());

        $this->getJson('/api/me')->assertOk()->assertJsonPath('user.email', 'rio@example.com');

        $this->postJson('/api/logout')->assertOk();
        $this->assertGuest('web');
    }

    public function test_guest_cannot_access_todos(): void
    {
        $this->getJson('/api/todos')->assertUnauthorized();
    }

    public function test_todo_defaults_to_uncategorized_and_becomes_uncategorized_when_category_deleted(): void
    {
        Sanctum::actingAs($user = User::factory()->create());

        $this->postJson('/api/todos', ['title' => 'A', 'due_date' => '2026-10-08'])
            ->assertCreated()
            ->assertJsonPath('data.category_id', null)
            ->assertJsonPath('data.category.name', 'Tanpa Kategori');

        $catId = $this->postJson('/api/categories', ['name' => 'Kerja'])->assertCreated()->json('data.id');
        $this->postJson('/api/categories', ['name' => 'Kerja'])->assertUnprocessable();

        $todoId = $this->postJson('/api/todos', ['title' => 'B', 'due_date' => '2026-10-08', 'category_id' => $catId])
            ->assertJsonPath('data.category.name', 'Kerja')->json('data.id');

        $this->deleteJson("/api/categories/{$catId}")->assertOk();
        $this->getJson("/api/todos/{$todoId}")->assertJsonPath('data.category_id', null);
    }

    public function test_toggle_and_delete(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $id = $this->postJson('/api/todos', ['title' => 'A', 'due_date' => '2026-10-08'])->json('data.id');

        $this->patchJson("/api/todos/{$id}/toggle")->assertJsonPath('data.is_completed', true);
        $this->patchJson("/api/todos/{$id}/toggle")->assertJsonPath('data.is_completed', false);
        $this->deleteJson("/api/todos/{$id}")->assertOk();
        $this->getJson("/api/todos/{$id}")->assertNotFound();
    }

    public function test_filters_and_today(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $cat = $this->postJson('/api/categories', ['name' => 'Rumah'])->json('data.id');

        $this->postJson('/api/todos', ['title' => 'Beli sayur', 'due_date' => '2026-10-08', 'category_id' => $cat]);
        $this->postJson('/api/todos', ['title' => 'Bayar listrik', 'due_date' => '2026-11-02']);
        $this->postJson('/api/todos', ['title' => 'Laporan', 'due_date' => '2025-10-08']);

        $this->getJson('/api/todos')->assertJsonCount(3, 'data');
        $this->getJson('/api/todos?search=bayar')->assertJsonCount(1, 'data');
        $this->getJson('/api/todos?date=2026-10-08')->assertJsonCount(1, 'data');
        $this->getJson('/api/todos?month=10')->assertJsonCount(2, 'data');
        $this->getJson('/api/todos?year=2026')->assertJsonCount(2, 'data');
        $this->getJson('/api/todos?month=10&year=2026')->assertJsonCount(1, 'data');
        $this->getJson("/api/todos?category_id={$cat}")->assertJsonCount(1, 'data');
        $this->getJson('/api/todos?category_id=none')->assertJsonCount(2, 'data');
        $this->getJson('/api/todos/today?date=2026-10-08')->assertJsonCount(1, 'data');
    }

    public function test_long_description_can_be_created_and_updated(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $long = trim(str_repeat("Baris panjang.\n", 600)); // ~9000 karakter, baris baru dipertahankan

        $id = $this->postJson('/api/todos', ['title' => 'A', 'due_date' => '2026-10-08', 'description' => $long])
            ->assertCreated()
            ->assertJsonPath('data.description', $long)
            ->json('data.id');

        $this->patchJson("/api/todos/{$id}", ['description' => 'Ringkas'])
            ->assertOk()
            ->assertJsonPath('data.description', 'Ringkas')
            ->assertJsonPath('data.title', 'A');

        $this->patchJson("/api/todos/{$id}", ['description' => null])->assertJsonPath('data.description', null);

        $this->patchJson("/api/todos/{$id}", ['description' => str_repeat('x', 10001)])->assertUnprocessable();
    }

    public function test_user_cannot_touch_other_users_data(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $id = $this->postJson('/api/todos', ['title' => 'Rahasia', 'due_date' => '2026-10-08'])->json('data.id');
        $cat = $this->postJson('/api/categories', ['name' => 'Privat'])->json('data.id');

        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/todos')->assertJsonCount(0, 'data');
        $this->deleteJson("/api/todos/{$id}")->assertNotFound();
        $this->deleteJson("/api/categories/{$cat}")->assertNotFound();
        $this->postJson('/api/todos', ['title' => 'X', 'due_date' => '2026-10-08', 'category_id' => $cat])
            ->assertUnprocessable();
    }
}
