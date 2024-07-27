use std::future::Future;
use tokio::time::Duration;

const FORCE_MULTI_THREAD: bool = true;

pub struct BlockOnOpts {
    pub multithreaded: bool,
}

/**
* Create a temporary Tokio runtime to run the given future.
*/
pub fn block_on<Output>(fut: impl Future<Output = Output>, opts: BlockOnOpts) -> Output {
    // Build temporary runtime
    let mut builder = if opts.multithreaded || FORCE_MULTI_THREAD {
        tokio::runtime::Builder::new_multi_thread()
    } else {
        tokio::runtime::Builder::new_current_thread()
    };
    let rt = builder.enable_all().build().unwrap();

    // Run future
    let output = rt.block_on(fut);

    // Give tasks time to shut down
    // rt.shutdown_background();
    rt.shutdown_timeout(Duration::from_secs(1));

    output
}
