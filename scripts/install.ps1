# 版本信息
$DefaultVersion = "0.1.0"
$RepoUrl = "https://github.com/jwyGithub/development-tools"
$InstallDir = "$env:USERPROFILE\.development-tools"
$Tools = @("ziper", "giter")

# 检测是否为交互式终端
function Test-Interactive {
    return [Environment]::UserInteractive -and ($Host.Name -eq 'ConsoleHost' -or $Host.Name -eq 'Windows PowerShell ISE Host')
}

# 检测系统架构
function Get-SystemArch {
    if ([Environment]::Is64BitOperatingSystem) {
        if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) {
            return "aarch64"
        }
        return "x86_64"
    }
    throw "不支持的系统架构"
}

# 获取最新版本
function Get-LatestVersion {
    param (
        [string]$Tool
    )
    
    $TagPrefix = switch ($Tool) {
        "ziper" { "zip-v" }
        "giter" { "git-v" }
        default { throw "未知的工具: $Tool" }
    }
    
    Write-Host "正在获取 $Tool 的最新版本..." -ForegroundColor Blue
    
    try {
        $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/jwyGithub/development-tools/releases" -ErrorAction Stop
        $LatestRelease = $Releases | Where-Object { $_.tag_name -like "$TagPrefix*" } | Select-Object -First 1
        
        if ($LatestRelease) {
            $Version = $LatestRelease.tag_name -replace "^$TagPrefix", ""
            Write-Host "找到最新版本: $Version" -ForegroundColor Green
            return $Version
        }
    }
    catch {
        Write-Host "无法获取最新版本: $_" -ForegroundColor Yellow
    }
    
    Write-Host "无法获取最新版本，使用默认版本 $DefaultVersion" -ForegroundColor Yellow
    return $DefaultVersion
}

# 下载工具
function Download-Tool {
    param (
        [string]$Tool,
        [string]$Version,
        [string]$Arch
    )
    
    $Target = "$Arch-pc-windows-msvc"
    $BinaryName = "$Tool-$Version-$Target.exe"
    
    # 根据工具名称确定正确的 tag 名称
    $TagName = switch ($Tool) {
        "ziper" { "zip-v$Version" }
        "giter" { "git-v$Version" }
        default { throw "未知的工具: $Tool" }
    }
    
    $Url = "$RepoUrl/releases/download/$TagName/$BinaryName"
    $OutputFile = "$InstallDir\$Tool.exe"
    
    Write-Host "下载 $Tool $Version for $Target..." -ForegroundColor Blue
    Write-Host "下载 URL: $Url" -ForegroundColor Blue
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutputFile
        Write-Host "$Tool 下载成功！" -ForegroundColor Green
    }
    catch {
        Write-Host "下载失败：$_" -ForegroundColor Red
        exit 1
    }
}

# 配置环境变量
function Set-ToolPath {
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $CurrentPath.Contains($InstallDir)) {
        $NewPath = "$CurrentPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        Write-Host "已添加环境变量配置" -ForegroundColor Green
        
        # 更新当前会话的 PATH
        $env:Path = "$env:Path;$InstallDir"
    }
}

# 安装工具
function Install-DevTool {
    param (
        [string]$Tool
    )
    
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }
    
    $Arch = Get-SystemArch
    $Version = Get-LatestVersion -Tool $Tool
    Download-Tool -Tool $Tool -Version $Version -Arch $Arch
    Set-ToolPath
    Write-Host "$Tool 安装成功！" -ForegroundColor Green
}

# 卸载工具
function Uninstall-DevTool {
    param (
        [string]$Tool
    )
    
    $ToolPath = "$InstallDir\$Tool.exe"
    if (Test-Path $ToolPath) {
        Remove-Item $ToolPath -Force
        Write-Host "$Tool 卸载成功！" -ForegroundColor Green
    }
    else {
        Write-Host "$Tool 未安装" -ForegroundColor Yellow
    }
}

# 升级工具
function Update-DevTool {
    param (
        [string]$Tool
    )
    
    Write-Host "升级 $Tool..." -ForegroundColor Blue
    Uninstall-DevTool -Tool $Tool
    Install-DevTool -Tool $Tool
}

# 安装所有工具
function Install-AllTools {
    Write-Host "正在安装所有工具..." -ForegroundColor Blue
    foreach ($tool in $Tools) {
        Install-DevTool -Tool $tool
    }
    Write-Host "所有工具安装完成！" -ForegroundColor Green
}

# 安装指定工具
function Install-SpecificTools {
    param (
        [string[]]$ToolsToInstall
    )
    
    if ($ToolsToInstall.Count -eq 0) {
        Write-Host "错误：未指定要安装的工具" -ForegroundColor Red
        Write-Host "可用的工具: $($Tools -join ', ')" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "正在安装指定的工具..." -ForegroundColor Blue
    foreach ($tool in $ToolsToInstall) {
        if ($Tools -contains $tool) {
            Install-DevTool -Tool $tool
        }
        else {
            Write-Host "错误：不支持的工具 '$tool'" -ForegroundColor Red
            Write-Host "可用的工具: $($Tools -join ', ')" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host "指定的工具安装完成！" -ForegroundColor Green
}

# 显示菜单
function Show-Menu {
    Write-Host "`nDevelopment Tools 安装脚本" -ForegroundColor Blue
    Write-Host "1) 安装工具"
    Write-Host "2) 升级工具"
    Write-Host "3) 卸载工具"
    Write-Host "4) 退出"
    Write-Host
    
    $choice = Read-Host "请选择操作 [1-4]"
    
    switch ($choice) {
        "1" {
            Write-Host "`n选择要安装的工具："
            Write-Host "1) ziper"
            Write-Host "2) giter"
            Write-Host "3) 全部"
            $toolChoice = Read-Host "请选择 [1-3]"
            
            switch ($toolChoice) {
                "1" { Install-DevTool -Tool "ziper" }
                "2" { Install-DevTool -Tool "giter" }
                "3" { 
                    foreach ($tool in $Tools) {
                        Install-DevTool -Tool $tool
                    }
                }
                default { Write-Host "无效的选择" -ForegroundColor Red }
            }
        }
        "2" {
            Write-Host "`n选择要升级的工具："
            Write-Host "1) ziper"
            Write-Host "2) giter"
            Write-Host "3) 全部"
            $toolChoice = Read-Host "请选择 [1-3]"
            
            switch ($toolChoice) {
                "1" { Update-DevTool -Tool "ziper" }
                "2" { Update-DevTool -Tool "giter" }
                "3" { 
                    foreach ($tool in $Tools) {
                        Update-DevTool -Tool $tool
                    }
                }
                default { Write-Host "无效的选择" -ForegroundColor Red }
            }
        }
        "3" {
            Write-Host "`n选择要卸载的工具："
            Write-Host "1) ziper"
            Write-Host "2) giter"
            Write-Host "3) 全部"
            $toolChoice = Read-Host "请选择 [1-3]"
            
            switch ($toolChoice) {
                "1" { Uninstall-DevTool -Tool "ziper" }
                "2" { Uninstall-DevTool -Tool "giter" }
                "3" { 
                    foreach ($tool in $Tools) {
                        Uninstall-DevTool -Tool $tool
                    }
                }
                default { Write-Host "无效的选择" -ForegroundColor Red }
            }
        }
        "4" {
            Write-Host "感谢使用！" -ForegroundColor Green
            exit
        }
        default {
            Write-Host "无效的选择" -ForegroundColor Red
        }
    }
}

# 主程序
function Main {
    param (
        [string[]]$Args
    )
    
    # 检查是否为交互式终端
    if (Test-Interactive) {
        # 交互式模式
        while ($true) {
            Show-Menu
            Write-Host
        }
    }
    else {
        # 非交互式模式（通过管道执行）
        # 检查是否有命令行参数
        if ($Args.Count -gt 0) {
            Install-SpecificTools -ToolsToInstall $Args
        }
        else {
            # 安装所有工具
            Install-AllTools
        }
    }
}

# 执行主程序
Main $args
