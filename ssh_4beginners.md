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

* 在完成前面的两个操作之后，此后就可以使用ssh命令登录至指定服务器：
  ```bash
  ssh username@server_ip
  ```
## 关于在双4090D服务器上SSH连接方案和主流连接方案不同之处的分析


