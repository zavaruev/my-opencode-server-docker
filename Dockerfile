# Minimal Dockerfile for OpenCode Server
# Uses the pre-built anomalyco image as base, just sets up the environment
# Auto-build via GitHub Actions is optional (currently has npm 10 compatibility issues)

FROM ghcr.io/anomalyco/opencode:2.2.6 AS builder

# Just mark as built - the actual image is anomalyco/opencode:2.2.6
# This Dockerfile is mainly for version tracking

# Metadata
LABEL org.open-code.version="2.2.6"
LABEL org.open-code.maintainer="zavaruev"

# The image is ready to use - just run it
# Entrypoint is already set in the base image