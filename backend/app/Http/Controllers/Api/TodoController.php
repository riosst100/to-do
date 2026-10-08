<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TodoResource;
use App\Models\Todo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class TodoController extends Controller
{
    /**
     * Query params: search, category_id (id | "none"), date (Y-m-d), month (1-12), year, status (pending|completed).
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'category_id' => ['nullable', 'string'],
            'date' => ['nullable', 'date_format:Y-m-d'],
            'month' => ['nullable', 'integer', 'between:1,12'],
            'year' => ['nullable', 'integer', 'between:1970,2100'],
            'status' => ['nullable', Rule::in(['pending', 'completed'])],
        ]);

        $todos = $request->user()->todos()
            ->with('category')
            ->filter($filters)
            ->orderBy('is_completed')
            ->orderBy('due_date')
            ->latest('id')
            ->get();

        return TodoResource::collection($todos);
    }

    /** Tugas hari ini (berdasarkan tanggal dari client, default tanggal server). */
    public function today(Request $request): AnonymousResourceCollection
    {
        $request->validate(['date' => ['nullable', 'date_format:Y-m-d']]);
        $date = $request->input('date', now()->toDateString());

        $todos = $request->user()->todos()
            ->with('category')
            ->whereDate('due_date', $date)
            ->orderBy('is_completed')
            ->latest('id')
            ->get();

        return TodoResource::collection($todos);
    }

    public function store(Request $request): JsonResponse
    {
        $todo = $request->user()->todos()->create($this->validated($request));

        return (new TodoResource($todo->load('category')))->response()->setStatusCode(201);
    }

    public function show(Request $request, Todo $todo): TodoResource
    {
        $this->authorizeOwner($request, $todo);

        return new TodoResource($todo->load('category'));
    }

    public function update(Request $request, Todo $todo): TodoResource
    {
        $this->authorizeOwner($request, $todo);

        $todo->update($this->validated($request, partial: true));

        return new TodoResource($todo->load('category'));
    }

    public function toggle(Request $request, Todo $todo): TodoResource
    {
        $this->authorizeOwner($request, $todo);

        $todo->update([
            'is_completed' => ! $todo->is_completed,
            'completed_at' => $todo->is_completed ? null : now(),
        ]);

        return new TodoResource($todo->load('category'));
    }

    public function destroy(Request $request, Todo $todo): JsonResponse
    {
        $this->authorizeOwner($request, $todo);

        $todo->delete();

        return response()->json(['message' => 'Tugas dihapus.']);
    }

    private function validated(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'title' => [$required, 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:'.Todo::DESCRIPTION_MAX],
            'due_date' => [$required, 'date_format:Y-m-d'],
            // null / kosong = Tanpa Kategori
            'category_id' => [
                'nullable',
                Rule::exists('categories', 'id')->where('user_id', $request->user()->id),
            ],
        ]);
    }

    private function authorizeOwner(Request $request, Todo $todo): void
    {
        abort_unless($todo->user_id === $request->user()->id, 404);
    }
}
