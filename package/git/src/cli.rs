use clap::{Parser, Subcommand};
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

    # 查看标签 (View tags)
    {bin} tag")]
pub struct Cli {
    /// 要执行的命令
    #[command(subcommand)]
    pub command: Commands,

    /// 项目目录路径（可选，默认为当前目录）
    /// (Project directory path - optional, defaults to current directory)
    #[arg(short = 'p', long = "project", global = true)]
    pub project: Option<String>,

    /// 代理地址
    /// (Proxy address)
    #[arg(short = 'x', long = "proxy")]
    pub proxy: Option<String>,
}

#[derive(Subcommand)]
pub enum Commands {
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

    /// tag管理
    Tag {
        /// 列出所有tag
        /// (List all tags)
        #[arg(short = 'l', long = "list")]
        list: bool,

        /// 以表格形式显示（默认）
        /// (Display in table format - default)
        #[arg(short = 't', long = "table")]
        table: bool,
    },
}

impl Cli {
    pub fn get_repo_path(&self) -> PathBuf {
        if let Some(path) = &self.project {
            PathBuf::from(path)
        } else {
            std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
        }
    }
}
