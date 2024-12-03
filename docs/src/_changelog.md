```@meta
CurrentModule = DistributedNext
```

# Changelog

This documents notable changes in DistributedNext.jl. The format is based on
[Keep a Changelog](https://keepachangelog.com).

## [v1.0.0] - 2024-12-02

### Added
- A watcher mechanism has been added to detect when both the Distributed stdlib
  and DistributedNext may be active and adding workers. This should help prevent
  incompatibilities from both libraries being used simultaneously ([#10]).

### Fixed
- Fixed behaviour of `isempty(::RemoteChannel)`, which previously had the
  side-effect of taking an element from the channel ([#3]).
- Improved thread-safety, such that it should be safe to start workers with
  multiple threads and send messages between them ([#4]).

### Changed
- Added a `project` argument to [`addprocs(::AbstractVector)`](@ref) to specify
  the project of a remote worker ([#2]).
- Workers will now attempt to pick the fastest available interface to
  communicate over ([#9]).
- The `SSHManager` now passes all `JULIA_*` environment variables by default to
  the workers, instead of only `JULIA_WORKER_TIMEOUT` ([#9]).
