use anyhow::{Context, Result};
use clap::Parser;
use glob::Pattern;
use log::{error, info, warn, LevelFilter};
use path_clean::clean;
use std::env;
use std::fs::File;
use std::io::{self, Write};
#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use walkdir::WalkDir;

/// 快速的文件压缩工具 (A fast compression tool)
#[derive(Parser)]
#[command(author, version, about = "快速的文件压缩工具 (A fast compression tool)", long_about = None)]
#[command(help_template = "{about-section}
用法 (Usage): {usage}

参数 (Arguments):
{positionals}

选项 (Options):
{options}

示例 (Examples):
    # 基本用法：压缩目录为 [目录名].zip (Basic usage: compress directory to [dirname].zip)
    {bin} dist

    # 指定输出文件 (Specify output file)
    {bin} dist output.zip

    # 指定输出目录和文件名 (Specify output directory and filename)
    {bin} dist dest/output.zip

    # 忽略特定文件和目录 (Ignore specific files and directories)
    {bin} dist --ignore \"node_modules,.git,*.zip,*.tar\"

    # 静默模式 (Quiet mode)
    {bin} dist -q

    # 详细输出模式 (Verbose mode)
    {bin} dist -v

    # 升级到最新版本 (Upgrade to latest version)
    {bin} --upgrade

    # 卸载程序 (Remove the program)
    {bin} --remove
")]
struct Cli {
    /// 要压缩的源文件或目录 (Source directory or file to compress)
    #[arg(default_value = None)]
    source: Option<String>,

    /// 输出的zip文件路径（可选，默认为源名称加.zip后缀）
    /// (Output zip file path - optional, defaults to source name with .zip extension)
    #[arg(default_value = None)]
    output: Option<String>,

    /// 要忽略的模式，使用逗号分隔（例如："node_modules,.git,*.zip"）
    /// (Patterns to ignore, comma-separated - e.g., "node_modules,.git,*.zip")
    #[arg(short = 'i', long = "ignore", value_delimiter = ',')]
    ignore_patterns: Option<Vec<String>>,

    /// 静默模式 - 不显示输出
    /// (Quiet mode - suppress output)
    #[arg(short = 'q', long = "quiet")]
    quiet: bool,

    /// 详细模式 - 显示详细输出
    /// (Verbose mode - show detailed output)
    #[arg(short = 'v', long = "verbose")]
    verbose: bool,

    /// 升级到最新版本
    /// (Upgrade to latest version)
    #[arg(long = "upgrade")]
    upgrade: bool,

    /// 卸载程序
    /// (Remove the program)
    #[arg(long = "remove")]
    remove: bool,
}

fn setup_logger(quiet: bool, verbose: bool) {
    let level = if quiet {
        LevelFilter::Error
    } else if verbose {
        LevelFilter::Debug
    } else {
        LevelFilter::Info
    };

    env_logger::Builder::from_default_env()
        .filter_level(level)
        .format(|buf, record| {
            if record.level() == log::Level::Info {
                writeln!(buf, "{}", record.args())
            } else {
                writeln!(buf, "[{}] {}", record.level(), record.args())
            }
        })
        .init();
}

fn should_ignore(path: &Path, ignore_patterns: &[Pattern]) -> bool {
    let path_str = path.to_string_lossy();

    // 首先检查完整路径
    for pattern in ignore_patterns {
        if pattern.matches(&path_str) {
            return true;
        }
    }

    // 检查每个路径组件
    for component in path.components() {
        let comp_str = component.as_os_str().to_string_lossy();
        for pattern in ignore_patterns {
            if pattern.matches(&comp_str) {
                return true;
            }
        }
    }

    false
}

fn create_zip(source: &Path, output: &Path, ignore_patterns: &[Pattern]) -> Result<()> {
    let file = File::create(output).context("Failed to create zip file")?;
    let mut zip = zip::ZipWriter::new(file);
    let options = zip::write::FileOptions::default()
        .compression_method(zip::CompressionMethod::Deflated)
        .unix_permissions(0o755);

    let source_path = clean(source);
    let source_name = source_path.file_name().unwrap_or_default();

    // 使用 WalkDir 的配置选项来更好地处理错误
    let walker = WalkDir::new(&source_path)
        .follow_links(false) // 不跟随符号链接
        .same_file_system(true) // 保持在同一个文件系统内
        .contents_first(false); // 目录优先

    for entry in walker {
        match entry {
            Ok(entry) => {
                let path = entry.path();

                // Skip if path matches any ignore pattern
                if should_ignore(path, ignore_patterns) {
                    info!("Ignoring: {}", path.display());
                    continue;
                }

                let relative_path = if path == source_path {
                    PathBuf::from(source_name)
                } else {
                    let stripped_path = path.strip_prefix(&source_path)?;
                    PathBuf::from(source_name).join(stripped_path)
                };

                if path.is_file() {
                    match File::open(path) {
                        Ok(mut f) => {
                            info!("Adding: {}", relative_path.display());
                            if let Err(e) = zip
                                .start_file(relative_path.to_string_lossy().into_owned(), options)
                            {
                                warn!("Failed to add file {}: {}", path.display(), e);
                                continue;
                            }
                            if let Err(e) = io::copy(&mut f, &mut zip) {
                                warn!("Failed to copy file {}: {}", path.display(), e);
                                continue;
                            }
                        }
                        Err(e) => {
                            warn!("Failed to open file {}: {}", path.display(), e);
                            continue;
                        }
                    }
                } else if !path.is_dir() {
                    warn!("Skipping non-regular file: {}", path.display());
                }
            }
            Err(e) => {
                // 只是警告而不是中断整个过程
                warn!("Failed to access path: {}", e);
                continue;
            }
        }
    }

    zip.finish()?;
    Ok(())
}

fn remove_ziper() -> Result<()> {
    // 获取 HOME 目录
    let home = get_home_dir()?;
    let ziper_dir = home.join(".ziper");

    // 删除 ziper 目录
    if ziper_dir.exists() {
        std::fs::remove_dir_all(&ziper_dir).context("删除 ziper 目录失败")?;
        info!("已删除 ziper 目录");
    }

    // Windows 平台不需要修改 shell 配置
    #[cfg(unix)]
    {
        // 获取当前用户的 shell
        let shell = env::var("SHELL").unwrap_or_else(|_| String::from("/bin/bash"));
        let shell_name = Path::new(&shell)
            .file_name()
            .unwrap_or_default()
            .to_string_lossy();

        // 确定配置文件路径
        let rc_file = match shell_name.as_ref() {
            "zsh" => home.join(".zshrc"),
            "bash" => home.join(".bashrc"),
            _ => home.join(".profile"),
        };

        // 如果配置文件存在，清理 ziper 相关配置
        if rc_file.exists() {
            // 使用 sed 删除 ziper 相关配置
            let status = Command::new("sed")
                .arg("-i.bak")
                .arg("-e")
                .arg("/# ziper/d")
                .arg("-e")
                .arg("/\\.ziper\\/ziper\\.sh/d")
                .arg(&rc_file)
                .status()
                .context("执行 sed 命令失败")?;

            if status.success() {
                // 删除备份文件
                let _ = std::fs::remove_file(rc_file.with_extension("bak"));
                info!("已清理 shell 配置");
            }
        }

        info!("Ziper 已成功卸载，请重新打开终端或执行 'source ~/.zshrc' 使配置生效");
    }

    #[cfg(windows)]
    {
        info!("Ziper 已成功卸载");
    }

    Ok(())
}

fn get_latest_version() -> Result<String> {
    let output = Command::new("curl")
        .arg("-s")
        .arg("https://api.github.com/repos/jwyGithub/development-tools/releases/latest")
        .output()
        .context("获取最新版本信息失败")?;

    let output_str = String::from_utf8_lossy(&output.stdout);
    if let Some(version) = output_str.split('"').find(|s| s.starts_with('v')) {
        Ok(version.to_string())
    } else {
        Ok("v0.1.0".to_string())
    }
}

fn get_home_dir() -> Result<PathBuf> {
    if cfg!(windows) {
        env::var("USERPROFILE").map(PathBuf::from).context("无法获取 USERPROFILE 目录")
    } else {
        env::var("HOME").map(PathBuf::from).context("无法获取 HOME 目录")
    }
}

fn get_current_version() -> Result<String> {
    let home = get_home_dir()?;
    let ziper_path = if cfg!(windows) {
        home.join(".ziper").join("bin").join("ziper.exe")
    } else {
        home.join(".ziper").join("bin").join("ziper")
    };

    if !ziper_path.exists() {
        return Ok("未安装".to_string());
    }

    let output = Command::new(ziper_path)
        .arg("--version")
        .output()
        .context("获取当前版本失败")?;

    let version = String::from_utf8_lossy(&output.stdout)
        .split_whitespace()
        .nth(1)
        .unwrap_or("未知")
        .to_string();

    Ok(version)
}

fn upgrade_ziper() -> Result<()> {
    let current_version = get_current_version()?;
    let latest_version = get_latest_version()?;

    if current_version == latest_version {
        info!("已经是最新版本 ({})", latest_version);
        return Ok(());
    }

    // 获取系统信息
    let os = if cfg!(target_os = "macos") {
        "darwin"
    } else if cfg!(target_os = "linux") {
        "linux"
    } else if cfg!(target_os = "windows") {
        "windows"
    } else {
        return Err(anyhow::anyhow!("不支持的操作系统"));
    };

    let arch = if cfg!(target_arch = "x86_64") {
        "amd64"
    } else if cfg!(target_arch = "aarch64") {
        "arm64"
    } else if cfg!(target_arch = "x86") {
        "386"
    } else {
        return Err(anyhow::anyhow!("不支持的系统架构"));
    };

    // 构建下载 URL
    let binary_name = if cfg!(windows) {
        format!("ziper-{}-{}.exe", os, arch)
    } else {
        format!("ziper-{}-{}", os, arch)
    };
    
    let download_url = format!(
        "https://github.com/jwyGithub/development-tools/releases/download/{}/{}",
        latest_version, binary_name
    );

    info!("正在下载 Ziper {} ({}-{})...", latest_version, os, arch);

    // 创建临时目录
    let tmp_dir = std::env::temp_dir().join("ziper-upgrade");
    std::fs::create_dir_all(&tmp_dir).context("创建临时目录失败")?;
    let tmp_file = if cfg!(windows) {
        tmp_dir.join("ziper.exe")
    } else {
        tmp_dir.join("ziper")
    };

    // 下载新版本
    let status = Command::new("curl")
        .arg("-sSL")
        .arg(&download_url)
        .arg("-o")
        .arg(&tmp_file)
        .status()
        .context("下载失败")?;

    if !status.success() {
        return Err(anyhow::anyhow!("下载失败"));
    }

    // 设置执行权限（仅 Unix 系统）
    #[cfg(unix)]
    std::fs::set_permissions(&tmp_file, std::fs::Permissions::from_mode(0o755))
        .context("设置执行权限失败")?;

    // 获取安装目录
    let home = get_home_dir()?;
    let install_dir = home.join(".ziper").join("bin");
    let install_path = if cfg!(windows) {
        install_dir.join("ziper.exe")
    } else {
        install_dir.join("ziper")
    };

    // 创建安装目录
    std::fs::create_dir_all(&install_dir).context("创建安装目录失败")?;

    // 移动文件到安装目录
    std::fs::rename(&tmp_file, &install_path).context("安装失败")?;

    // 清理临时目录
    std::fs::remove_dir_all(&tmp_dir).ok();

    info!("Ziper 已成功升级到 {}", latest_version);
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    setup_logger(cli.quiet, cli.verbose);

    if cli.upgrade {
        return upgrade_ziper();
    }

    if cli.remove {
        return remove_ziper();
    }

    // 检查是否提供了源路径
    let source = if let Some(source) = cli.source {
        source
    } else {
        error!("请指定要压缩的源文件或目录");
        std::process::exit(1);
    };

    // Convert ignore patterns to glob patterns
    let ignore_patterns: Vec<Pattern> = cli
        .ignore_patterns
        .unwrap_or_default()
        .iter()
        .map(|p| Pattern::new(p))
        .collect::<std::result::Result<Vec<_>, _>>()
        .context("Invalid ignore pattern")?;

    let source = Path::new(&source);
    if !source.exists() {
        error!("Source path does not exist: {}", source.display());
        std::process::exit(1);
    }

    // Determine output path
    let output = if let Some(output) = cli.output {
        // 如果提供了输出路径，直接使用
        PathBuf::from(output)
    } else {
        // 默认使用源文件名加.zip后缀
        let name = source.file_name().unwrap_or_default();
        PathBuf::from(format!("{}.zip", name.to_string_lossy()))
    };

    // 确保输出目录存在
    if let Some(parent) = output.parent() {
        if !parent.exists() {
            std::fs::create_dir_all(parent).context("Failed to create output directory")?;
        }
    }

    info!("Compressing {} to {}", source.display(), output.display());
    create_zip(source, &output, &ignore_patterns)?;
    info!("Successfully created {}", output.display());

    Ok(())
}
