# 版本信息
$Version = "0.1.0"
$RepoUrl = "https://github.com/jwyGithub/development-tools"
$InstallDir = "$env:USERPROFILE\.development-tools"
$Tools = @("ziper", "giter")

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
    while ($true) {
        Show-Menu
        Write-Host
    }
}

# 运行主程序
Main
