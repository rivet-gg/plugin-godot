use godot::prelude::*;
use tokio::sync::mpsc as tokio_mpsc;

use crate::util::runtime;

/// Returned when running a task to control the task.
#[derive(GodotClass)]
#[class(no_init)]
pub struct RivetTaskHandle {
    abort_tx: Option<tokio_mpsc::Sender<()>>,
}

impl RivetTaskHandle {
    pub fn create(abort_tx: tokio_mpsc::Sender<()>) -> Gd<Self> {
        Gd::from_object(Self {
            abort_tx: Some(abort_tx),
        })
    }
}

#[godot_api]
impl RivetTaskHandle {
    #[func]
    fn abort(&mut self) {
        if let Some(abort_tx) = self.abort_tx.take() {
            runtime::spawn(Box::pin(async move {
                match abort_tx.send(()).await {
                    Ok(_) => {}
                    Err(_) => {
                        eprintln!("task abort receiver dropped")
                    }
                }
            }));
        } else {
            eprintln!("task already aborted")
        }
    }
}
