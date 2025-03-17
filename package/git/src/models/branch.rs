use colored::*;

/// 分支信息结构
#[derive(Debug)]
pub struct BranchInfo {
    pub name: String,
    pub is_head: bool,
    pub upstream: Option<String>,
}

impl BranchInfo {
    pub fn new(name: String, is_head: bool, upstream: Option<String>) -> Self {
        Self {
            name,
            is_head,
            upstream,
        }
    }

    pub fn display_name(&self) -> String {
        if self.is_head {
            format!("* {}", self.name).green().to_string()
        } else {
            format!("  {}", self.name)
        }
    }

    pub fn display_upstream(&self) -> String {
        self.upstream.as_deref().unwrap_or("-").to_string()
    }
}
