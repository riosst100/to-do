<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['category_id', 'title', 'description', 'due_date', 'is_completed', 'completed_at'])]
class Todo extends Model
{
    /** Panjang maksimum deskripsi (karakter). */
    public const DESCRIPTION_MAX = 10000;

    protected function casts(): array
    {
        return [
            'due_date' => 'date:Y-m-d',
            'is_completed' => 'boolean',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Filter: search, category_id ("none" = Tanpa Kategori), date, month, year, status.
     */
    public function scopeFilter(Builder $query, array $filters): Builder
    {
        return $query
            ->when($filters['search'] ?? null, fn (Builder $q, $search) => $q->where(
                fn (Builder $q) => $q->whereLike('title', "%{$search}%")
                    ->orWhereLike('description', "%{$search}%")
            ))
            ->when($filters['category_id'] ?? null, fn (Builder $q, $categoryId) => $categoryId === 'none'
                ? $q->whereNull('category_id')
                : $q->where('category_id', $categoryId))
            ->when($filters['date'] ?? null, fn (Builder $q, $date) => $q->whereDate('due_date', $date))
            ->when($filters['month'] ?? null, fn (Builder $q, $month) => $q->whereMonth('due_date', $month))
            ->when($filters['year'] ?? null, fn (Builder $q, $year) => $q->whereYear('due_date', $year))
            ->when(isset($filters['status']), fn (Builder $q) => match ($filters['status']) {
                'completed' => $q->where('is_completed', true),
                'pending' => $q->where('is_completed', false),
                default => $q,
            });
    }
}
