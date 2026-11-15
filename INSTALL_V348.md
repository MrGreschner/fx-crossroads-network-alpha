# Crossroads V348 full server project

Extract outside your GitHub checkout. Copy the extracted project files directly into the repository root, with Dockerfile.network and project.godot side by side, or use them to start a fresh checkout. Keep ZIPs and standalone PCKs outside GitHub. This deployment uses the individual project files and imports them in Docker.

In Render, use a Docker web service with Dockerfile Path ./Dockerfile.network and health check /health. Preserve your existing environment variables and database. After deployment, check that /health reports build V348 and ready true.
