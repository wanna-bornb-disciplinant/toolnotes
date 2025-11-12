## Tool Overview
- ``argparse``是Python标准库，专门用来读取你在终端执行脚本时传入的“命令行参数”，把参数自动转换成变量供代码使用--不用修改代码，就能通过终端灵活调整程序配置。
- ``gin``是Python第三方配置库，核心作用是「参数与代码分离」，通过 .gin 配置文件统一管理实验参数（模型结构、训练超参等），支持参数绑定、动态调整和锁定，适配深度学习项目
- ``loguru``的核心优势是API极简、配置零冗余，所有日志操作都围绕logger实例展开（无需像logging那样创建Logger、Handler、Formatter等一堆对象）

## Installation & Setup
- 从头安装 + 关键配置

## Core Usage
- 单独使用``argparse``的简单说明：
  ```python
    import argparse
    # 1. 创建参数解析器
    parser = argparse.ArgumentParser(description="深度学习训练脚本")
    # 2. 定义可配置参数（指定参数名、默认值、说明）
    parser.add_argument("--lr", type=float, default=0.001, help="学习率")
    parser.add_argument("--batch_size", type=int, default=32, help="批次大小")
    parser.add_argument("--model", type=str, default="ResNet50", help="模型类型")
    # 3. 解析终端传入的参数
    args = parser.parse_args()
    # 4. 代码中直接使用参数
    lr = args.lr
    batch_size = args.batch_size
    print(f"使用学习率：{lr}，批次大小：{batch_size}，模型：{args.model}")
  ```
  ```bash
    python train.py --lr 0.0005 --batch_size 64 --model "ViT"
  ```
- add_argument中比较常见的一些问题例如如何判断一个变量是否在bash中必需；action的常见种类；required参数是否必需等等，都在下面的两个示例中有所展现：
  ```python
    import argparse
  
    parser = argparse.ArgumentParser()
    # 非必须：指定 default 值（不传则用 32）
    parser.add_argument("--batch_size", type=int, default=32, help="批次大小（非必须）")
    # 非必须：没写 default，但 required=False（默认），不传则为 None
    parser.add_argument("--resume", type=str, help="断点续训路径（非必须，不传则不续训）")
    # 非必须：布尔型参数（用 action="store_true"，不传则为 False），这里当然也可以用action="store_false"，情况就会和前面相反
    parser.add_argument("--debug", action="store_true", help="调试模式（非必须，不传则关闭）")
    # 必须：GPU 编号（必须指定用哪块卡，没有默认值）
    parser.add_argument("--gpu", type=int, required=True, help="GPU编号（必须，-1表示CPU）")
    # 必须：运行模式（必须明确是训练/测试，没有默认值）
    parser.add_argument("--mode", type=str, required=True, choices=["train", "val", "test"], help="运行模式（必须）")
  
    args = parser.parse_args()
    print(args.batch_size)  # 不传则输出 32
    print(args.resume)      # 不传则输出 None
    print(args.debug)       # 不传则输出 False
  ```
  ```python
    # 四种常见的action类型

    # action="store"，存储用户传入的参数值（最基础的行为），用户传什么值，args 里就存什么值，store为默认情况
    parser.add_argument("--lr", type=float, default=0.001)  # 默认 action="store"
    parser.add_argument("--data_path", type=str, default="./data")

    # action="store_true/store_false"，不需要用户传具体值，只需要 “传或不传”
    parser.add_argument("--debug", action="store_true", help="调试模式（传了就是True，没传是False）")
    parser.add_argument("--disable_wandb", action="store_true", help="禁用wandb（传了就禁用）")
    parser.add_argument("--use_cpu", action="store_false", dest="use_gpu", help="使用CPU（传了则use_gpu=False）")

    # action="append"，允许用户多次传入同一个参数，值会被存成列表
    parser.add_argument("--gpu_ids", action="append", type=int, help="指定多个GPU（可多次传）")
    parser.add_argument("--pretrain_paths", action="append", type=str, help="多个预训练模型路径")
    # python train.py --gpu_ids 0 --gpu_ids 1 --pretrain_paths "model1.pth" --pretrain_paths "model2.pth"

    # action="count"，统计用户传入该参数的次数，存为整数
    parser.add_argument("-v", "--verbose", action="count", default=0, help="日志详细程度（-v/-vv/-vvv）")
  ```

- gin的一些关键细节：  
  .gin 配置文件前缀含义：前缀（如 model.、train.）是「参数归属标签」，用于隔离不同模块的参数（避免同名冲突），需与代码中 @gin.configurable 装饰的类 / 函数匹配(@gin.configurable("model")这样进行匹配)  
  类与函数在 Gin 中的关系：完全平级 —— 两者通过 @gin.configurable 装饰后，均能接收 Gin 配置参数，匹配规则、参数优先级完全一致，仅参数注入时机不同（类在实例化时，函数在调用时）  
  ``gin.parse_config_file(path)``用于加载单个.gin配置文件    
  ``gin.parse_config(string)``用于临时情况下解析单个字符串格式的参数，如gin.parse_config("trainer.lr=0.001")  
  ``gin.parse_config_file_and_bindings(path,bindings)``用于同时加载多个配置文件和多个临时参数  
  ``gin.bind_parameter(key,value)``用于手动修改单个参数  
  ``gin.finalize()``用于手动锁定所有配置  
  参数优先级高低：gin.bind_parameter() 手动修改 → bindings 临时参数 → 后加载的 .gin 文件 → 前加载的 .gin 文件 → 参数默认值  

- 有了gin这个高效管理参数和配置的工具，我们就可以把argparse的部分管理内容下放给gin使用了：
  ```gin
    # config.gin
    train.batch_size = 32
    train.lr = 0.001
    model.num_layers = 12
    model.dropout = 0.1
  ```
  ```python
    import argparse
    import gin
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--gin_config", type=str, default="config.gin", help="gin配置文件路径")
    parser.add_argument("--gpu", type=int, default=0, help="GPU编号")
    args = parser.parse_args()
    
    # 加载gin配置文件
    gin.parse_config_file(args.gin_config)
    
    # 代码中使用gin绑定的参数
    @gin.configurable  # 自动从gin配置中读取参数
    def train(batch_size, lr):
        print(f"batch_size: {batch_size}, lr: {lr}")
    
    train()  # 不用传参，gin自动注入
  ```

- loguru内置多个核心日志级别(从低到高)，对应不同场景，用法完全一致(仅语义和颜色不同):    
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.trace() 最详细的调试信息（比如函数调用栈）    
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.debug() 调试信息（比如参数值、中间结果）  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.info() 正常运行信息（比如训练开始 / 结束）  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.success() 操作成功（比如模型保存、训练完成）  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.warning() 警告（比如参数过时、资源不足）  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.error() 错误（比如加载文件失败、维度不匹配）  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;logger.critical()	 致命错误（比如内存溢出、程序崩溃）
  ``` python
    from loguru import logger
    import time
    
    # 1. 基础日志输出（直接调用对应级别函数）
    logger.trace("进入 train() 函数，开始初始化模型...")
    logger.debug("调试参数：lr=0.001, batch_size=32")
    logger.info("训练开始：总轮数 50，使用 GPU 0")
    
    # 模拟训练过程
    for epoch in range(3):
        time.sleep(0.5)
        if epoch == 2:
            logger.success(f"第 {epoch+1} 轮训练完成！准确率：89.2%")
        else:
            logger.info(f"第 {epoch+1} 轮训练完成！准确率：{80+epoch}%")
    
    # 模拟异常场景
    try:
        model.load_state_dict(torch.load("wrong_path.pth"))
    except FileNotFoundError as e:
        logger.error(f"模型加载失败：{e}", exc_info=True)  # exc_info=True 显示异常堆栈
    
    logger.critical("致命错误：GPU 显存不足（需要 16GB，实际 8GB），程序终止！")
  ```
  
- loguru中logger.add()的细节：  
  logger.add() 是 loguru 最核心的配置函数，用于指定日志 “输出到哪里”“怎么存”“格式是什么”，支持链式调用，一次可配置多个输出目标。
  ```python
    from loguru import logger
    import sys
    
    # 配置 2 个输出目标：① 终端 ② 文件（带滚动+压缩+保留）
    logger.add(
        sink=sys.stderr,  # 输出到终端（默认已开启，这里可自定义格式）
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {module}:{name}:{line} | {message}",
        level="INFO"  # 终端只输出 INFO 及以上（避免 DEBUG 刷屏）
    ).add(
        sink="./logs/train_{time:YYYYMMDD}.log",  # 输出到文件（文件名带日期）
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
        level="DEBUG",  # 文件输出 DEBUG 及以上（方便调试回溯）
        rotation="500 MB",  # 单个文件 500MB 滚动
        retention=30,  # 保留 30 天日志
        compression="gz",  # 旧日志 gzip 压缩
        encoding="utf-8"  # 支持中文
    )
    
    # 之后的日志会同时输出到终端和文件
    logger.debug("调试信息：数据集加载完成，共 10000 样本")
    logger.info("训练开始：学习率 0.001，批次大小 64")
    logger.success("模型保存成功：./checkpoints/epoch_10.pth")
    logger.error("数据增强失败：图片路径不存在")
  ```

- 三个库如何配合使用的一个示例(这里的示例使用了wandb可视化一些配置和训练的效果)：
  ```bash
    pip install wandb
    wandb login
  ```
  ```gin
    # ==================== wandb 配置（gin 管理）====================
    wandb.log_interval = 5          # 每 5 步记录一次指标
    wandb.save_model = True         # 是否在 wandb 保存模型权重
    wandb.save_code = True          # 是否上传代码快照（方便复现）
    wandb.note = "ResNet 基础训练，学习率 0.001"  # 实验备注
    
    # ==================== 原有配置（模型/训练/数据）====================
    model.num_layers = 12
    model.dropout = 0.1
    train.lr = 0.001
    train.batch_size = 32
    train.epochs = 10
    data.image_size = 224
  ```
  ```python
    from loguru import logger
    import argparse
    import gin
    import wandb
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import DataLoader, TensorDataset
    
    # ---------------------- 1. argparse 配置（控制 wandb 核心开关）----------------------
    parser = argparse.ArgumentParser(description="argparse+gin+loguru+wandb 集成示例")
    # 原有 argparse 参数（gin 配置文件、GPU 等）
    parser.add_argument("--gin_files", type=str, nargs="*", default=["./config.gin"], help="gin 配置文件路径")
    parser.add_argument("--gpu", type=int, default=0, help="GPU 编号")
    # wandb 核心参数（终端动态切换，无需写进 gin）
    parser.add_argument("--use_wandb", action="store_true", default=True, help="是否启用 wandb 可视化")
    parser.add_argument("--wandb_project", type=str, default="ResNet-Training", help="wandb 项目名")
    parser.add_argument("--wandb_run_name", type=str, default=None, help="实验运行名（默认自动生成）")
    parser.add_argument("--wandb_entity", type=str, default=None, help="wandb 团队/个人名（官网设置）")
    args = parser.parse_args()
    
    # ---------------------- 2. loguru 配置（终端+文件日志，同步到 wandb）----------------------
    import sys
    # 配置终端输出（INFO 及以上）
    logger.add(
        sink=sys.stderr,
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {module}:{line} | {message}",
        level="INFO"
    )
    # 配置文件输出（DEBUG 及以上，滚动+压缩）
    logger.add(
        sink="./logs/train_{time:YYYYMMDD}.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
        level="DEBUG",
        rotation="500 MB",
        retention=7,
        compression="gz",
        encoding="utf-8"
    )
    
    # ---------------------- 3. gin 加载配置（包括 wandb 细节参数）----------------------
    gin.parse_config_files_and_bindings(
        config_files=args.gin_files,
        bindings=[],
        final_config=True  # 锁定配置，避免后续修改
    )
    # 从 gin 中读取 wandb 细节参数（gin 管理，无需终端传）
    wandb_log_interval = gin.query_parameter("wandb.log_interval")
    wandb_save_model = gin.query_parameter("wandb.save_model")
    wandb_save_code = gin.query_parameter("wandb.save_code")
    wandb_note = gin.query_parameter("wandb.note")
    # 从 gin 中读取其他核心参数
    num_layers = gin.query_parameter("model.num_layers")
    dropout = gin.query_parameter("model.dropout")
    lr = gin.query_parameter("train.lr")
    batch_size = gin.query_parameter("train.batch_size")
    epochs = gin.query_parameter("train.epochs")
    
    # ---------------------- 4. wandb 初始化（根据 argparse 开关控制）----------------------
    if args.use_wandb:
        # 初始化 wandb（核心配置来自 argparse，细节参数来自 gin）
        run = wandb.init(
            project=args.wandb_project,
            name=args.wandb_run_name,  # 实验名（如 "resnet-lr-0.001-batch-32"）
            entity=args.wandb_entity,
            notes=wandb_note,  # 实验备注（来自 gin）
            save_code=wandb_save_code,  # 上传代码快照（来自 gin）
            config=gin.config._CONFIG  # 关键：将所有 gin 配置同步到 wandb（自动展示在 config 面板）
        )
        # 将 loguru 日志同步到 wandb（wandb 日志面板可查看）
        logger.add(
            sink=lambda msg: wandb.log({"log": msg}),  # 自定义 sink，将日志写入 wandb
            format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {message}",  # wandb 日志格式
            level="INFO"  # 仅同步 INFO 及以上日志，避免刷屏
        )
        logger.success("wandb 初始化成功！项目名：{}，实验名：{}".format(args.wandb_project, run.name))
    else:
        logger.warning("未启用 wandb，仅记录本地日志")
    
    # ---------------------- 5. 深度学习核心逻辑（模型/训练/指标记录）----------------------
    # 设备配置
    device = torch.device(f"cuda:{args.gpu}" if torch.cuda.is_available() else "cpu")
    logger.info(f"使用设备：{device}，模型层数：{num_layers}，学习率：{lr}")
    
    # 模拟模型、数据集（实际项目替换为真实代码）
    class SimpleResNet(nn.Module):
        @gin.configurable("model")  # 绑定 gin model. 前缀参数
        def __init__(self, num_layers, dropout):
            super().__init__()
            self.layers = nn.Sequential(*[nn.Linear(10, 10) for _ in range(num_layers)])
            self.dropout = nn.Dropout(dropout)
            self.fc = nn.Linear(10, 2)
        def forward(self, x):
            return self.fc(self.dropout(self.layers(x)))
    
    # 初始化模型、优化器、损失函数
    model = SimpleResNet().to(device)
    optimizer = optim.Adam(model.parameters(), lr=lr)
    criterion = nn.CrossEntropyLoss()
    
    # 模拟数据集（1000 样本，输入维度 10，输出 2 分类）
    x = torch.randn(1000, 10).to(device)
    y = torch.randint(0, 2, (1000,)).to(device)
    dataset = TensorDataset(x, y)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
    
    # 训练循环（关键：用 wandb 记录指标）
    logger.info("开始训练！总轮数：{}，批次大小：{}".format(epochs, batch_size))
    for epoch in range(epochs):
        model.train()
        total_loss = 0.0
        total_acc = 0.0
        for step, (batch_x, batch_y) in enumerate(dataloader):
            optimizer.zero_grad()
            outputs = model(batch_x)
            loss = criterion(outputs, batch_y)
            loss.backward()
            optimizer.step()
    
            # 计算指标
            total_loss += loss.item()
            acc = (outputs.argmax(dim=1) == batch_y).float().mean().item()
            total_acc += acc
    
            # 每 log_interval 步记录指标到 wandb（来自 gin 配置）
            global_step = epoch * len(dataloader) + step
            if step % wandb_log_interval == 0:
                logger.debug(f"Epoch [{epoch+1}/{epochs}], Step [{step}/{len(dataloader)}], Loss: {loss.item():.4f}, Acc: {acc:.4f}")
                if args.use_wandb:
                    wandb.log({
                        "train/loss_step": loss.item(),
                        "train/acc_step": acc,
                        "global_step": global_step
                    })
    
        # 每轮结束记录全局指标
        avg_loss = total_loss / len(dataloader)
        avg_acc = total_acc / len(dataloader)
        logger.success(f"Epoch [{epoch+1}/{epochs}] 完成！平均 Loss: {avg_loss:.4f}，平均 Acc: {avg_acc:.4f}")
        if args.use_wandb:
            wandb.log({
                "train/loss_epoch": avg_loss,
                "train/acc_epoch": avg_acc,
                "epoch": epoch+1
            })
    
            # 保存模型到 wandb（来自 gin 配置的开关）
            if wandb_save_model and (epoch+1) % 5 == 0:  # 每 5 轮保存一次
                checkpoint = {
                    "epoch": epoch+1,
                    "model_state_dict": model.state_dict(),
                    "optimizer_state_dict": optimizer.state_dict(),
                    "loss": avg_loss
                }
                wandb.log_artifact(
                    artifact_or_path=checkpoint,
                    name=f"model-epoch-{epoch+1}",
                    type="model",
                    metadata={"epoch": epoch+1, "loss": avg_loss, "acc": avg_acc}
                )
                logger.info(f"模型已保存到 wandb：model-epoch-{epoch+1}")
    
    # 训练结束，关闭 wandb
    if args.use_wandb:
        wandb.finish()
    logger.success("训练全部完成！")
  ```

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- 官方文档、推荐教程、插件链接

