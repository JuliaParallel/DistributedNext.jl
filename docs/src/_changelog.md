```@meta
CurrentModule = DistributedNext
```

# Changelog

This documents notable changes in DistributedNext.jl. The format is based on
[Keep a Changelog](https://keepachangelog.com).

## Unreleased

### Fixed
- Fixed a cause of potential hangs when exiting the process ([#16]).
- Fixed a subtle bug in `remotecall(f, ::AbstractWorkerPool)`, previously the
  implementation would take a worker out of the pool and immediately put it back
  in without waiting for the returned [`Future`](@ref). Now it will wait for the
  `Future` before putting the worker back in the pool ([#20]).
- Fixed cases like `addprocs([("machine 10.1.1.1:9000", 2)])` where the bind
  port is specified. Previously this would cause errors when the workers all
  tried to bind to the same port, now all additional workers will treat the bind
  port as a port hint ([#19]).
- Fixed a bug in the network interface selection code that would cause it to
  error when only a subset of interfaces reported the negotiation speed
  ([#29]).

### Added
- A watcher mechanism has been added to detect when both the Distributed stdlib
  and DistributedNext may be active and adding workers. This should help prevent
  incompatibilities from both libraries being used simultaneously ([#10]).
- [`other_workers()`](@ref) and [`other_procs()`](@ref) were implemented and
  exported ([#18]).
- The `SSHManager` now supports specifying a bind port hint in the machine
  specification ([#19], see the [`addprocs()`](@ref) docs).

### Changed
- [`remotecall_eval`](@ref) is now exported ([#23]).

## [v1.0.0] - 2024-12-02

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
