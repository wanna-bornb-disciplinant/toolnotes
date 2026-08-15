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
  ```text
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
  ```
  - 关键配置项：
  - 主配置文件中的 `defaults` 列表定义加载哪些子配置，顺序决定覆盖优先级（后面的覆盖前面的）。
  - `_self_` 用于控制主配置文件自身的加载位置，默认在主配置最后加载（优先级最高）。
  - 可以通过 `hydra/job_logging`、`hydra/hydra_logging` 自定义日志配置。
  - 输出目录可通过 `hydra.run.dir` 配置，支持变量插值（如 `${now}`）。

## Core Usage（高频操作 + 快捷键 + 实用技巧）

- **命令行覆盖**：
- `python my_app.py key=value`：覆盖已有字段。
- `+key=value`：新增一个在配置中不存在的字段。
- `++key=value`：强制覆盖或新增（无视是否存在）。
- 覆盖配置组：`python my_app.py db=postgres`（不加前缀）。
- **多运行（Multirun）**：使用 `-m` 或 `--multirun` 进行参数组合扫描。
- 示例：`python my_app.py -m db=mysql,postgres model=resnet,vit`，自动生成 2×2 四种组合，依次运行。
- 结果保存在独立的时间戳目录下。
- **`@package` 规则**：
- 默认情况下，子配置文件的“着陆点”是其在 `conf/` 下的相对路径（如 `conf/db/mysql.yaml` → `db` 节点）。
- 使用 `# @package _global_` 将该文件的所有内容提升到配置树的根节点下，便于跨节点覆盖顶层变量。
- 也可以在子文件中指定 `@package foo.bar` 挂载到任意节点。
- **`_self_`**：出现在主配置文件的 `defaults` 列表中，用于显式控制主配置自身的加载顺序。
- 不加 `_self_`：主配置最后加载，优先级最高。
- 加上 `- _self_`：主配置插入到该位置，后续的配置会覆盖它。
- **`_target_`**：在配置中指定要实例化的 Python 类或函数。
- 配合 `hydra.utils.instantiate(cfg.xxx)` 动态创建对象。
- 默认 `instantiate` 会递归实例化所有嵌套的 `_target_`（`_recursive_=True`）。
- **`_partial_`**：用于延迟实例化或部分应用。
- `_partial_: true` 标记一个配置块为“工厂”，阻止递归实例化，`instantiate` 返回 `functools.partial` 对象，调用时才真正创建。
- `_partial_: my_module.my_func` 直接指定一个函数/类，效果类似。
- 典型用途：依赖注入、需要运行时参数的创建、多次创建相同配置的实例（性能优化）。
- **结构化配置（Structured Configs）**：
- 使用 Python `dataclass` 定义配置 Schema，通过 `ConfigStore` 注册。
- 示例：
  ```python
  from dataclasses import dataclass
  from hydra.core.config_store import ConfigStore

  @dataclass
  class MySQLConfig:
      host: str = "localhost"
      port: int = 3306

  cs = ConfigStore.instance()
  cs.store(name="mysql", group="db", node=MySQLConfig)
  ```
- 注册后，defaults: - db: mysql 将使用该数据类生成配置，无需对应的 YAML 文件。
- 推荐在数据类中使用 MISSING（from omegaconf import MISSING）作为默认值，强制 YAML 提供值，实现启动时校验。
- 可在数据类字段中使用 DictConfig 类型表示动态结构，代替 Any 以保留点号访问。
- **实用技巧**：
  - 在子配置中使用 ${...} 插值引用其他配置节点（如 host: ${db.host}）。
  - 使用 --cfg job 或 --cfg hydra 查看合并后的配置。
  - 在 instantiate 时传递额外参数：instantiate(cfg.obj, extra_param=value)。
  - 使用 @hydra.main(config_path="conf", config_name="config") 装饰入口函数。
  - 通过 hydra.utils.call(cfg.some_config, **kwargs) 一步完成实例化并调用。
## Common Pitfalls（避坑指南 + 解决方案）

- YAML 缩进使用 Tab：YAML 只允许空格缩进，混用 Tab 会导致解析错误。解决方案：编辑器设置为空格缩进（推荐 2 或 4 空格）。
- 冒号/短横线后缺少空格：key:value 会被解析为字符串，-item 会被当作普通字符串。务必写成 key: value 和 - item。
- 子配置试图覆盖顶层变量但未加 @package _global_：子配置中的 app_name 会变成 db.app_name，不生效。如需覆盖顶层，必须在子文件顶部加 # @package _global_，并在其中显式声明顶层变量。
- 在数据类中使用可变默认值（如 []）：所有实例共享同一列表。应使用 field(default_factory=list) 或 field(default_factory=lambda: [1,2,3])。
- CLI 覆盖不存在的字段被忽略：直接写 key=value 只能覆盖已有字段，若字段不存在则被静默忽略。应使用 +key=value 新增。
- _partial_ 误解：认为 _partial_ 不需要 instantiate。实际上仍需调用 instantiate，只是它返回的是工厂函数而非最终对象。
- 结构化配置中类型使用 Any：失去类型检查和 IDE 补全。推荐用 DictConfig 表示动态字典，或用 Union 列举可能的具体类型。
- ConfigStore 注册时机晚于 @hydra.main：必须在 @hydra.main 装饰的函数定义之前完成注册，否则配置找不到。最佳实践：注册代码放在模块顶层，在入口函数之前。
- defaults 列表中的 - _self_ 位置错误：放在不同位置会影响主配置的覆盖优先级。默认不加 _self_ 时主配置最高，若想让子配置覆盖主配置，应将 - _self_ 放在列表最前面或中间（取决于具体覆盖需求）。
- 多运行（-m）时组合过多导致内存爆炸：可使用 hydra/sweeper 插件（如 Optuna）进行智能搜索，或通过 --multirun 配合 --jobs 限制并行数。
- instantiate 递归实例化导致意外创建所有嵌套对象：如果只想创建外层对象，而内层对象需延迟创建，务必在嵌套配置中加上 _partial_: true 阻止递归。
- 在业务代码中模仿 Hydra 内部写法：如 field(default_factory=lambda: defaults) 这种依赖运行时上下文的写法，仅在 Hydra/OmegaConf 内部有效，普通代码中直接使用会引发 NameError。

## Useful Resources（官方文档、推荐教程、插件链接）

- 官方文档：![Hydra 主页](https://hydra.cc) | ![OmegaConf 文档](https://omegaconf.readthedocs.io/en/2.3_branch/)
- 入门教程：

  - Hydra 官方教程（包含基础到高级）: ![https://hydra.cc/docs/tutorials/](https://hydra.cc/docs/tutorials/)
  - 结构化配置详解：![https://hydra.cc/docs/advanced/structured_configs/](https://hydra.cc/docs/advanced/structured_configs/)
  - 多运行与 Sweeper 插件：![https://hydra.cc/docs/plugins/optuna_sweeper/](https://hydra.cc/docs/plugins/optuna_sweeper/)
- 推荐社区教程：

  - “Hydra 完全指南”系列（Medium）
  - PyTorch Lightning + Hydra 最佳实践（Lightning AI 官方博客）
- 常用插件列表：

  - hydra-colorlog：彩色终端日志
  - hydra-submitit-launcher：提交到 SLURM 集群
  - hydra-optuna-sweeper：Optuna 超参搜索
  - hydra-ray-launcher：Ray 分布式执行
  - hydra-ax-sweeper：Ax 平台超参优化
- 调试工具：

  - hydra.utils.get_original_cwd() 获取原始工作目录
  - hydra.utils.to_absolute_path() 转换相对路径
  - 使用 --hydra-help 查看所有 Hydra 命令行选项
  - 社区与支持：GitHub Issues、Slack（Python 开发者社区常有讨论）、Stack Overflow 标签 hydra 和 omegaconf




