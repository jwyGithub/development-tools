use anyhow::{Context, Result};
use clap::Parser;
use glob::Pattern;
use log::{error, info, warn, LevelFilter};
use path_clean::clean;
use std::fs::File;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use zip::write::{ExtendedFileOptions, FileOptions};

/// 快速的文件压缩工具
///
/// 一个简单易用的ZIP压缩工具，用于将文件或目录压缩为ZIP格式。
/// 支持指定输出文件名和路径，忽略特定文件或目录，以及不同的输出详细级别。
#[derive(Parser)]
#[command(author, version, about, long_about = None)]
#[command(after_help = "示例:

```
# 基本用法：压缩目录为 [目录名].zip
ziper dist

# 指定输出文件
ziper dist output.zip

# 指定输出目录和文件名
ziper dist path/to/output.zip

# 忽略特定模式
ziper dist --ignore \"node_modules,.git,*.zip\"

# 使用静默模式
ziper dist -q

# 使用详细模式
ziper dist -v
```")]
struct Cli {
    /// 要压缩的源文件或目录
    ///
    /// 指定需要被压缩的文件或目录的路径。
    /// 如果是目录，将递归压缩其中的所有内容。
    source: Option<String>,

    /// 输出的zip文件路径
    ///
    /// 指定生成的ZIP文件的路径和名称。
    /// 如果不提供，默认使用源名称加.zip后缀。
    output: Option<String>,

    /// 要忽略的模式，使用逗号分隔
    ///
    /// 指定在压缩过程中要忽略的文件或目录模式。
    /// 支持glob模式，多个模式用逗号分隔。
    /// 例如："node_modules,.git,*.zip"
    #[arg(
        short = 'i',
        long = "ignore",
        value_delimiter = ',',
        help_heading = "过滤选项"
    )]
    ignore_patterns: Option<Vec<String>>,

    /// 静默模式 - 不显示输出
    ///
    /// 在压缩过程中不显示任何进度信息，除非发生错误。
    #[arg(
        short = 'q',
        long = "quiet",
        conflicts_with = "verbose",
        help_heading = "输出控制"
    )]
    quiet: bool,

    /// 详细模式 - 显示详细输出
    ///
    /// 在压缩过程中显示详细的进度信息，包括每个被处理的文件。
    #[arg(
        short = 'v',
        long = "verbose",
        conflicts_with = "quiet",
        help_heading = "输出控制"
    )]
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
                            let options = FileOptions::<ExtendedFileOptions>::default()
                                .compression_method(zip::CompressionMethod::Deflated)
                                .unix_permissions(0o755);
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

    // 如果没有提供源路径，显示帮助信息
    if cli.source.is_none() {
        eprintln!("错误: 必须提供源文件或目录路径");
        eprintln!("使用 --help 查看帮助信息");
        return Ok(());
    }

    let source = cli.source.unwrap();
    let source_path = Path::new(&source);

    // 如果源路径不存在，返回错误
    if !source_path.exists() {
        error!("源路径不存在: {}", source);
        return Ok(());
    }

    // 确定输出路径
    let output = match cli.output {
        Some(path) => PathBuf::from(path),
        None => {
            let mut path = source_path.to_path_buf();
            path.set_extension("zip");
            path
        }
    };

    // 编译忽略模式
    let ignore_patterns: Vec<Pattern> = cli
        .ignore_patterns
        .unwrap_or_default()
        .iter()
        .filter_map(|pattern| match Pattern::new(pattern) {
            Ok(p) => Some(p),
            Err(e) => {
                warn!("无效的忽略模式 '{}': {}", pattern, e);
                None
            }
        })
        .collect();

    // 创建 zip 文件
    create_zip(source_path, &output, &ignore_patterns)?;

    Ok(())
}
