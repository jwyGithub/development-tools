use anyhow::Result;
use git2::{BranchType, Repository};

use crate::models::BranchInfo;

pub fn get_branch_info(repo: &Repository) -> Result<(Vec<BranchInfo>, Vec<BranchInfo>)> {
    let mut local_branches = Vec::new();
    let mut remote_branches = Vec::new();

    // 获取当前 HEAD 分支
    let head = repo.head().ok();
    let head_name = head
        .as_ref()
        .and_then(|h| h.shorthand())
        .unwrap_or("")
        .to_string();

    // 获取所有分支
    let branches = repo.branches(None)?;

    for branch in branches {
        let (branch, branch_type) = branch?;
        let name = branch.name()?.unwrap_or("").to_string();
        let is_head = name == head_name;

        let upstream = branch
            .upstream()
            .ok()
            .and_then(|b| b.name().ok().flatten().map(|s| s.to_owned()));

        let branch_info = BranchInfo::new(name, is_head, upstream);

        match branch_type {
            BranchType::Local => local_branches.push(branch_info),
            BranchType::Remote => remote_branches.push(branch_info),
        }
    }

    // 对本地分支进行排序：HEAD 分支优先，其他按字母顺序
    local_branches.sort_by(|a, b| {
        if a.is_head {
            std::cmp::Ordering::Less
        } else if b.is_head {
            std::cmp::Ordering::Greater
        } else {
            a.name.cmp(&b.name)
        }
    });

    // 对远程分支按字母顺序排序
    remote_branches.sort_by(|a, b| a.name.cmp(&b.name));

    Ok((local_branches, remote_branches))
} 
