# 检测架构
$arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }

# 获取最新版本
try {
    $version = (Invoke-RestMethod -Uri "https://api.github.com/repos/jwyGithub/development-tools/releases/latest").tag_name
}
catch {
    $version = "v0.1.0"
}

# 构建下载 URL
$binaryName = "ziper-windows-$arch.exe"
$downloadUrl = "https://github.com/jwyGithub/development-tools/releases/download/$version/$binaryName"

Write-Host "正在下载 Ziper $version (windows-$arch)..."

# 创建临时目录
$tmpDir = Join-Path $env:TEMP "ziper-install"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

# 下载二进制文件
$outputFile = Join-Path $tmpDir "ziper.exe"
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile
}
catch {
    Write-Host "下载失败！"
    exit 1
}

# 确定安装目录
$installDir = if ($env:USERPROFILE) {
    Join-Path $env:USERPROFILE ".local\bin"
} else {
    "C:\Program Files\Ziper"
}

# 创建安装目录
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# 移动二进制文件到安装目录
$installPath = Join-Path $installDir "ziper.exe"
Move-Item -Force $outputFile $installPath

# 清理临时目录
Remove-Item -Recurse -Force $tmpDir

Write-Host "Ziper 已成功安装到 $installPath"

# 添加到 PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$userPath;$installDir",
        "User"
    )
    Write-Host "已将 $installDir 添加到用户 PATH 环境变量"
    Write-Host "请重新打开 PowerShell 或命令提示符以使更改生效"
}

Write-Host "安装完成！使用 'ziper --help' 查看使用说明" 
