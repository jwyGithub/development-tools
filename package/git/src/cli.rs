use clap::{arg, command, value_parser, Parser, Subcommand};
use std::path::PathBuf;

/// Git 工具集
///
/// 一个Git仓库管理工具，提供更直观的分支和标签管理功能。
/// 支持查看分支信息、标签信息，并可以进行分支和标签的管理操作。
#[derive(Parser)]
#[command(
    name = "giter",
    version,
    author,
    about,
    long_about = None,
    // 使用严格的错误检查
    arg_required_else_help(true),
    // 使用彩色帮助文档
    color = clap::ColorChoice::Auto,
    // 启用命令别名
    disable_help_flag(false)
)]
pub struct Cli {
    /// 要执行的命令
    #[command(subcommand)]
    pub command: Commands,

    /// 项目目录路径（可选，默认为当前目录）
    ///
    /// 指定Git仓库的根目录路径。如果不提供，将使用当前工作目录。
    /// 例如：`giter -p /path/to/repo branch`
    #[arg(
        short = 'p',
        long = "project",
        global = true,
        value_name = "DIR",
        value_parser = value_parser!(PathBuf),
    )]
    pub project: Option<PathBuf>,

    /// 代理地址
    ///
    /// 设置HTTP代理地址，用于访问远程Git仓库。
    /// 例如：`giter --proxy http://127.0.0.1:7890 branch`
    #[arg(
        short = 'x',
        long = "proxy",
        value_name = "URL",
        help_heading = "网络设置"
    )]
    pub proxy: Option<String>,
}

/// Git仓库操作命令
#[derive(Subcommand)]
#[command(about = "Git仓库操作命令")]
pub enum Commands {
    /// 分支管理
    ///
    /// 查看和管理Git仓库中的分支。
    /// 可以以表格或列表形式显示，支持筛选本地和远程分支。
    ///
    /// 示例:
    ///
    /// ```
    /// # 以表格形式显示所有分支
    /// giter branch
    ///
    /// # 以列表形式显示所有分支
    /// giter branch --list
    ///
    /// # 只显示本地分支
    /// giter branch --local
    ///
    /// # 只显示远程分支
    /// giter branch --remote
    /// ```
    #[command(visible_alias = "br")]
    Branch {
        /// 以列表形式显示
        ///
        /// 将分支信息以简洁的列表形式展示，每行显示一个分支。
        #[arg(
            short = 'l',
            long = "list",
            conflicts_with = "table",
            help_heading = "显示格式"
        )]
        list: bool,

        /// 以表格形式显示（默认）
        ///
        /// 将分支信息以表格形式展示，包含更多详细信息。
        #[arg(
            short = 't',
            long = "table",
            conflicts_with = "list",
            default_value = "true",
            help_heading = "显示格式"
        )]
        table: bool,

        /// 只显示本地分支
        ///
        /// 仅显示本地仓库中的分支，不包含远程分支。
        #[arg(long = "local", conflicts_with = "remote", help_heading = "筛选选项")]
        local: bool,

        /// 只显示远程分支
        ///
        /// 仅显示远程仓库中的分支，不包含本地分支。
        #[arg(long = "remote", conflicts_with = "local", help_heading = "筛选选项")]
        remote: bool,
    },

    /// 标签管理
    ///
    /// 查看和管理Git仓库中的标签。
    /// 可以以表格或列表形式显示所有标签。
    ///
    /// 示例:
    ///
    /// ```
    /// # 以表格形式显示所有标签
    /// giter tag
    ///
    /// # 以列表形式显示所有标签
    /// giter tag --list
    /// ```
    #[command(visible_alias = "t")]
    Tag {
        /// 以列表形式显示
        ///
        /// 将标签信息以简洁的列表形式展示，每行显示一个标签。
        #[arg(
            short = 'l',
            long = "list",
            conflicts_with = "table",
            help_heading = "显示格式"
        )]
        list: bool,

        /// 以表格形式显示（默认）
        ///
        /// 将标签信息以表格形式展示，包含更多详细信息。
        #[arg(
            short = 't',
            long = "table",
            conflicts_with = "list",
            default_value = "true",
            help_heading = "显示格式"
        )]
        table: bool,
    },
}

impl Cli {
    pub fn get_repo_path(&self) -> PathBuf {
        match &self.project {
            Some(path) => path.clone(),
            None => std::env::current_dir().unwrap_or_else(|_| PathBuf::from(".")),
        }
    }
}
