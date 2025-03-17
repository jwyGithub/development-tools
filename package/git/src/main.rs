use anyhow::{Context, Result};
use clap::Parser;
use git2::Repository;

mod cli;
mod commands;
mod display;
mod models;

use cli::{Cli, Commands};

fn main() -> Result<()> {
    let mut cli = Cli::parse();

    // 设置代理
    if let Some(proxy) = cli.proxy.take() {
        std::env::set_var("http.proxy", proxy);
    }

    // 打开仓库
    let repo = Repository::discover(&cli.get_repo_path())
        .with_context(|| format!("无法在 {} 中找到 Git 仓库", cli.get_repo_path().display()))?;

    // 处理子命令
    match cli.command {
        Commands::Branch {
            list,
            table: _,
            local,
            remote,
        } => {
            let (local_branches, remote_branches) = commands::get_branch_info(&repo)?;
            let show_local = !remote;
            let show_remote = !local;

            if list {
                display::display_branches_list(
                    &local_branches,
                    &remote_branches,
                    show_local,
                    show_remote,
                );
            } else {
                display::display_branches_table(
                    &local_branches,
                    &remote_branches,
                    show_local,
                    show_remote,
                );
            }
        }
        Commands::Tag { list, table: _ } => {
            let (tags, _) = commands::get_tag_info(&repo)?;
            if list {
                display::display_tags_list(&tags, &[], true, false);
            } else {
                display::display_tags_table(&tags, &[], true, false);
            }
        }
    }

    Ok(())
}
