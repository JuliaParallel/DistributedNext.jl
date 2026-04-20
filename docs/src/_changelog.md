```@meta
CurrentModule = DistributedNext
```

# Changelog

This documents notable changes in DistributedNext.jl. The format is based on
[Keep a Changelog](https://keepachangelog.com).

## [v1.3.1] - 2026-04-20

### Changed
- Fixed an incorrect assumption in `start_worker` that the loopback `bind_addr`
  would be IPv4, which is untrue on macOS. This fixes silent hangs during
  precompile on macOS, and also ensures `start_worker` errors are properly
  reported ([#68]).

## [v1.3.0] - 2026-04-06

### Changed
- The internals were completely refactored to move all global variables into a
  single struct ([#61]). This should not be a user-visible change, but of course
  it's possible that some things slipped through the cracks so please open an
  issue if you encounter any bugs.
- A precompilation workload was added to improve TTFX ([#62]).

## [v1.2.0] - 2026-03-21

### Added
- Implemented callback support for workers being added/removed etc ([#17]).
- Added a package extension to support Revise.jl ([#17]).
- Added support for setting worker statuses with [`setstatus`](@ref) and
  [`getstatus`](@ref) ([#17]).

### Fixed
- Modified the default implementations of methods like `take!` and `wait` on
  [`AbstractWorkerPool`](@ref) to be threadsafe and behave more consistently
  with each other ([#21]). This is technically breaking, but it's a strict
  bugfix to correct previous inconsistent behaviour so it will still land in a
  minor release.

## [v1.1.1] - 2026-03-09

### Fixed
- Backported various fixes from Distributed ([#25]).
- Fixed a lingering task that could cause hangs when exiting Distributed ([#51]).

## [v1.1.0] - 2025-08-02

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
