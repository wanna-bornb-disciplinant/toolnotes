## Tool Overview
- ChatGPT对wandb的总结：**它是一个帮你记录、管理、可视化整个机器学习生命周期的工具。** wandb可以帮助记录与可视化训练过程，管理实验与对比，保存与版本化数据和模型，构建可视化分析界面，部署与推理监控
- 以下是wandb官方文档对其产品的相关介绍：  
  W&B的产品主要分为四个，分别是``W&B Models`` ``W&B Weave`` ``W&B Inference`` ``W&B Training``，其中W&B Models适合从头训练机器学习模型，主要特征为实验过程追踪、超参数优化、模型注册和训练可视化；W&B Weave适合构建LLM应用，主要特征为推理追踪、Prompt(提示词)管理、评估和API及资源成本追踪；W&B Inference适合使用预训练模型的场景，主要特征为托管形式的开源模型管理、API访问和模型测试沙盒；W&B Training适合微调模型，主要特征为创建和部署LORA、利用强化学习自定义模型自适应

## Installation & Setup
- 命令行中设置API—Key的环境变量：
  ```bash
  export WANDB_API_KEY=<your_api_key>
  ```
- wandb是一个Python库，仅需``pip install wandb``即可安装
- 使用前需在wandb官网注册一个账号，并获取账号的私钥，然后在bash等命令行终端中执行``wandb login``即可
- wandb管理实验和项目的单位是``team``和``project``

## Core Usage
- 这里的用法讲解参照

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- wandb官方文档：[https://docs.wandb.ai/](https://docs.wandb.ai/)
- wandb官方示例库：[https://github.com/wandb/examples](https://github.com/wandb/examples)
- wand官方教学资料：[https://github.com/wandb/edu](https://github.com/wandb/edu)
- 知乎wandb使用教程：[https://www.zhihu.com/column/c_1494418493903155200](https://www.zhihu.com/column/c_1494418493903155200),与其配套的github项目：[https://github.com/OpenRL-Lab/Wandb_Tutorial](https://github.com/OpenRL-Lab/Wandb_Tutorial)
- 
