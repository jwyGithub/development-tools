use crate::models::{BranchInfo, TagInfo};

pub fn display_branches(
    local: &[BranchInfo],
    remote: &[BranchInfo],
    show_local: bool,
    show_remote: bool,
) {
    if show_local {
        println!("本地分支:");
        for branch in local {
            if let Some(ref upstream) = branch.upstream {
                println!("{} -> {}", branch.display_name(), upstream);
            } else {
                println!("{}", branch.display_name());
            }
        }
    }

    if show_local && show_remote {
        println!();
    }

    if show_remote {
        println!("远程分支:");
        for branch in remote {
            println!("  {}", branch.name);
        }
    }
}

pub fn display_tags(local: &[TagInfo], remote: &[TagInfo], show_local: bool, show_remote: bool) {
    if show_local {
        println!("本地标签:");
        for tag in local {
            if let Some(ref message) = tag.message {
                println!(
                    "  {} {} {}",
                    tag.display_name(true),
                    tag.display_commit(),
                    message
                );
            } else {
                println!("  {} {}", tag.display_name(true), tag.display_commit());
            }
        }
    }

    if show_local && show_remote {
        println!();
    }

    if show_remote {
        println!("远程标签:");
        for tag in remote {
            if let Some(ref message) = tag.message {
                println!(
                    "  {} {} {}",
                    tag.display_name(false),
                    tag.display_commit(),
                    message
                );
            } else {
                println!("  {} {}", tag.display_name(false), tag.display_commit());
            }
        }
    }
}
