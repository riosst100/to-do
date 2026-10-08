<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::create($data);

        return $this->authenticated($request, $user, $data['device_name'] ?? null, 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
            'remember' => ['nullable', 'boolean'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        return $this->authenticated($request, $user, $data['device_name'] ?? null, remember: $request->boolean('remember', true));
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()]);
    }

    public function logout(Request $request): JsonResponse
    {
        if ($request->hasSession()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();
        } else {
            $request->user()->currentAccessToken()->delete();
        }

        return response()->json(['message' => 'Berhasil logout.']);
    }

    /**
     * SPA (domain stateful) → login via session cookie + cookie "remember me" agar tidak perlu login ulang.
     * Klien lain (mis. mobile) → bearer token.
     */
    private function authenticated(Request $request, User $user, ?string $deviceName, int $status = 200, bool $remember = true): JsonResponse
    {
        if ($request->hasSession()) {
            Auth::guard('web')->login($user, $remember);
            $request->session()->regenerate();

            return response()->json(['user' => $user], $status);
        }

        return response()->json([
            'user' => $user,
            'token' => $user->createToken($deviceName ?? 'web')->plainTextToken,
        ], $status);
    }
}
