## Tool Overview
- Zsh（Z-shell）是一款由 Paul Falstad 于 1990 年主导开发的Unix/Linux/macOS 平台命令行 shell（命令解释器），定位为兼容传统、功能极强、高度可定制的现代化 shell，集成 Bourne shell、Bash、Ksh、Csh 等主流 shell 精华特性，打破 “传统 shell 功能简陋、增强 shell 学习成本高” 的局限，主打智能交互、强大扩展、极致个性化，全类 Unix 系统（macOS、Linux、BSD 等）原生支持，自 macOS Catalina 起成为 macOS 默认 shell，可无缝替代 Bash、Ksh、Tcsh 等传统 shell，搭配 Oh My Zsh 等框架后成为开发者首选命令行环境。
- 其核心特性集中于兼容性、智能交互、功能扩展、个性化四大维度：兼容性上完全兼容 Bash 语法与 POSIX 标准，可直接运行所有 Bash 脚本，提供 sh/ksh/csh 模拟模式，平滑迁移无压力，继承传统 shell 稳定可靠的脚本执行能力；智能交互拥有业界最强命令补全，支持命令、参数、路径、变量、 man 页、命令选项等多级智能补全，支持跨终端共享命令历史、实时去重，支持多行命令编辑、撤销重做、拼写纠错，输入错误命令可自动提示修正，目录切换支持自动补全、历史跳转、模糊匹配，无需完整路径即可快速定位；功能扩展内置模块化架构，支持加载 TCP/Unix 套接字、FTP 客户端、数学函数等扩展模块，支持强大的通配符（递归匹配、 glob 筛选、排除文件），无需 find 即可完成复杂文件查找，支持数组、关联数组、高阶变量处理，支持函数重载、别名扩展、脚本热重载，搭配 Oh My Zsh、Prezto 等框架可使用 300+ 插件（如语法高亮、自动建议、Git 增强、Docker 补全）；个性化支持高度自定义提示符（左右双提示符、右侧信息隐藏、Git 分支 / 状态实时显示、路径缩写），内置 140+ 主题（如 Powerlevel10k、Agnoster、Pure），支持图标、Emoji、彩色高亮、连字字体渲染，支持快捷键完全自定义、按键绑定修改、启动项配置，零配置可用，也可通过 .zshrc 实现数百项深度定制。
- 使用场景主要覆盖开发者、系统管理员、运维工程师、命令行重度用户：开发者编写、调试、运行脚本时，凭借智能补全、语法高亮、自动建议大幅提升输入效率，Git/Docker/K8s/Node/Python 等工具链适配完善，目录快速跳转、历史命令智能检索减少重复操作，多项目并行开发时命令管理更高效；系统管理员 / 运维批量执行命令、服务器运维、日志排查时，强大通配符简化文件批量操作，跨终端共享历史避免重复输入，别名与函数简化复杂长命令，长时间运行稳定、资源占用低，适配 SSH 远程、批量脚本、自动化任务场景；命令行重度用户日常文件管理、文本处理、系统操作时，拼写纠错、模糊跳转、智能补全降低操作门槛，高颜值提示符与主题提升使用体验，替代系统默认 Bash 后交互更流畅、功能更丰富；普通用户也可零成本使用，macOS 开箱即用、Linux 一键安装，享受比默认 shell 更友好、更高效、更美观的命令行体验，无需学习复杂语法即可享受增强功能。

## Installation & Setup
- 事先明确一点，ghostty作为终端模拟器，你装在本地电脑上看到的就是ghostty，当使用ssh连接远程服务器工作时，终端模拟器是工作在本地环境中的，这是ghostty和类似tmux zsh等终端工具都不同的一点

- **如果在远程服务器上配置下面的终端工具+docker容器的工作模式，遇到一些诸如shell等的问题最好的解决方式就是直接重写dockerfile来规避，terminal目录中提供了类似的创建流程**

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
    - 接下来是默认使用tmux(!!!慎选，可以会和后续的一些配置发生冲突)：
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

- ubuntu安装(如果你的本地环境就是linux，请自己去安装ghostty)：
  - 如果在容器中不是root权限，在切换到root权限运行下列指令的时候，注意要修改真实使用用户的配置文件，root和普通用户的配置文件是独立的
  - 保证apt正常：
    ```bash
      sudo apt update
      sudo apt upgrade -y
    ```
  - 安装zsh:
    ```bash
      sudo apt install -y zsh
      zsh --version
    ```
  - 切换为zsh:
    ```bash
      chsh -s "$(which zsh)"
    ```
    - 这里有一些具体的实现细节，例如如果你的运行环境是docker的容器，则配置只会在当前的容器中生效，同时docker exec的指令就要相应的做出一些更改：例如/bin/bash改为zsh
  - 检查切换是否正确：
    ```bash
      cat /etc/passwd | grep xxxx(用户名) 
    ```
    - 输出类似zsh之类的信息即启动成功
  - 安装oh-my-zsh:
    ```bash
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```
  - 安装tmux：
    ```bash
      apt install -y tmux
    ```

## Core Usage
- 高频操作 + 快捷键 + 实用技巧

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- 官方文档、推荐教程、插件链接

