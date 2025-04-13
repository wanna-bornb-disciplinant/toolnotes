## 在一个现有的本地项目中如何使用基本的git指令
### 首先这部分的内容是服务于本地的一个代码项目，其初始状态是不对应于github中的一个仓库或项目的，因此以下所有的操作都是在一个类似新的仓库中的

* cmd或git cmd中进入当前项目的目录，第一个命令是
```bash
git status
```
  这个命令帮助查看git仓库的当前状态，在未创建的状态下他会提示没有git仓库，创建完成后会提示当前仓库所在的分支以及commit的状态

* 在一个全新的仓库中，可以初始化创建git仓库
```bash
git init
```
  git init后并不是直接变成了一个完备的git仓库，此时在这个项目中的代码和文件还没有真正的放入到git仓库，在git中称为这些文件并没有被追踪，初始化后调用git status会出现untracked files

* 接下来的两个指令才真正将文件添加到git仓库中
```bash
git add XXX.xx(所有的文件是.)
```
  但实质上，git add并没有把文件提交到git仓库中，而是把文件添加到了[临时缓冲区]，git add能有效防止错误提交的可能性

* 正式提交的指令为：
```bash
git commit -m "xxxx"
```
  git commit指令将上述添加到[临时缓冲区]的文件正式提交到git仓库中，当提交完成后，此时git status就会出现类似
  
  '''On branch master,
  
  nothing to commit, working tree clean'''

* git可以实时的打印提交日志：
```bash
git log
```
  在log中，可以看到提交的ID号，提交的分支名称，作者、时间、commit的附带信息

* git作为分布式版本控制系统最大的特性在于：你可以在不同的分支上并行处理多个功能、修复不同的 bug，互不干扰，在 Git 中创建一个新分支几乎是瞬间完成的，Git 只是创建一个指向某个提交对象（commit）的新指针，不涉及大量数据复制(snapshot+指针)
```bash
git branch
```
  git branch显示了仓库中的分支情况，某个分支前的'''*号'''表示了当前所在的分支，如果将指令改为
```bash
git branch XXX
```
  则会再创建一个branch名为XXX，但当前所在的分支还是之前的

* 在git中进行分支的切换就需要使用到
```bash
git checkout XXX
```
  这个命令会将当前的分支切换为XXX，如果希望同时完成创建加切换这两个操作，可以使用
```bash
git checkout -b XXX
```
* 分支既然能够创建，也可以直接合并，例如当前正处于master分支下，可以
```bash
git merge A
```
  将A的分支直接合并到master下，merge的指令需要保证两个分支上的代码并不互相冲突，是一个需要谨慎操作的指令

* git branch既然可以创建新的分支，当前也可以直接删除掉一些不再维护的分支，可以通过
```bash
git branch -d A
```
  -d的选项代表着删除这个分支，但有时会出现无法删除的情况，例如要删除的分支并没有成功地合并到master分支等等，此时则需要
```bash
git branch -D A
```
-D的选项可以强行删除A这个分支

* git作为一个分布式版本管理系统，不仅可以实现多个分支的管理，也可以在单个分支下实现多个版本的管理
```bash
git tag v1.0
```
上述的指令为当前的分支添加了一个v1.0的标签，此时可以通过再调用'''git tag'''这一指令实现标签记录的查看，既然创建了版本的标签，我们也能通过之前切换分支的指令完成版本之间的切换
```bash
git checkout v1.0
```
## git和github的绑定，上述的基本指令都是在围绕本地的项目和git仓库而言的，但git好用的地方在于还有github这样一个管理代码的平台，因此git和github的绑定也很重要

* 目前github支持的连接方式包括https和ssh，在这里我们选择ssh的安全协议向github提交代码和从github下载代码

* 关于ssh的连接方式详见ssh_4beginners.md当中的部分
