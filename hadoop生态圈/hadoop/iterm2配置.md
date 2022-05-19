## iterm2

### step1 macOS上配置

1. 安装brew

   ```
   suker@sukerdembp ~ % /bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/ineo6/homebrew-install/install.sh)"
   ```

2. 使用brew安装lrzsz

   ```
   suker@sukerdembp ~ % brew install lrzsz
   ```

3. 下载[iterm2-send-zmodem和iterm2-recv-zmodem](https://github.com/aikuyun/iterm2-zmodem)，把文件移动到/usr/local/bin/

4. 添加可执行权限

   ```
   suker@sukerdembp ~ % chmod +x /usr/local/bin/iterm2-*
   ```

5. 设置iterm触发器

   选择菜单iTerm2->Preferences...->Profiles，配置如下![profile配置](./imgs/test-profiles.png)

   选择test中的Advanced -> Triggers -> edit, 分别添加send和recv规则

   - send配置

     ```
     Regular Expression: \*\*B0100
     Action: Run Silent Coprocess...
     Parameters: /usr/local/bin/iterm2-send-zmodem.sh
     Instant: ✔︎
     ```

   - recv配置

     ```
     Regular Expression: \*\*B00000000000000
     Action: Run Silent Coprocess...
     Parameters: /usr/local/bin/iterm2-recv-zmodem.sh
     Instant: ✔︎
     ```

   ![profiles-triggers配置](./imgs/triggers-profiles.png)

####  step2 centos主机test配置

1. 安装rz、sz命令

   ```
   [root@test ~]# yum install lrzsz   
   ```
   
2. 测试`rz`,`sz`命令

   ```
   #上传命令
   [root@test ~]# rz -y
   #待弹出文件选择框后选择文件
   
   #下载if-cfg-ens33文件命令
   [root@test ~]# sz ifcfg-ens33
   ```

   

