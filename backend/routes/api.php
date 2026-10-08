<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\TodoController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::apiResource('categories', CategoryController::class)->only(['index', 'store', 'destroy']);

    Route::get('/todos/today', [TodoController::class, 'today']);
    Route::patch('/todos/{todo}/toggle', [TodoController::class, 'toggle']);
    Route::apiResource('todos', TodoController::class);
});
