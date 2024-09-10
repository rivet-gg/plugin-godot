use lazy_static::lazy_static;
use std::future::Future;

lazy_static! {
    /// Shared runtime for executing tasks.
    ///
    /// Multithreaded is required in order to be able to use blocking threads. We reduce the worker
    /// thread count to reduce footprint.
    ///
    /// Sharing the runtime instead of creating an independent runtiem for each task reduces memory
    /// footprint.
    static ref RUNTIME: tokio::runtime::Runtime = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .unwrap();
}

/// Runs a future on the shared runtime.
pub fn block_on<Output>(fut: impl Future<Output = Output>) -> Output {
    RUNTIME.block_on(fut)
}
