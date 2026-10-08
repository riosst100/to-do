<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class CategoryController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $categories = $request->user()->categories()
            ->withCount(['todos', 'todos as pending_count' => fn ($q) => $q->where('is_completed', false)])
            ->orderBy('name')
            ->get();

        return CategoryResource::collection($categories);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => [
                'required', 'string', 'max:50',
                Rule::notIn([Category::UNCATEGORIZED_LABEL]),
                Rule::unique('categories')->where('user_id', $request->user()->id),
            ],
            'color' => ['nullable', 'regex:/^#[0-9a-fA-F]{6}$/'],
        ], [
            'name.unique' => 'Kategori dengan nama ini sudah ada.',
            'name.not_in' => 'Nama kategori ini sudah dipakai sistem.',
        ]);

        $category = $request->user()->categories()->create([
            'name' => $data['name'],
            'color' => $data['color'] ?? '#6366f1',
        ]);

        return (new CategoryResource($category))->response()->setStatusCode(201);
    }

    public function destroy(Request $request, Category $category): JsonResponse
    {
        abort_unless($category->user_id === $request->user()->id, 404);

        // Todo di kategori ini otomatis jadi "Tanpa Kategori" (nullOnDelete)
        $category->delete();

        return response()->json(['message' => 'Kategori dihapus.']);
    }
}
