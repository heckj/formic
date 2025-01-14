# ``Command``

## Overview

Conform to the Command protocol to provide the logic for the Formic engine to invoke a command effecting a remote host or service.

The engine calls ``run(host:logger:)`` to invoke the command, providing a `Host` instance that presents the host to the logic for executing the command.
The engine may provide a [`Logger`](https://swiftpackageindex.com/apple/swift-log/documentation/logging/logger) instance, to allow the command to log messages, typically to the console when invoked from a command-line interface.
Log output at `debug` or `trace` log levels within your command. 
Throw errors to indicate unavoidable error conditions, and report failure conditions by including the relevant information into ``CommandOutput`` that you return from this method.  


## Topics

### Inspecting Commands

- ``Command/id``
- ``Command/ignoreFailure``
- ``Command/retry``
- ``Command/executionTimeout``
- ``Backoff``

### Invoking Commands

- ``Command/run(host:logger:)``
