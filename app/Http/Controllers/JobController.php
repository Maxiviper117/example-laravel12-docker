<?php

namespace App\Http\Controllers;

use App\Jobs\ExampleJob;
use Illuminate\Http\Request;

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
}
