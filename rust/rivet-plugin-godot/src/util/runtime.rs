use std::future::Future;
use tokio::time::Duration;

pub struct BlockOnOpts {}

/**
* Create a temporary Tokio runtime to run the given future.
*/
pub fn block_on<Output>(fut: impl Future<Output = Output>, _opts: BlockOnOpts) -> Output {
    // Build temporary runtime
    //
    // Multithreaded is required in order to be able to use blocking threads. We reduce the worker
    // thread count to reduce footprint.
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .unwrap();

    // Run future
    let output = rt.block_on(fut);

    // Give tasks time to shut down
    // rt.shutdown_background();
    rt.shutdown_timeout(Duration::from_secs(1));

    output
}
