## 基础的SSH连接方案

* 当前ssh的主流连接方式应该是，如果我有一台主机A和服务器B，我希望在A和B之间建立SSH连接，正确的操作是：
  
  A端生成一组SSH密钥，将密钥的公钥```id_rsa_pub```部分发给服务器，在生成密钥和配置SSH服务之后服务器端会有一个```authorized_keys```的文件，将公钥写入到配置文件当中
  
  此时通过SSH进行连接，服务器检测到访问请求后，会去查看他的```authorized_keys```，服务器此时会根据文件当中得到的公钥信息发送一个challenge，使用A的公钥进行加密，这时如果A端的私钥能够使用私钥解决challenge，就可以实现连接

* 上述的基本连接方式有一些具体的细节：

  生成密钥对的代码通常是这样的形式：

  ```bash
  ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
  ```
  生成指令的三个选项的含义分别是-t rsa制定了密钥的类型为RSA，-b 4096制定了密钥的长度为4096位，4096位也是目前比较推荐的高安全性长度，-C "your_email@example.com"为生成的密钥添加了注释，在管理多个密钥时非常实用

  在生成过程中，系统会提示输入一个passphrase，可以输入并确认一个passphrase

  passphrase在之后的SSH登录中都会要求输入，但可以使用```ssh-agent```来缓存相关信息，这样可以免密登录服务器，具体的方法可以自行google

* 在生成密钥对之后的第二步是将密钥对中的公钥发送至B端，通常使用
  ```bash
  ssh-copy-id username@server_ip(B端用户和IP地址)
  ```
  这句指令的本质是一个脚本，它通过SSH协议登录到B端，并执行：使用cat等命令将本地公钥发送至B端，将公钥内容追加至B端的```authorized_keys```中

  如果使用的是Windows系统，会出现“ssh-copy-id命令不存在”的情况。打开powershell，输入如下脚本后，在执行上述ssh-copy-id命令。
  ```bash
  function ssh-copy-id([string]$userAtMachine, $args){   
    $publicKey = "$ENV:USERPROFILE" + "/.ssh/id_rsa.pub"
    if (!(Test-Path "$publicKey")){
        Write-Error "ERROR: failed to open ID file '$publicKey': No such file"            
    }
    else {
        & cat "$publicKey" | ssh $args $userAtMachine "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys || exit 1"      
    }
}
  ```

* 在完成前面的两个操作之后，此后就可以使用ssh命令登录至指定服务器：
  ```bash
  ssh username@server_ip
  ```
## 关于在双4090D服务器上SSH连接方案和主流连接方案不同之处的分析

* 之前在实验室的双EPYC 7763+4090D上实现的SSH连接方案与上述主流的连接方式不同，使用B端的SSH生成密钥指令，将B端的私钥存放在A端，然后使用ssh -i的方式进行登录

* 这种登录方式本身是一种反向用途，因为B端的私钥被放置在了A端，登录本身还是使用私钥进入到公钥的地址的方式，如果使用这样的连接方案连接至B，会存在一定的问题：
  
    1.私钥会有泄露风险
  
    2.无法知道私钥的完整生命周期
  
    3.破坏了私钥只属于当前电脑的规则，SSH协议遵从“客户端私钥保密”的规则

* 但本身这种连接方式也会在一些场景中使用，虽然不推荐

* 还有一个在当时比较困扰笔者的问题：当我在服务器上生成密钥文件时，是针对于单个用户的，因此我把这个密钥对中的私钥发给客户机时，客户机也只能登录对应的用户，使用对应的用户权限，但使用主流的SSH登录方案，密钥对是客户机生成的，这样岂不是就不能选择对应的用户了吗？
  
  思考并实践后的回答是：密钥对和用户本身没有实际关系，但仔细思考服务器每个用户的文件中都会有一个SSH专属的文件夹，当中保存着密钥和authorized_keys等内容，因此，只需要在发送公钥文件时指定B端接收的用户，那么SSH登录后只会连接到接收公钥文件的那个用户

## 关于客户机+跳板机+服务器这样的SSH配置下的基础连接方案

* 假设当前的三机结构如下：
  ```markdown
    客户机（公网） ──SSH──▶ 跳板机（公网IP: 1.2.3.4）
                              │
                              └─SSH──▶ 目标服务器（内网IP: 192.168.0.100）
  ```
  客户机登录跳板机用用户：```user_jump```

  跳板机登录目标服务器用用户：```user_target```

* 基于ProxyJump的方式进行ssh连接可以达到的效果是：
  ```bash
  ssh -J user_jump@1.2.3.4 user_target@192.168.0.100
  ```
  通过两次SSH连接通过跳板机连接至服务器

* 首先在客户机上的操作就是生成SSH密钥对，将公钥文件发送至跳板机和服务器中：
  ```bash
  ssh-copy-id user_jump@1.2.3.4
  ssh user_jump@1.2.3.4
  ssh-copy-id user_target@192.168.0.100
  ```

  在本地配置```~/.ssh/config```文件：
  ```bash
  Host jump
    HostName 1.2.3.4
    User user_jump
    IdentityFile ~/.ssh/id_rsa

  Host target
    HostName 192.168.0.100
    User user_target
    IdentityFile ~/.ssh/id_rsa
    ProxyJump jump
  ```

配置结束后可以达到的效果是：
```bash
ssh target
```

* 其余的必要操作只需保证跳板机能ping或ssh连接至服务器即可，总结基础的三机连接如下：
  ```markdown
  [客户机]
  ├── ~/.ssh/id_rsa / id_rsa.pub
  ├── ~/.ssh/config:
  │   - Host jump
  │   - Host target (ProxyJump jump)

        │
        ▼

  [跳板机]
  ├── user_jump 用户存在
  ├── ~/.ssh/authorized_keys 中包含 客户机的 id_rsa.pub
  ├── 能访问目标服务器（ping/ssh）

        │
        ▼

  [目标服务器]
  ├── user_target 用户存在
  ├── ~/.ssh/authorized_keys 中包含 客户机的 id_rsa.pub

  ```

* 跳板机上建议开启 UFW、防火墙、Fail2Ban

## 额外需要的跳板机方案的高级配置
