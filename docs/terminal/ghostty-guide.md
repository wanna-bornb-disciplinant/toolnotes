## Tool Overview
- Ghostty 是一款由 Mitchell Hashimoto 主导开发、使用 Zig 语言构建的跨平台终端模拟器，核心定位是兼顾极致速度、丰富功能与原生体验的现代化 CLI 工具，打破传统终端 “快则功能弱、强则不原生” 的取舍困境，主打高性能渲染与轻量化设计，在 macOS、Linux 平台可稳定运行，Windows 版本处于开发阶段，能无缝替代 iTerm2、Kitty、GNOME Terminal 等主流终端
- 其核心特性集中于性能、原生交互、功能扩展与个性化四大维度：性能上采用 GPU 加速渲染，macOS 用 Metal、Linux 用 OpenGL，高负载下可稳定 60fps，滚动海量日志、处理 AI 工具长文本输出时无卡顿，内存占用仅为同类终端的 1/3，启动速度低于 100ms，搭配专用 IO 线程实现低延迟、无抖动交互；原生交互层面深度适配系统 UI，macOS 基于 SwiftUI/AppKit、Linux 采用 GTK4 框架，原生支持标签页、分屏、下拉式快速终端，支持安全键盘输入，密码输入时自动显示锁定图标，贴合系统操作习惯；功能扩展上支持 Kitty 图形协议，可在终端直接显示图片，兼容 Neovim、Zellij 等工具，完整遵循 ECMA-48 与 xterm 标准，内置终端多路复用能力，无需依赖 tmux 即可实现分屏、布局保存与自动恢复；个性化方面内置 200 + 款主流主题（如 Catppuccin、Tokyo Night、Nord），支持随系统深色 / 浅色模式自动切换，支持连字字体、Emoji 完整渲染、超链接识别，同时提供灵活的快捷键自定义与数百项配置选项，零配置开箱即用，也可深度定制
- 使用场景主要覆盖开发者、系统管理员与 AI 工具用户：开发者日常编码、调试与命令行操作时，可借助分屏、标签页管理多任务，流畅查看长代码与日志，适配 Python、Go、Rust 等开发环境，配合 Git、Docker、Kubernetes 等工具链提升效率；系统管理员运维服务器时，处理海量系统日志、批量执行脚本、监控服务状态，凭借低资源占用与高稳定性，长时间运行无压力；AI 编程用户使用 Claude Code、Cursor、GitHub Copilot CLI 等工具时，因低延迟、无卡顿的长文本渲染能力，成为 Anthropic 官方推荐的适配终端，可高效接收、查看 AI 生成的大量代码与输出内容；此外也适合普通用户替代系统默认终端，享受轻量化、高颜值、高响应的命令行体验。

## Installation & Setup
- 事先明确一点，ghostty作为终端模拟器，你装在本地电脑上看到的就是ghostty，当使用ssh连接远程服务器工作时，终端模拟器是工作在本地环境中的，这是ghostty和类似tmux zsh等终端工具都不同的一点

- mac安装：
  - 首先确定mac os的系统高于MACOS 13，否则无法正常安装运行
  - mac中默认的shell是zsh
  - 通过``brew --version``检查是否安装Homebrew，如未安装使用``/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"``进行安装，intel版和apple silicon版的默认安装前缀会不同
  - 安装oh-my-zsh
    - 安装命令为
      ```bash
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
      ```
    - 上面的指令在国内大概率timeout,可以选择官方加速入口、gitee版本和清华镜像源，使用镜像源在后续更新的时候也最好改成镜像源，我们用镜像源举例：
      - ```bash
          git clone https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git
          cd ohmyzsh/tools
          REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git sh install.sh
        ```
      - 更新清华源：
        ```bash
          git -C ~/.oh-my-zsh remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git
        ```
    - 通过下面的命令验证是否安装成功：
      ```bash
        ls ~/.oh-my-zsh
        echo $SHELL
      ```
  - 安装tmux
    ```bash
      brew install tmux
      tmux -V
    ```
  - 使用CLI的方式安装ghostty：
    ```bash
      brew install --cask ghostty
    ```
  - 截止目前，在mac中安装了上述四个工具，tmux是显式调用，zsh是mac的默认shell，其余的工具需要默认使用
    - ghostty安装成功后会类似一个应用程序出现在访达中
    - 从ghostty中启动shell，如果在zsh中能看到git分支、路径高亮和彩色提示，就说明oh-my-zsh已经成功运行
    - 接下来是默认使用tmux：
      - 打开zsh配置文件
        ```bash
          nano ~/.zshrc
        ```
      - 在最后添加这一段：
        ```bash
          # Auto start tmux
          if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
            tmux
          fi
        ```
- 如果是本地windows+ssh远程连接linux服务器的方案，仅需在linux中安装zsh + oh-my-zsh + tmux即可，本地安装的ghostty或类似原始的windows terminal功能够强大

- ubuntu安装：
  - 

## Core Usage
- 

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- 官方文档、推荐教程、插件链接

