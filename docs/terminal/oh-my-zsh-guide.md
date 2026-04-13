## Tool Overview
- Oh My Zsh 是一款由 Robby Russell 主导维护、基于 Zsh 构建的开源社区化 Zsh 配置管理框架，核心定位是零门槛增强 Zsh、开箱即用的命令行美化与效率工具集，解决原生 Zsh 配置繁琐、插件零散、主题复杂的痛点，主打简单易用、生态丰富、社区活跃，全类 Unix 系统（macOS、Linux、BSD 等）均可一键安装，是全球最流行的 Zsh 增强方案，可快速将原生 Zsh 升级为现代化、高颜值、高效率终端环境，成为开发者与命令行用户标配工具。
- 其核心特性集中于开箱即用、主题生态、插件扩展、便捷管理四大维度：开箱即用层面无需复杂配置，一条命令即可完成安装与初始化，自动适配系统环境并生成默认配置，自动加载基础优化与常用别名，启动即用无需手动编写 .zshrc，同时兼容原生 Zsh 全部功能，不破坏原有命令与脚本；主题生态内置 150+ 款官方主题（如 Agnoster、Robbyrussell、Sunrise、Powerlevel10k 兼容），支持一键切换、实时预览，支持彩色提示符、Git 分支状态、路径缩写、执行耗时、权限标识等信息展示，可随使用场景自动展示关键信息，兼顾美观与实用性；插件扩展内置 270+ 官方插件，覆盖 Git、Docker、kubectl、npm、yarn、python、vscode 等主流工具链，支持命令补全、语法高亮、自动建议、目录跳转、代理快速切换等增强能力，插件启用仅需在配置中添加名称，无需额外安装依赖；便捷管理提供内置更新、卸载、插件 / 主题查询工具，支持自定义别名、函数、快捷键扩展，自动加载配置文件并热生效，兼容第三方插件与主题，可灵活组合打造专属终端环境，同时保持轻量稳定，不显著增加启动延迟。
- 使用场景主要覆盖普通开发者、运维人员、学生与终端入门用户：开发者日常编码、Git 操作、容器与云原生工具使用时，通过插件实现命令自动补全、分支提示、错误高亮，大幅减少输入与查错成本；运维人员在服务器管理、脚本执行、日志查看时，借助快速别名、目录跳转、历史命令增强提升运维效率，多服务器切换与批量操作更流畅；学生与入门用户无需理解复杂 shell 配置，即可拥有美观流畅的终端，降低命令行学习门槛；同时也适合重度终端用户快速搭建标准化环境，在多设备间同步配置，统一终端体验，替代手动配置 Zsh 的繁琐流程，实现高效、统一、可迁移的命令行工作流。

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
- oh-my-zsh中很多主题，常见的有"robbyrussell" "agnoster" "powerlevel10k"，可以在.zshrc中更换

- 如果需要oh-my-tmux和oh-my-zsh配合使用，可以让oh-my-zsh专门围绕git conda 路径等进行可视化
  - 更改插件：
    ```bash
      plugins=(
        git
        docker
        conda
      )
    ```
- zsh-autosuggestions和zsh-syntax-highlighting作为非常实用的功能，可以添加进入plugins
  - 安装 autosuggestions 插件
    ```bash
      git clone https://github.com/zsh-users/zsh-autosuggestions \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    ```
  - 安装 syntax-highlighting 插件
    ```bash
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    ```
  - 检查是否有新的两个插件存在：
    ```bash
      ls ~/.oh-my-zsh/custom/plugins
    ```
  - 在.zshrc中添加插件名字

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- 官方文档、推荐教程、插件链接

