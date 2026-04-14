## Tool Overview
- tmux（终端多路复用器，Terminal Multiplexer）是由 Nicholas Marriott 主导开发的Unix/Linux/macOS 平台核心工具，定位为持久化、模块化、高度可控的终端会话管理器。它打破了传统终端 “会话与窗口强绑定、无法后台持久化” 的局限，主打会话隔离、多窗口 / 分屏管理、持久化运行，是远程开发、服务器运维与多任务并行场景的必备工具，可完全替代 Screen，在 macOS、Linux、BSD 等系统上稳定运行，也是 Oh My Zsh 等终端框架的常用配套增强工具。
- 其核心特性集中于会话隔离、多窗口 / 分屏、持久化、高度可控四大维度：
  - 会话隔离与持久化：核心能力是将终端会话与物理连接解耦，即使关闭 SSH 连接、终端窗口崩溃，后台会话仍持续运行（如长时间训练模型、跑脚本），重新连接后可恢复完整会话状态，避免任务因断连中断，同时实现多会话隔离，互不干扰。
  - 多窗口与分屏管理：支持在单个终端内创建多个独立窗口（相当于独立终端），并对窗口进行垂直 / 水平分屏（拆窗），自由调整面板大小、切换焦点、排列布局；可为不同窗口绑定专属任务（如编码、日志查看、数据库操作），通过快捷键快速切换，提升多任务协作效率。
  - 高度可定制与扩展性：基于客户端 - 服务器（C/S）架构，支持自定义快捷键、状态栏（显示时间、主机名、会话名、电池电量等）、面板样式；支持插件扩展（如 tmux-resurrect 保存会话、tmux-continuum 自动恢复），兼容 Zsh、Fish 等主流 Shell，与 Ghostty、iTerm2 等终端模拟器无缝配合。
  - 轻量高效：底层设计简洁，内存占用极低，高负载下仍保持响应速度，支持远程服务器无图形界面（Headless）环境下运行，是轻量级终端环境的核心组件。
- 使用场景主要覆盖远程开发者、服务器运维人员、AI 实验人员、多任务终端用户：
  - 远程开发者：通过 SSH 连接服务器时，用 tmux 管理多窗口开发环境，即使网络波动断开，重新 SSH 登录后可恢复之前的编码、调试会话，无需重新配置环境，适配 Python、PyTorch、Git 等开发工具链，提升远程协作效率。
  - 服务器运维人员：长时间运维服务器时，后台运行 tmux 托管日志查看、批量脚本执行、服务监控等任务，避免会话中断；多面板分屏可同时监控多个服务状态、对比配置文件，大幅提升运维效率。
  - AI 实验人员：运行深度学习训练、模型推理等长时任务时，用 tmux 持久化会话，避免本地电脑休眠、断连导致任务失败；同时分屏可实时查看 GPU 监控、日志输出，配合 NeRF、3D 高斯泼溅等工具使用，兼顾任务稳定性与可视化。
  - 多任务终端用户：日常办公、学习时，用 tmux 管理多个独立工作流（如文档编辑、命令行操作、笔记查看），通过快捷键快速切换，告别多终端窗口混乱，打造整洁高效的终端工作环境。

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
- 可以配合oh-my-tmux使用
  - 安装：
    - 安装指令：
      ```bash
        cd ~
        git clone https://github.com/gpakosz/.tmux.git
        ln -s -f .tmux/.tmux.conf
        cp .tmux/.tmux.conf.local .
      ```
    - 强制tmux使用之前配置的个性化zsh:
      - 打开当前用户的tmux配置文件：
        ```bash
          vim ~/.tmux.conf.local
        ```
      - 添加限制：
        ```bash
          set -g default-shell /usr/bin/zsh
          set -g default-command /usr/bin/zsh
        ```
    - 如果打开tmux出现乱码，有可能是TERM的问题，可以检查tmux内外的$TERM是否相同,通常是外部版本过老，在外部的.zshrc中修改TERM，类似：
      ```bash
        export TERM=xterm-256color
      ```
- **使用说明**：
  - 使用名字命名会话会方便attach
    ```bash
      tmux new -s <session-name>    #上面命令新建一个指定名称的会话。
    ```
  - 主动分离会话(一般来说ssh断联、exit主动退出、终端窗口被关闭都是被动分离)：
    ```bash
      tmux detach
    ```
  - 查看所有会话：
    ```bash
      tmux ls
    ```
  - 接入某个之前分离的会话：
    ```bash
      tmux attach -t xxxx
    ```
  - 杀死某个具体的会话：
    ```bash
      tmux kill-session -t xxxx
    ```
  - 切换会话：
    ```bash
      tmux switch -t xxxx
    ```
  - **核心操作**：
    - 所有快捷键都基于prefix（tmux默认是ctrl+b，oh-my-tmux中添加了ctrl+a）
    - 关闭当前pane用``ctrl+d``，关闭当前window可以关掉window上的全部pane，也可以``prefix+&``
    - 窗口相关：
      - 新建窗口：
        ```bash
          prefix + c
        ```
      - 切换窗口：
        ```bash
          prefix + p(previous)
          prefix + n(next)
          prefix + number(id)
        ```
    - pane（分屏）相关：
      - 横向分屏：
        ```bash
          prefix + "
        ```
      - 纵向分屏：
        ```bash
          prefix + %
        ```
      - 切换pane:
        ```bash
          prefix + 方向键
        ```
      - 调整pane大小：
        ```bash
          长按prefix + 方向键
        ```
      - 单个pane中翻动页面查看上下的内容：
        ```bash
          prefix + [ + 上/下/pgup/pgdn
        ```
    - 什么时候用windows，什么时候用panes：
      - windows类似浏览器的tab,相互切换，真正分开的是pane
      - 如果需要同时监控，就开panes，如果需要一定隔离属于不同的任务，就开windows
    

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- 官方文档、推荐教程、插件链接

