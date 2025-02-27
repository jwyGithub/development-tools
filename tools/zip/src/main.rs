use anyhow::{Context, Result};
use clap::Parser;
use glob::Pattern;
use log::{error, info, warn, LevelFilter};
use path_clean::clean;
use std::fs::File;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
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
")]
struct Cli {
    /// 要压缩的源文件或目录 (Source directory or file to compress)
    source: String,

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

fn main() -> Result<()> {
    let cli = Cli::parse();
    setup_logger(cli.quiet, cli.verbose);

    // Convert ignore patterns to glob patterns
    let ignore_patterns: Vec<Pattern> = cli
        .ignore_patterns
        .unwrap_or_default()
        .iter()
        .map(|p| Pattern::new(p))
        .collect::<std::result::Result<Vec<_>, _>>()
        .context("Invalid ignore pattern")?;

    let source = Path::new(&cli.source);
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
