## Tool Overview

- PyTorch Lightning 的核心定位是对原生 PyTorch 训练流程进行工程化封装：保留 `torch.nn.Module`、`torch.optim`、`DataLoader` 等 PyTorch 组件，同时把训练循环、验证循环、分布式训练、混合精度、日志、Checkpoint 和 Callback 等常见工程逻辑交给 `Trainer` 管理。
- `LightningModule` 负责“模型如何训练”：通常包含网络结构、`forward()`、`training_step()`、`validation_step()`、`test_step()`、`configure_optimizers()`，以及训练生命周期相关的 hooks。最核心的是 `training_step()` 与 `configure_optimizers()`；`forward()` 仍然用于定义模型本身的前向传播。
- `LightningDataModule` 负责“数据如何提供”：常见方法包括 `prepare_data()`、`setup()`、`train_dataloader()`、`val_dataloader()`、`test_dataloader()`、`predict_dataloader()`。其中 `prepare_data()` 更适合只需要做一次的数据下载或准备工作，`setup()` 更适合在每个训练进程中构造 Dataset、划分数据集和创建与当前 stage 相关的数据对象。
- `Trainer` 负责“训练如何运行”：管理 epoch/batch loop、自动反向传播、optimizer step、验证、测试、设备、DDP/FSDP、混合精度、梯度累积、梯度裁剪、Callback、Logger 和 Checkpoint。通常不需要继承 `Trainer`，而是通过参数配置。
- TorchMetrics 不是 PyTorch 官方核心包，而是 Lightning AI 维护的指标库。它提供 Accuracy、Precision、Recall、F1、AUROC、Dice、PSNR、SSIM 等标准化指标，并通过有状态的 `update → compute → reset` 机制累积跨 batch 的统计结果；它可以独立用于 PyTorch，也和 Lightning 的 `self.log()`、DDP 指标同步高度兼容。
- Hook 是“训练生命周期中的时间点接口”，例如 `on_train_start()`、`on_train_epoch_start()`、`on_train_batch_end()`、`on_validation_epoch_end()`、`on_before_backward()`、`on_after_backward()`、`on_before_optimizer_step()`、`on_save_checkpoint()` 等。Hook 的关键是“什么时候执行”。
- Callback 是“把一组 Hook 封装成独立可复用对象”。例如 `ModelCheckpoint`、`EarlyStopping`、`LearningRateMonitor` 都是 Lightning 官方提供的 Callback。可以理解为：Hook 是接口/插槽，Callback 是利用这些插槽实现功能的独立模块。
- Lightning 的 Logger 是统一日志抽象。`self.log()` 并不是 TensorBoard 专属 API，它只是把指标交给 Trainer/Logger；Logger 可以是 W&B、TensorBoard、CSV、MLflow 等。切换 Logger 往往不需要修改 `LightningModule` 内已有的 `self.log()`。
- Checkpoint 在 Lightning 中不仅是模型权重，而通常包含模型参数、optimizer 状态、scheduler 状态、epoch、global step、部分 callback 状态和其他训练状态，因此既能用于推理，也能用于断点续训。
- `ModelCheckpoint` 是一个典型 Callback：它根据 `monitor`、`mode`、`save_top_k`、`save_last`、`every_n_epochs`、`every_n_train_steps` 等规则自动决定什么时候保存 `.ckpt`。
- `lightning-hydra-template`（常见仓库名为 `ashleve/lightning-hydra-template`）的核心思想是把 Lightning 的模型、数据、Trainer、Callback、Logger 与 Hydra 的配置组合系统连接起来：Python 负责“类怎么实现”，YAML 负责“这次实验选哪个类、什么参数”。
- Hydra 中最关键的概念包括 `_target_`、`_partial_`、`defaults`、`${...}` 插值和 CLI override。`hydra.utils.instantiate()` 会根据 `_target_` 动态创建对象，因此 DataModule、LightningModule、Trainer、Callback、Logger 都可以配置化。
- `@task_wrapper` 不是 Hydra 或 Lightning 官方装饰器，而是 `lightning-hydra-template` 自己定义的工程辅助装饰器。它通常在整个 `train()` / `evaluate()` 任务外层提供统一的 `try / except / finally` 逻辑，用于异常记录、输出目录提示和 W&B 等资源收尾。它比 Lightning Hook/Callback 所处的层级更高。

## Installation & Setu

- Lightning 常见安装方式：`pip install lightning`。现代代码通常使用 `import lightning as L`，并从 `lightning.pytorch` 中导入 Callback、Logger 等组件。
- TorchMetrics 可安装为：`pip install torchmetrics`。分类任务推荐使用更明确的类，例如 `BinaryAccuracy`、`MulticlassAccuracy`，而不是依赖容易受版本变化影响的旧式泛化写法。
- W&B 可安装为：`pip install wandb`，首次使用通常运行 `wandb login`，或在服务器/容器环境中通过 `WANDB_API_KEY` 等环境变量完成认证。
- Hydra 通常安装为：`pip install hydra-core`。`lightning-hydra-template` 项目还会依赖 OmegaConf，以及项目自身列出的日志、超参数搜索和测试相关依赖；具体版本应优先参考仓库当前的 `pyproject.toml`、`requirements.txt` 或锁文件。
- 一个最小 Lightning 工程可以只使用 `LightningModule + Trainer`，并把原生 DataLoader 直接传给 `trainer.fit()`；`LightningDataModule` 不是强制组件，而是为了让数据逻辑更清晰、更适合多实验和多进程场景。
- W&B 与 Lightning 配合时，创建 `WandbLogger(project=..., name=...)` 后传入 `Trainer(logger=wandb_logger)`；此后 `self.log("train_loss", loss)` 等指标会自动进入 W&B。不要同时对同一个 scalar 又调用 `self.log()` 又手动 `wandb.log()`，否则可能造成重复记录或 step 不一致。
- 多 GPU 时常见 Trainer 设置为 `accelerator="gpu", devices=N, strategy="ddp"`；多机时额外设置 `num_nodes=M`。其中 `devices` 通常表示“每个节点使用多少设备”，总进程数近似为 `world_size = devices × num_nodes`。
- 多机训练不能只靠 `Trainer(num_nodes=...)` 自动发现其他机器，还需要 torchrun、SLURM 等 launcher/cluster environment 提供主节点地址、端口、node rank、world size 等运行环境。
- H100/A100 一类硬件上可优先考虑 `precision="bf16-mixed"`；FP16 场景则常见 `precision="16-mixed"`。具体精度选择仍需结合模型数值稳定性验证。
- Hydra-Lightning 项目推荐把 Python 代码与配置分开：`src/` 放实现，`configs/` 放 data/model/trainer/callbacks/logger/experiment 等配置组；`train.py` 尽量只做 instantiate 与 `trainer.fit()` 调度。
- 一个简化的 Hydra-Lightning 目录可以是：`configs/data/`、`configs/model/`、`configs/trainer/`、`configs/callbacks/`、`configs/logger/`、`configs/experiment/`、`configs/train.yaml`，以及 `src/data/`、`src/models/`、`src/train.py`。
- 为保证复现实验，可结合 `L.seed_everything(seed, workers=True)`、`Trainer(deterministic=True)`、固定依赖版本和保存完整 Hydra 配置。需要注意：deterministic 可能牺牲性能，也不保证所有硬件/算子上绝对 bitwise 一致。

## Core Usage

- `LightningModule` 常见最小结构：`__init__()` 中定义网络与超参数；`forward()` 负责普通推理路径；`training_step(batch, batch_idx)` 计算并返回 loss；`validation_step()` / `test_step()` 负责评估；`configure_optimizers()` 返回 optimizer，必要时同时返回 scheduler。
- Lightning 自动优化模式下，一般不需要在 `training_step()` 中手写 `optimizer.zero_grad()`、`loss.backward()` 和 `optimizer.step()`；这些由 Trainer 完成。只有复杂优化算法、多个 optimizer、RL 或特殊 alternating optimization 场景才会考虑 manual optimization。
- `LightningDataModule.prepare_data()` 适合下载等只应做一次的操作，`setup(stage)` 适合构建当前进程实际使用的数据集；`train_dataloader()`、`val_dataloader()` 等负责返回对应 DataLoader。
- TorchMetrics 推荐按 train/val/test 分别建立实例，例如 `self.train_acc`、`self.val_acc`，因为 Metric 是有状态的；不要让训练和验证共享同一个状态对象。多个指标可用 `MetricCollection` 统一管理，并通过 `.clone(prefix="train_")`、`.clone(prefix="val_")` 复制。
- `self.log()` 是 Lightning 的通用指标记录方式。训练 loss 常见 `on_step=True, on_epoch=True`；验证指标常见 `on_step=False, on_epoch=True`。DDP 下如果记录的是普通 scalar 且需要跨 rank 聚合，可考虑 `sync_dist=True`；使用 TorchMetrics 时应优先依赖 Metric 本身的分布式状态管理，避免重复同步。
- 常见训练 Hooks：`on_train_start()` 整个训练开始一次；`on_train_epoch_start()` 每个训练 epoch 开始；`on_train_batch_start()` / `on_train_batch_end()` 每个 batch 前后；`on_train_epoch_end()` 每个 epoch 结束；validation/test 具有对应生命周期 Hook。
- 梯度调试 Hooks：`on_before_backward(loss)` 在 backward 前；`on_after_backward()` 在梯度计算后；`on_before_optimizer_step(optimizer)` 在 optimizer 更新前，可用于 gradient norm、NaN 检测、梯度统计等。不要默认认为每个 `on_train_batch_end()` 都对应一次 optimizer step，因为梯度累积时多个 batch 才执行一次更新。
- Checkpoint Hooks：`on_save_checkpoint(checkpoint)` 可向 checkpoint 添加自定义状态，`on_load_checkpoint(checkpoint)` 用于恢复；这和 `ModelCheckpoint` 的职责不同——前者决定“额外保存什么”，后者决定“什么时候保存、保留哪些文件”。
- `Trainer` 常见参数可按五类记忆：训练长度 `max_epochs`、`max_steps`、`limit_train_batches`；设备 `accelerator`、`devices`、`num_nodes`；并行 `strategy`；数值与优化 `precision`、`accumulate_grad_batches`、`gradient_clip_val`；训练辅助 `callbacks`、`logger`、`log_every_n_steps`、checkpoint/progress bar 等。
- 梯度累积时，近似有效全局 batch size 为 `per_device_batch_size × devices × num_nodes × accumulate_grad_batches`。扩展到多机多卡后，学习率和优化超参数是否需要随 global batch 调整，应根据具体算法验证。
- 多机 DDP 的 Lightning 侧配置示例为 `Trainer(accelerator="gpu", devices=4, num_nodes=2, strategy="ddp")`；真正启动通常由 torchrun 或 SLURM 完成。可把职责理解为：Lightning 管训练流程与 strategy，PyTorch Distributed 管 process group，NCCL 管 NVIDIA GPU 间通信，torchrun/SLURM 管进程启动与 rank 环境。
- W&B 基本配合方式：创建 `WandbLogger` 后传给 Trainer，LightningModule 继续正常使用 `self.log()`；图片、表格、视频等复杂对象可以使用 `self.logger.log_image(...)` 或 `self.logger.experiment.log(...)`。如果配置 `WandbLogger(log_model=True)`，还可以和 `ModelCheckpoint` 配合追踪模型 artifact。
- Lightning 支持多个 Logger，例如同时传 `[TensorBoardLogger(...), WandbLogger(...)]`，从而一份 `self.log()` 同时写入本地 TensorBoard 和 W&B。
- `ModelCheckpoint` 最常见的最佳模型保存方式是 `ModelCheckpoint(monitor="val_loss", mode="min", save_top_k=1或3, save_last=True)`。`best` 适合最终测试/推理，`last` 适合训练中断后的恢复；二者通常不是同一个 epoch。
- `save_top_k=1` 只保留最佳一个，`save_top_k=3` 保留前三，`save_top_k=-1` 保存所有触发的 checkpoint，`save_top_k=0` 不做 top-k 保存。长期训练时应谨慎使用 `-1`，避免磁盘被快速写满。
- Checkpoint 可按 epoch、step 或其他触发条件保存，例如 `every_n_epochs=5`、`every_n_train_steps=1000`。也可以同时设置多个 `ModelCheckpoint` Callback，例如一个保存 best，一个每 10 epoch 做周期备份。
- 断点续训使用 `trainer.fit(model, datamodule=data, ckpt_path=".../last.ckpt")`，它会恢复模型、optimizer、scheduler、epoch/global step 等训练状态；单纯 `load_state_dict()` 一般只恢复模型权重。
- 推理/测试可使用 `MyLightningModule.load_from_checkpoint("best.ckpt")`，也可在当前 Trainer/ModelCheckpoint 上使用 `trainer.test(..., ckpt_path="best")`。训练后可以读取 `checkpoint_callback.best_model_path` 和 `best_model_score`。
- `trainer.save_checkpoint("manual.ckpt")` 表示立即手工保存；`ModelCheckpoint` 表示训练过程中按规则自动保存；`on_save_checkpoint()` 表示定义额外状态写入 checkpoint，三者应明确区分。
- Hydra-Lightning 中 `_target_` 指向实际 Python 类，例如模型配置可写 `_target_: src.models.xxx.MyLitModule`，然后通过 `hydra.utils.instantiate(cfg.model)` 创建对象。
- Hydra 的 `_partial_: true` 常用于 optimizer/scheduler，因为它们需要等模型参数准备好后再真正创建。例如 YAML 先定义 AdamW 的 lr/weight_decay，在 `configure_optimizers()` 中再把 `self.parameters()` 传进去完成实例化。
- `defaults` 用于配置组合，例如 `data: mnist`、`model: resnet`、`trainer: gpu`、`logger: wandb`；`${paths.data_dir}` 等写法用于 OmegaConf/Hydra 插值；CLI 可直接覆盖任意配置，例如 `python src/train.py trainer.max_epochs=200 model.optimizer.lr=1e-4`。
- `configs/experiment/` 是科研项目中特别值得保留的设计：把 baseline、proposed、ablation 等实验写成独立 YAML，通过 `experiment=xxx` 一次性覆盖 data/model/trainer/optimizer 等配置。这样实验定义可以直接进入 Git 版本控制，而不是反复修改 Python。
- Hydra multirun 可通过 `-m` 组合多个参数，例如一次运行多个模型、多个 lr。大规模搜索时建议同时使用稳定的输出目录、明确的随机种子、W&B/MLflow 等实验追踪，以及失败 trial 的异常处理策略。
- `@task_wrapper` 的逻辑可以理解为给 `train()` 外层加上 `try → 执行任务 → except 记录异常并重新抛出 → finally 清理 W&B/打印输出目录`。它解决的是整个任务级别的工程问题，而不是模型训练生命周期内部的问题。
- `@hydra.main`、`@task_wrapper`、`Trainer`、Hook/Callback 可以按层级理解：`@hydra.main` 负责生成最终 cfg；`@task_wrapper` 负责包住整个任务；`Trainer` 负责运行训练；Hook/Callback 负责 Trainer 生命周期内部的扩展。

## Common Pitfalls

- 不要把 Lightning 理解为替代 PyTorch。LightningModule 仍然建立在 PyTorch Module、Tensor、Autograd、Optimizer 之上；它主要解决训练流程与工程组织问题。
- 不要认为 `LightningDataModule` 是必需的。小项目可以直接传 DataLoader；当数据逻辑复杂、需要 train/val/test/predict 统一管理、多 GPU 或多实验复用时再使用 DataModule 更有价值。
- 不要把 `forward()` 和 `training_step()` 混为一谈。`forward()` 定义模型普通前向计算，`training_step()` 定义一个训练 batch 如何算 loss/metric；Trainer 驱动训练时主要依赖 `training_step()`。
- 不要把 TorchMetrics 当成 loss。Loss 参与 backward 和优化；Metric 主要用于评价和日志。Metric 通常不参与梯度计算。
- 不要让 train/val/test 共用一个有状态 TorchMetrics 实例，否则统计状态可能互相污染。即便某些调用模式看起来暂时正常，也不利于维护和分布式一致性。
- 不要在使用 `self.log()` 后又无必要手动 `wandb.log()` 记录同一个指标；应保持一个统一的 step 语义。只有图片、表格、自定义 artifact 等 Lightning 标准 scalar logging 不适合表达的内容再直接调用 W&B API。
- 不要把 Hook 和 Callback 看成对立概念。Hook 是生命周期插槽，Callback 是实现多个 Hook 的独立对象；一个相同名字的 Hook 可以同时存在于 LightningModule 和 Callback 中。
- 复杂、可复用、与模型本身弱耦合的功能应优先放 Callback，例如 checkpoint、early stopping、lr monitoring、可视化；强依赖算法内部状态的逻辑才更适合写在 LightningModule Hook 中。
- 使用梯度累积时，不要用“每个 batch 都 optimizer.step()”的思维理解训练；这会导致对 Hook 时序、global batch size 和 LR 的判断出错。
- DDP 多机训练不是只设置 `num_nodes` 就完成。必须确保网络连通、主节点地址与端口正确、所有节点的软件/代码/数据路径一致，并由 torchrun/SLURM 等方式正确启动各 rank。
- 多 GPU 下 `devices` 通常是每节点设备数；总 GPU 数应结合 `num_nodes` 计算。混淆这两个概念会导致错误的 global batch size 和 world size 判断。
- `sync_dist=True` 会引入额外通信开销，不应对所有日志无差别开启。对 TorchMetrics 要理解它自身的 distributed aggregation 机制，避免重复 reduce。
- Checkpoint 中的 `best` 和 `last` 用途不同：best 用于模型选择，last 用于恢复训练。只保存 best 而没有 last，训练在一个较差但更靠后的 epoch 中断时会丢掉最新 optimizer/scheduler 状态。
- `save_top_k=-1` 在大模型或长期训练中可能快速耗尽磁盘；应结合保存频率和单个 ckpt 大小提前估算存储需求。
- `load_from_checkpoint()` 与 `trainer.fit(..., ckpt_path=...)` 不应混淆。前者更偏向重建模型并加载 checkpoint，后者用于让 Trainer 恢复完整训练状态并继续训练。
- 如果 LightningModule 的构造参数复杂，建议使用 `self.save_hyperparameters()`，否则 `load_from_checkpoint()` 时可能需要手工补充初始化参数。
- Hydra 的 `_target_` 是导入路径字符串，重构 Python 模块路径后必须同步修改 YAML，否则运行时实例化会失败。
- optimizer 使用 `_partial_: true` 时，要明确它返回的是“待补充参数的构造器/partial”，而不是已经创建好的 optimizer；真正实例化通常在 `configure_optimizers()` 中完成。
- Hydra 配置不要过度碎片化。模板本身配置非常完整，但自己的项目应从 data/model/trainer/callbacks/logger/experiment 几个核心组开始，避免为了“像模板”而增加过度抽象。
- 使用 Hydra 时要注意运行目录和相对路径语义。推荐统一通过 `${paths...}`、`${hydra:runtime.output_dir}` 或明确的项目根目录构造路径，不要在代码里散落 `/home/...` 绝对路径。
- Hydra multirun 和超参数搜索中，一个 trial OOM 或配置错误可能中断整体流程；`task_wrapper` 的异常处理策略、搜索框架的失败容忍配置和资源释放方式应提前设计。
- `@task_wrapper` 捕获异常后通常还会重新 `raise`，因此它不是“吞掉错误继续训练”的装饰器；如果希望超参数搜索跳过失败 trial，需要结合搜索框架本身的失败处理策略。
- Lightning、Hydra、TorchMetrics 的 API 都会随版本演进，社区模板代码不应机械照搬。遇到参数名、Hook 签名或 import 路径差异时应优先查看当前安装版本的官方文档。

## Useful Resources

- Lightning 官方文档：`https://lightning.ai/docs/pytorch/stable/`，重点可继续阅读 LightningModule、Trainer、Hooks、Callbacks、Checkpointing、Distributed Training 和 Loggers。
- TorchMetrics 官方文档：`https://lightning.ai/docs/torchmetrics/stable/`，重点关注 Metric 基类、分类指标、MetricCollection、分布式同步以及与 Lightning 的集成。
- W&B Lightning 集成文档：`https://docs.wandb.ai/guides/integrations/lightning/`，适合继续学习 scalar、image、table、artifact、model checkpoint tracking 与 offline mode。
- Hydra 官方文档：`https://hydra.cc/docs/`，重点建议继续掌握 Config Groups、Defaults List、Overrides、Instantiation、Multirun、Sweep 和 Working Directory。
- OmegaConf 官方文档：`https://omegaconf.readthedocs.io/`，用于理解 `${...}` 插值、DictConfig/ListConfig、resolver 和结构化配置。
- lightning-hydra-template GitHub：`https://github.com/ashleve/lightning-hydra-template`，建议优先阅读 `configs/train.yaml`、`src/train.py`、`src/utils/utils.py`、model/data/trainer/logger/callbacks 配置目录，以及 `experiment/` 下的实验覆盖方式。
- PyTorch Distributed 官方文档：`https://pytorch.org/docs/stable/distributed.html`，适合理解 Lightning DDP 背后的 process group、rank、world size、collective communication。
- torchrun 文档：`https://pytorch.org/docs/stable/elastic/run.html`，适合真正部署多机训练时理解 `--nnodes`、`--nproc-per-node`、`--node-rank`、master address/port 等启动参数。
- 后续如果继续深入 Lightning，建议按这个顺序学习：`self.log()` 的 `on_step/on_epoch/sync_dist` → `automatic vs manual optimization` → 多 optimizer/scheduler → DDP/FSDP strategy → Callback 自定义 → Checkpoint 恢复细节 → Hydra experiment/multirun → SLURM/torchrun 多机部署。


