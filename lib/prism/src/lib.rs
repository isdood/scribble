//! Prism: Crystal-based High Performance Computing Framework
//! ======================================================
//!
//! A quantum-harmonic computational framework leveraging crystal lattice patterns
//! for distributed parallel processing and resonance-based task scheduling.
//!
//! Architecture:
//! ------------
//! - Crystal Core: Quantum-harmonic computational patterns
//! - Runtime: Resonance-mapped task scheduling
//! - Bindings: Rust/Zig FFI interface for crystal operations
//!
//! Author: Caleb J.D. Terkovics <isdood>
//! Created: 2025-01-21
//! Last Updated: 2025-01-21 12:58:17 UTC
//! Current User: isdood

// Import the rust module and its submodules
pub(crate) mod rust;

// Re-export public interfaces
pub use rust::{
    binding,
    crystal,
    runtime,
    types,
};

use std::sync::Arc;
use std::future::Future;

// Re-export core types
pub use rust::{
    crystal::bridge::{Crystal, CrystalNode, CrystalSystem},
    runtime::task::{Task, TaskConfig, TaskExecutor},
    types::{PrismError, PrismResult, Priority, TaskStatus},
};

/// Framework version from Cargo manifest
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Result type for quantum-harmonic operations
pub type Result<T> = std::result::Result<T, PrismError>;

/// Quantum Runtime Configuration
/// Controls crystal lattice parameters and resonance patterns
#[derive(Debug, Clone)]
pub struct RuntimeConfig {
    /// Number of quantum threads in crystal lattice
    pub thread_count: u32,
    /// Stack size for resonance patterns
    pub stack_size: usize,
    /// Enable hardware-level quantum threading
    pub use_hardware_threads: bool,
    /// Optional memory limit for crystal growth
    pub memory_limit: Option<usize>,
}

impl Default for RuntimeConfig {
    fn default() -> Self {
        Self {
            thread_count: num_cpus::get() as u32,
            stack_size: 2 * 1024 * 1024, // 2MB quantum buffer
            use_hardware_threads: true,
            memory_limit: None,
        }
    }
}

/// Prism Quantum Runtime
/// Manages crystal patterns and task execution through resonance mapping
pub struct Runtime {
    executor: TaskExecutor,
    crystal: Arc<Crystal>,
    config: RuntimeConfig,
}

impl Runtime {
    /// Initialize a new quantum-harmonic runtime with the given configuration
    pub fn init(config: RuntimeConfig) -> Result<Self> {
        let crystal = Arc::new(Crystal::new(CrystalSystem::Cubic)?);
        let executor = TaskExecutor::new(Some(Arc::clone(&crystal)))
        .map_err(|e| PrismError::Runtime(e.to_string()))?;

        Ok(Self {
            executor,
            crystal,
            config,
        })
    }

    /// Create a new quantum task with the specified configuration
    pub fn create_task<F>(&self, future: F, config: TaskConfig) -> Result<Task<F>>
    where
    F: Future<Output = PrismResult<()>> + Send + 'static,
    {
        Task::new(future, config, Some(Arc::clone(&self.crystal)))
        .map_err(|e| PrismError::Task(e.to_string()))
    }

    /// Execute a task through the crystal lattice
    pub async fn execute<F>(&self, task: Task<F>) -> Result<()>
    where
    F: Future<Output = PrismResult<()>> + Send + 'static,
    {
        self.executor.submit(task)
        .await
        .map_err(|e| PrismError::Runtime(e.to_string()))
    }

    /// Get a reference to the current crystal system
    pub fn crystal(&self) -> &Arc<Crystal> {
        &self.crystal
    }

    /// Get the current quantum runtime configuration
    pub fn config(&self) -> &RuntimeConfig {
        &self.config
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    async fn test_task() -> PrismResult<()> {
        tokio::time::sleep(Duration::from_millis(100)).await;
        Ok(())
    }

    #[tokio::test]
    async fn test_runtime_init() {
        let config = RuntimeConfig::default();
        let runtime = Runtime::init(config).unwrap();
        assert!(Arc::strong_count(&runtime.crystal) >= 1);
    }

    #[tokio::test]
    async fn test_task_creation() {
        let runtime = Runtime::init(RuntimeConfig::default()).unwrap();
        let task_config = TaskConfig::default();
        let task = runtime.create_task(test_task(), task_config).unwrap();
        assert_eq!(task.status(), TaskStatus::Ready);
    }

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }
}

/// Prism Framework Prelude
/// Common types for quantum-harmonic computing
pub mod prelude {
    pub use super::{
        Crystal,
        CrystalSystem,
        PrismError,
        PrismResult,
        Runtime,
        RuntimeConfig,
        Task,
        TaskConfig,
        TaskExecutor,
        TaskStatus,
    };
}
