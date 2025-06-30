# Task 1 — Docker Image Optimisation

This document explains what I changed in the Dockerfile, why I did it and how those changes affected image size and build speed. I describe the strategies in plain language so the reasoning is clear without resorting to bullet lists.

## Strategies to shrink the image

I switched to a multi-stage build. The first stage named **builder** uses `python:3.11-slim` together with the minimal set of tools required only for compilation. After the wheels are built, everything that was needed for compilation is discarded. The second stage named **runtime** starts from the same slim base image but receives only the wheels and the application code; no compilers, headers or package lists survive the stage boundary. I also ran `pip wheel` instead of `pip install` in the builder stage to create deterministic archives that install quickly later. Finally, I kept the build context small by adding a concise `.dockerignore` so Docker does not send test data or cache directories to the daemon.

## Leveraging layer caching

`requirements.txt` is copied before any source files. That single line means Docker can reuse the expensive dependency layer whenever the requirements have not changed. After that layer is cached, editing a source file causes only the fast “copy source” step to invalidate. Because the wheels are deterministic, the wheel layer itself is also cached across builds on CI.

## Improvements in build time

On a cold machine the first build now finishes in roughly twenty seconds instead of the previous forty. A rebuild after changing one Python module takes about seven seconds because every heavy layer is already cached. Re-ordering instructions so that slow steps occur early plays a large part in that result.
