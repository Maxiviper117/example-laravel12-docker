<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\JobController;

// Route to dispatch a job, wait 5s, then check status and return as JSON
Route::post('/job-with-status1', [JobController::class, 'dispatchAndCheckStatus'])->name('job.dispatchAndCheckStatus');
