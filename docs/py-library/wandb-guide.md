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
- 这里的用法讲解参照[Wandb_Tutorial](https://github.com/OpenRL-Lab/Wandb_Tutorial)对于wandb的介绍，由衷感谢他们的贡献!
- 上面的教程按照基础使用、超参数搜索、数据和模型管理、wandb本地部署四个方向展开，此教程中不会复制项目中的代码，仅标注重点代码部分和基于此的注解
- 第一部分是基础使用，这里介绍了如何用wandb可视化训练曲线、图片、视频、matplotlib画图、表格、多进程group、html和Pytorch集成。
  
  **训练曲线代码**中的一些细节：使用``from pathlib import Path``和``run_dir = Path("../results") / all_args.project_name / all_args.experiment_name`` ``if not run_dir.exists():``等函数简洁地指定wandb.init中的"dir"参数；使用``socket.gethostname()``作为wandb.init中的"help"参数充当实验注释；``args = parser.parse_known_args(args)[0]``和``test_curves(sys.argv[1:])``这两个都将bash参数分成了几段，known函数分开了已定义和未定义的函数，argv[1:]去除了python运行的函数名，因为函数名是第一个参数(用法和普通的argparse不同，等于封装了一层函数，由sys.argv传入参数)；**训练曲线的核心用法是：``wandb.log({"曲线名称": 数值}, step=步数)``**
   
  **图片代码**中的一些细节：引入gym包(OpenAI Gym是一个用于开发和比较强化学习算法的工具包，它提供了一系列标准化的环境(游戏、物理场景模拟等)，让研究者和开发者能够专注于算法本身，gym的核心作用就是提供智能体学习的环境的标准化实现,另外现在使用的是gymnasium)，和前面曲线输出的区别在于，**用``wandb.Image``对需要输出的图像做了一个格式转换，还是可以使用wandb.log({"xxx":xxx},y)这样的形式输出**，这里把图片输出的核心代码贴一下：
  ```python
  import gym
  
  env = gym.make("PongNoFrameskip-v4") # 创建一个Pong游戏，NoFrameskip表示不跳过任何帧
  env.reset()
  for step in range(4): # 共计4组游戏画面
      frames = []
      for i in range(4): # 一组游戏画面中包含4帧
          obs,r,done,_=env.step(env.action_space.sample()) # env.action_space.sample()采样一个随机动作，env.step()执行该运动，返回当前的画面obs，采取此动作的奖励r，是否结束done，额外信息不重要_
          frames.append(wandb.Image(obs, caption="Pong")) # wandb.Image将obs转换为wandb可以显示的图像
      wandb.log({"frames": frames},step=step)
      if done:
          env.reset()
  ```
  **matplotlib代码**中的一些细节：**使用``plt.gcf()``获得当前plt画图的figure对象，``wandb.Plotly()``将plt的figure对象转换为wandb可以显示的图像，同样使用wandb.log({"xxx":xxx},y)这样的形式输出**
  ```python
  x = np.arange(1, 11)
  for step in range(4):
      y = step * x + step
      plt.title("Matplotlib Demo")
      plt.xlabel("x axis caption")
      plt.ylabel("y axis caption")
      plt.plot(x, y)
      wandb.log({"plt":wandb.Plotly(plt.gcf())},step=step)
  ```
  **视频代码**中的一些细节：**利用``gym``来实现视频素材的生成，图片和视频的区别在于时间维度将其合并丢入``wandb.Video``中，还是通过wandb.log({"xxx":xxx},y)实现输出**
  ```python
  import gymnasium as gym
  import ale_py
  
  env = gym.make("PongNoFrameskip-v4")
  for episode in range(3):
      env.reset()
      done = False
      frames = []
      while not done:
          for _ in range(4):
              obs,r,done,_=env.step(env.action_space.sample()) # obs的初始形状为[height, width, channels]
              if done:
                  break
          frames.append(obs) # frames的初始形状为[height, width, channels, time], time在最后一个维度是因为stack的新维度在最后
      sequence = np.stack(frames, -1).transpose(3,2,0,1) # np.stack和np.concatenate的区别在于引入一个指定位置的新维度，np.ndarray.transpose() = torch.tensor.permute()，最终的维度是[time,channels,height,width]
      print(sequence.shape)
      video = wandb.Video(sequence, fps=10, format="gif",caption="Pong")
      wandb.log({"video": video},step=episode)
  ```
  **表格代码**中的一些细节：**通过``wandb.Table(data=xxx,columns=xxx)写入表格数据，之后还是通过``wandb.log()``输出表格内容**
  ```python
  columns = ["Name", "Age", "Score"]

  data = [["ZhuZhu", 1, 0], ["MaoMao",2,1]]
  table = wandb.Table(data=data, columns=columns)
  wandb.log({"table": table})
  wandb.finish()
  ```
  **html文件输出代码**中的一些细节：**通过``wandb.Html()转换html网页文件，这里给出了两种网页引入的方式**
  ```python
  html1 = wandb.Html('<a href="http://tartrl.cn">TARTRL</a>')
  html2 = wandb.Html(open('test.html'))
  wandb.log({"html1": html1,"html2":html2})
  wandb.finish()
  ```
  **多进程group代码**中的一些细节：
- 第二部分是超参数搜索+基于Launchpad实现分布式超参搜索，超参搜索需要几个前提：定义好超参搜索空间
  

## Common Pitfalls
- 避坑指南 + 解决方案

## Useful Resources
- wandb官方文档：[https://docs.wandb.ai/](https://docs.wandb.ai/)
- wandb官方示例库：[https://github.com/wandb/examples](https://github.com/wandb/examples)
- wand官方教学资料：[https://github.com/wandb/edu](https://github.com/wandb/edu)
- 知乎wandb使用教程：[https://www.zhihu.com/column/c_1494418493903155200](https://www.zhihu.com/column/c_1494418493903155200),与其配套的github项目：[https://github.com/OpenRL-Lab/Wandb_Tutorial](https://github.com/OpenRL-Lab/Wandb_Tutorial)
