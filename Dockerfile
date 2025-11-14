# Use the latest Julia 1.x image by default. Override at build time with --build-arg JULIA_VERSION=1.11
ARG JULIA_VERSION=1
FROM julia:${JULIA_VERSION}

# Optional: metadata
LABEL org.opencontainers.image.source="https://github.com/shriram/lab-assign" \
      org.opencontainers.image.description="Lab assignment solver environment with JuMP + HiGHS + CSV + DataFrames preinstalled" \
      org.opencontainers.image.licenses="MIT"

# We'll mount your repo into /files when you run the container
WORKDIR /files

# Create an isolated Julia environment and preinstall packages so runtime is fast
ENV JULIA_PROJECT=/opt/julia_env

# Preinstall packages used by this repo. Print a status at the end for visibility.
# Note: Printf is a stdlib and does not need to be added.
RUN julia --color=yes -e "using Pkg; \
    Pkg.activate(ENV[\"JULIA_PROJECT\"]); \
    Pkg.add([\"JuMP\", \"HiGHS\", \"CSV\", \"DataFrames\"]); \
    Pkg.precompile(); \
    println(\"\nPackages installed in JULIA_PROJECT=\", ENV[\"JULIA_PROJECT\"]); \
    Pkg.status()"

# Default to a quiet Julia REPL; you'll typically mount your project and run include("/files/assign.jl")
CMD ["julia", "-q"]
