use global_error::prelude::*;
use godot::{classes::Json, prelude::*};
use serde::{de::DeserializeOwned, Serialize};
use std::future::Future;
use tokio::time::Duration;

pub struct BlockOnOpts {
    pub multithreaded: bool,
}

/**
* Create a temporary Tokio runtime to run the given future.
*/
pub fn block_on<Output>(fut: impl Future<Output = Output>, opts: BlockOnOpts) -> Output {
    // TODO: Add back once confirmed fixed
    // Build temporary runtime
    // let mut builder = if opts.multithreaded {
    //     tokio::runtime::Builder::new_multi_thread()
    // } else {
    //     tokio::runtime::Builder::new_current_thread()
    // };
    let mut builder = tokio::runtime::Builder::new_multi_thread();
    let rt = builder.enable_all().build().unwrap();

    // Run future
    let output = rt.block_on(fut);

    // Give tasks time to shut down
    // rt.shutdown_background();
    rt.shutdown_timeout(Duration::from_secs(1));

    output
}
