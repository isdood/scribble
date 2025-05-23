//! Prism Error Types
//! ================
//!
//! Error types and results for the quantum-harmonic framework.
//!
//! Author: Caleb J.D. Terkovics <isdood>
//! Created: 2025-01-21
//! Last Updated: 2025-01-21 13:05:02 UTC
//! Current User: isdood

use std::fmt;

/// Result type for quantum-harmonic operations
pub type PrismResult<T> = Result<T, PrismError>;

/// Error type for operations in the Prism framework
#[derive(Debug, thiserror::Error)]
pub enum PrismError {
    /// Runtime execution errors
    #[error("Runtime error: {0}")]
    Runtime(String),

    /// Task-related errors
    #[error("Task error: {0}")]
    Task(String),

    /// Crystal system errors
    #[error("Crystal error: {0}")]
    Crystal(String),

    /// FFI binding errors
    #[error("Binding error: {0}")]
    Binding(String),

    /// System-level errors
    #[error("System error: {0}")]
    SystemError(String),

    /// Invalid argument errors
    #[error("Invalid argument: {0}")]
    InvalidArgument(String),

    /// Memory allocation errors
    #[error("Out of memory: {0}")]
    OutOfMemory(String),

    /// Operation timeout errors
    #[error("Operation timed out: {0}")]
    Timeout(String),

    /// System not initialized
    #[error("System not initialized")]
    NotInitialized,

    /// Operation completed successfully
    #[error("Success")]
    Success,
}

/// Priority levels for quantum tasks
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Priority {
    Low,
    Normal,
    High,
    Critical,
}

impl Default for Priority {
    fn default() -> Self {
        Self::Normal
    }
}

/// Task status in the quantum runtime
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TaskStatus {
    Ready,
    Running,
    Completed,
    Failed,
}

impl Default for TaskStatus {
    fn default() -> Self {
        Self::Ready
    }
}

/// Crystal pattern types
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PatternType {
    Cubic,
    Hexagonal,
    Tetragonal,
    Orthorhombic,
    Monoclinic,
    Triclinic,
    Custom(u32),
}

impl Default for PatternType {
    fn default() -> Self {
        Self::Cubic
    }
}

impl fmt::Display for PatternType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Cubic => write!(f, "Cubic"),
            Self::Hexagonal => write!(f, "Hexagonal"),
            Self::Tetragonal => write!(f, "Tetragonal"),
            Self::Orthorhombic => write!(f, "Orthorhombic"),
            Self::Monoclinic => write!(f, "Monoclinic"),
            Self::Triclinic => write!(f, "Triclinic"),
            Self::Custom(id) => write!(f, "Custom({})", id),
        }
    }
}

impl From<i32> for PrismError {
    fn from(code: i32) -> Self {
        match code {
            0 => PrismError::Success,
            1 => PrismError::Runtime("Unknown runtime error".into()),
            2 => PrismError::Task("Unknown task error".into()),
            3 => PrismError::Crystal("Unknown crystal error".into()),
            4 => PrismError::Binding("Unknown binding error".into()),
            5 => PrismError::SystemError("Unknown system error".into()),
            6 => PrismError::InvalidArgument("Unknown invalid argument".into()),
            7 => PrismError::OutOfMemory("Unknown memory error".into()),
            8 => PrismError::Timeout("Unknown timeout error".into()),
            9 => PrismError::NotInitialized,
            _ => PrismError::SystemError(format!("Unknown error code: {}", code)),
        }
    }
}

impl From<PrismError> for i32 {
    fn from(error: PrismError) -> Self {
        match error {
            PrismError::Success => 0,
            PrismError::Runtime(_) => 1,
            PrismError::Task(_) => 2,
            PrismError::Crystal(_) => 3,
            PrismError::Binding(_) => 4,
            PrismError::SystemError(_) => 5,
            PrismError::InvalidArgument(_) => 6,
            PrismError::OutOfMemory(_) => 7,
            PrismError::Timeout(_) => 8,
            PrismError::NotInitialized => 9,
        }
    }
}
