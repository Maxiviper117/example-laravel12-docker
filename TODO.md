# TODO: Laravel Horizon with Docker Base Image and Mounted App

This checklist will help you solve the problem of running Laravel Horizon in a Docker setup where the app code is **not copied** into the image, but is **mounted** at runtime.

## Problem Statement
- You want to use Laravel Horizon for queue management.
- Your Docker base image does **not** include the Laravel app source code.
- The app is mounted into the container at runtime (e.g. via `-v ./app:/var/www/html`).
- Composer dependencies (including Horizon) are not installed in the image by default.

## Tasks

```markdown
- [ ] Research best practices for running Laravel Horizon when the app is mounted, not copied, in Docker.
- [ ] Decide where and how to install Composer dependencies (host, entrypoint, or one-off container).
- [ ] Ensure `laravel/horizon` is present in `composer.json` and installed in `vendor` before starting Horizon.
- [ ] Determine if Composer install should run in the entrypoint (with bind mounts) or be a manual/host step.
- [ ] Document the workflow for updating dependencies (host vs. container, permissions, etc.).
- [ ] Ensure the `horizon` command is available in the container after mounting the app.
- [ ] Test Horizon startup and queue processing in this setup.
- [ ] Document any caveats or gotchas (e.g. Windows permissions, symlinks, race conditions).
```

## Notes
- Installing Composer dependencies in the entrypoint is possible, but has tradeoffs (startup time, race conditions, permissions).
- Installing dependencies on the host is more reliable, but may have cross-OS issues.
- The `horizon` command must be available in the container for Supervisor or entrypoint scripts to work.
- **Important:** If you are mounting your app from a Windows environment, it is not possible to build PECL extensions (required by some PHP packages) at runtime inside the container, because PECL is only supported on Unix-like filesystems. This can break Horizon or other PHP extensions that require PECL builds.
- Document your chosen approach for your team.
