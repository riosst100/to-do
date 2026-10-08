<?php

namespace App\Http\Resources;

use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TodoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'due_date' => $this->due_date?->format('Y-m-d'),
            'is_completed' => $this->is_completed,
            'completed_at' => $this->completed_at,
            'category_id' => $this->category_id,
            'category' => $this->category
                ? ['id' => $this->category->id, 'name' => $this->category->name, 'color' => $this->category->color]
                : ['id' => null, 'name' => Category::UNCATEGORIZED_LABEL, 'color' => '#9ca3af'],
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
