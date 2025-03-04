use colored::*;

/// tag信息结构
#[derive(Debug, Clone)]
pub struct TagInfo {
    pub name: String,
    pub commit: String,
    pub message: Option<String>,
}

impl TagInfo {
    pub fn new(name: String, commit: String, message: Option<String>) -> Self {
        Self {
            name,
            commit,
            message,
        }
    }

    pub fn display_name(&self, is_local: bool) -> String {
        if is_local {
            self.name.green().to_string()
        } else {
            self.name.to_string()
        }
    }

    pub fn display_commit(&self) -> String {
        self.commit[..8].yellow().to_string()
    }

    pub fn display_message(&self) -> String {
        self.message.as_deref().unwrap_or("-").to_string()
    }
} 
