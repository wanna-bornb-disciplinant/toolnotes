# YAML 与 Hydra 核心知识速查手册

## Tool Overview（Core function + 适用场景）

- **YAML**：一种人类可读的数据序列化格式，常用于配置文件。核心功能是描述键值对、列表、嵌套结构，支持注释、锚点引用、多文档等特性。
- **Hydra**：一个基于 Python 的配置管理框架，用于简化复杂应用的配置组合与管理。核心功能包括：
  - 通过 `defaults` 列表实现配置的模块化组合与覆盖。
  - 支持命令行动态覆盖配置参数。
  - 提供 `--multirun`（`-m`）进行参数扫描（组合爆炸实验）。
  - 与 OmegaConf 深度集成，支持结构化配置（dataclass 定义 Schema）。
  - 支持通过 `_target_` 和 `_partial_` 实现配置驱动的对象实例化（依赖注入）。
- **适用场景**：
  - 机器学习实验管理（超参数组合、多环境切换）。
  - 复杂应用的配置分层（开发/测试/生产环境）。
  - 需要类型安全、IDE 补全的大型项目。
  - 需要动态组合配置、运行时覆盖配置的实验性项目。

## Installation & Setup（从头安装 + 关键配置）

- 安装 Hydra 核心库：`pip install hydra-core`。
- 如需使用结构化配置（dataclass）和类型校验，无需额外安装（依赖 OmegaConf 自动安装）。
- 推荐安装插件：
  - `hydra-colorlog`（彩色日志）
  - `hydra-submitit-launcher`（提交到集群）
  - `hydra-optuna-sweeper`（集成 Optuna 超参优化）
  - `hydra-ray-launcher`（分布式运行）
- 项目目录结构建议：
project/
├── conf/
│   ├── config.yaml          # 主配置文件，包含 defaults 列表
│   ├── db/
│   │   ├── mysql.yaml
│   │   └── postgres.yaml
│   ├── model/
│   │   ├── resnet.yaml
│   │   └── vit.yaml
│   └── experiment/          # 可选：存放特定实验的组合配置
│       └── exp1.yaml
└── src/
    └── my_app.py            # 使用 @hydra.main 装饰器
