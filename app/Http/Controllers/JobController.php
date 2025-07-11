<?php

namespace App\Http\Controllers;

use App\Jobs\ExampleJob;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class JobController extends Controller
{
    /**
     * Dispatch an example job.
     *
     * @return \Illuminate\Http\RedirectResponse
     */
    public function dispatchExampleJob()
    {
        // Dispatch the job
        ExampleJob::dispatch();

        // Redirect back with a success message
        return redirect()->back()->with('status', 'Example job has been dispatched!');
    }

    /**
     * Dispatch a job, wait 5s, check status, and return as JSON
     */
    public function dispatchAndCheckStatus(Request $request)
    {
        // Create a unique identifier for this job
        $uuid = (string) Str::uuid();

        // Dispatch the job with the UUID
        ExampleJob::dispatch()->onQueue('default');

        // resopinse with json success message
        return response()->json([
            'status' => 'Job dispatched successfully',
            'message' => 'You can check the job status later using the job ID.'
        ], 200);
    }
}
