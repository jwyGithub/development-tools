use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use colored::*;
use git2::{BranchType, Repository};
use prettytable::{Cell, Row, Table};
#[cfg(unix)]
use std::path::PathBuf;

/// Git 工具集
#[derive(Parser)]
#[command(author, version, about = "Git 工具集", long_about = None)]
#[command(help_template = "{about-section}
用法 (Usage): {usage}

命令 (Commands):
{subcommands}

选项 (Options):
{options}

示例 (Examples):
    # 查看当前目录的分支信息 (View branches in current directory)
    {bin} branch

    # 查看指定目录的分支信息 (View branches in specified directory)
    {bin} branch -p /path/to/repo

    # 以列表形式显示分支 (Display branches in list format)
    {bin} branch --list

    # 以表格形式显示分支（默认）(Display branches in table format - default)
    {bin} branch --table

    # 只显示本地分支 (Show only local branches)
    {bin} branch --local

    # 只显示远程分支 (Show only remote branches)
    {bin} branch --remote
")]
struct Cli {
    /// 要执行的命令
    #[command(subcommand)]
    command: Commands,

    /// 项目目录路径（可选，默认为当前目录）
    /// (Project directory path - optional, defaults to current directory)
    #[arg(short = 'p', long = "project", global = true)]
    project: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    /// 分支管理
    Branch {
        /// 以列表形式显示
        /// (Display in list format)
        #[arg(short = 'l', long = "list")]
        list: bool,

        /// 以表格形式显示（默认）
        /// (Display in table format - default)
        #[arg(short = 't', long = "table")]
        table: bool,

        /// 只显示本地分支
        /// (Show only local branches)
        #[arg(long = "local", conflicts_with = "remote")]
        local: bool,

        /// 只显示远程分支
        /// (Show only remote branches)
        #[arg(long = "remote", conflicts_with = "local")]
        remote: bool,
    },
}

/// 分支信息结构
struct BranchInfo {
    name: String,
    is_head: bool,
    upstream: Option<String>,
}

fn get_branch_info(repo: &Repository) -> Result<(Vec<BranchInfo>, Vec<BranchInfo>)> {
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

        let branch_info = BranchInfo {
            name,
            is_head,
            upstream,
        };

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

fn display_table(local: &[BranchInfo], remote: &[BranchInfo], show_local: bool, show_remote: bool) {
    let mut table = Table::new();
    table.add_row(Row::new(vec![
        Cell::new("类型").style_spec("Fb"),
        Cell::new("分支名").style_spec("Fb"),
        Cell::new("上游分支").style_spec("Fb"),
    ]));

    // 添加本地分支
    if show_local {
        for branch in local {
            let name = if branch.is_head {
                format!("* {}", branch.name).green().to_string()
            } else {
                format!("  {}", branch.name)
            };

            table.add_row(Row::new(vec![
                Cell::new("本地"),
                Cell::new(&name),
                Cell::new(branch.upstream.as_deref().unwrap_or("-")),
            ]));
        }
    }

    // 添加远程分支
    if show_remote {
        for branch in remote {
            table.add_row(Row::new(vec![
                Cell::new("远程"),
                Cell::new(&branch.name),
                Cell::new("-"),
            ]));
        }
    }

    table.printstd();
}

fn display_list(local: &[BranchInfo], remote: &[BranchInfo], show_local: bool, show_remote: bool) {
    if show_local {
        println!("本地分支:");
        for branch in local {
            let prefix = if branch.is_head { "* " } else { "  " };
            let name = if branch.is_head {
                branch.name.green()
            } else {
                branch.name.normal()
            };

            if let Some(ref upstream) = branch.upstream {
                println!("{}{} -> {}", prefix, name, upstream);
            } else {
                println!("{}{}", prefix, name);
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

fn main() -> Result<()> {
    let cli = Cli::parse();

    // 确定仓库路径
    let repo_path = if let Some(path) = cli.project {
        PathBuf::from(path)
    } else {
        std::env::current_dir()?
    };

    // 打开仓库
    let repo = Repository::discover(&repo_path)
        .with_context(|| format!("无法在 {} 中找到 Git 仓库", repo_path.display()))?;

    // 处理子命令
    match cli.command {
        Commands::Branch {
            list,
            table: _,
            local,
            remote,
        } => {
            // 获取分支信息
            let (local_branches, remote_branches) = get_branch_info(&repo)?;

            // 确定显示哪些分支
            let show_local = !remote;
            let show_remote = !local;

            // 显示分支信息
            if list {
                display_list(&local_branches, &remote_branches, show_local, show_remote);
            } else {
                display_table(&local_branches, &remote_branches, show_local, show_remote);
            }
        }
    }

    Ok(())
}
