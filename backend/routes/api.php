<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\GoalController;
use App\Http\Controllers\PercentageController;

Route::get('/goals', [GoalController::class, 'index']);
Route::post('/goals', [GoalController::class, 'store']);
Route::delete('/goals/{id}', [GoalController::class, 'destroy']);

Route::get('/percentage', [PercentageController::class, 'index']);
Route::post('/percentage/{percentage}', [PercentageController::class, 'store']);
