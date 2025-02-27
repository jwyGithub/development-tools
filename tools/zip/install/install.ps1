# 检测系统架构
$arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }

# 获取最新版本
try {
    $version = (Invoke-RestMethod -Uri "https://api.github.com/repos/jwyGithub/development-tools/releases/latest").tag_name
} catch {
    $version = "v0.1.0"  # 默认版本
}

# 构建下载 URL
$binaryName = "ziper-windows-$arch.exe"
$downloadUrl = "https://github.com/jwyGithub/development-tools/releases/download/$version/$binaryName"

Write-Host "正在下载 Ziper $version (windows-$arch)..."

# 创建临时目录
$tempDir = Join-Path $env:TEMP "ziper-install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# 下载二进制文件
$zipperPath = Join-Path $tempDir "ziper.exe"
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipperPath
} catch {
    Write-Host "下载失败！"
    exit 1
}

# 确定安装目录
$installDir = if (Test-IsAdmin) {
    # 管理员权限，安装到系统目录
    "C:\Program Files\Ziper"
} else {
    # 用户权限，安装到用户目录
    Join-Path $env:LOCALAPPDATA "Programs\Ziper"
}

# 创建安装目录
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# 移动二进制文件
$installPath = Join-Path $installDir "ziper.exe"
Move-Item -Force $zipperPath $installPath

# 添加到 PATH
$envTarget = if (Test-IsAdmin) { "Machine" } else { "User" }
$currentPath = [Environment]::GetEnvironmentVariable("Path", $envTarget)

if (-not $currentPath.Contains($installDir)) {
    $newPath = "$currentPath;$installDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, $envTarget)
    $env:Path = "$env:Path;$installDir"
}

# 清理临时目录
Remove-Item -Recurse -Force $tempDir

Write-Host "Ziper 已成功安装到 $installPath"
Write-Host "安装完成！使用 'ziper --help' 查看使用说明"

# 辅助函数：检查是否有管理员权限
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# 显示帮助信息
function Show-Help {
    Write-Host "Ziper 安装工具"
    Write-Host
    Write-Host "用法："
    Write-Host "  install.ps1 [选项]"
    Write-Host
    Write-Host "选项："
    Write-Host "  -upgrade     升级到最新版本"
    Write-Host "  -remove      卸载 Ziper"
    Write-Host "  -help        显示此帮助信息"
}

# 获取当前版本
function Get-CurrentVersion {
    try {
        $version = (Get-Command ziper -ErrorAction SilentlyContinue).Version
        if ($version) {
            return $version.ToString()
        }
    } catch {}
    return "未安装"
}

# 获取最新版本
function Get-LatestVersion {
    try {
        $version = (Invoke-RestMethod -Uri "https://api.github.com/repos/jwyGithub/development-tools/releases/latest").tag_name
        if ($version) {
            return $version
        }
    } catch {}
    return "v0.1.0"
}

# 安装或升级
function Install-OrUpgrade {
    param (
        [bool]$Force = $false
    )
    
    # 检测系统架构
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
    
    # 版本检查
    $currentVersion = Get-CurrentVersion
    $latestVersion = Get-LatestVersion
    
    if (($currentVersion -eq $latestVersion) -and (-not $Force)) {
        Write-Host "已经是最新版本 ($latestVersion)"
        return
    }
    
    # 构建下载 URL
    $binaryName = "ziper-windows-$arch.exe"
    $downloadUrl = "https://github.com/jwyGithub/development-tools/releases/download/$latestVersion/$binaryName"
    
    Write-Host "正在下载 Ziper $latestVersion (windows-$arch)..."
    
    # 创建临时目录
    $tempDir = Join-Path $env:TEMP "ziper-install"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    # 下载二进制文件
    $zipperPath = Join-Path $tempDir "ziper.exe"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipperPath
    } catch {
        Write-Host "下载失败！"
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        exit 1
    }
    
    # 确定安装目录
    $installDir = if (Test-IsAdmin) {
        "C:\Program Files\Ziper"
    } else {
        Join-Path $env:LOCALAPPDATA "Programs\Ziper"
    }
    
    # 创建安装目录
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    
    # 移动二进制文件
    $installPath = Join-Path $installDir "ziper.exe"
    Move-Item -Force $zipperPath $installPath
    
    # 添加到 PATH
    $envTarget = if (Test-IsAdmin) { "Machine" } else { "User" }
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $envTarget)
    
    if (-not $currentPath.Contains($installDir)) {
        $newPath = "$currentPath;$installDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, $envTarget)
        $env:Path = "$env:Path;$installDir"
    }
    
    # 清理临时目录
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    
    if ($Force) {
        Write-Host "Ziper 已成功安装到 $installPath"
    } else {
        Write-Host "Ziper 已成功升级到 $latestVersion"
    }
    Write-Host "使用 'ziper --help' 查看使用说明"
}

# 卸载函数
function Remove-Ziper {
    try {
        $ziperPath = (Get-Command ziper -ErrorAction Stop).Source
        $installDir = Split-Path $ziperPath -Parent
        
        # 删除二进制文件和目录
        Remove-Item -Force $ziperPath -ErrorAction Stop
        if ((Get-ChildItem $installDir -Force).Count -eq 0) {
            Remove-Item -Recurse -Force $installDir -ErrorAction SilentlyContinue
        }
        
        # 从 PATH 中移除
        $envTarget = if (Test-IsAdmin) { "Machine" } else { "User" }
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $envTarget)
        $newPath = ($currentPath.Split(';') | Where-Object { $_ -ne $installDir }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, $envTarget)
        $env:Path = ($env:Path.Split(';') | Where-Object { $_ -ne $installDir }) -join ';'
        
        Write-Host "Ziper 已成功卸载"
    } catch {
        Write-Host "未找到 Ziper 安装"
        exit 1
    }
}

# 主逻辑
switch ($args[0]) {
    "-upgrade" {
        Install-OrUpgrade -Force $false
    }
    "-remove" {
        Remove-Ziper
    }
    "-help" {
        Show-Help
    }
    $null {
        Install-OrUpgrade -Force $true
    }
    default {
        Write-Host "未知选项: $($args[0])"
        Show-Help
        exit 1
    }
} 
