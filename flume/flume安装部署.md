## Flume安装部署

官网地址 http://flume.apache.org/

文档地址 http://flume.apache.org/FlumeUserGuide.html

下载地址 http://archive.apache.org/dist/flume/

版本 **1.9.0** 

**安装步骤**

1. 下载软件apache-flume-1.9.0-bin.tar.gz，并上传到 bigdata03上的/opt/software目录下

2. 解压apache-flume-1.9.0-bin.tar.gz到/opt/lagou/servers/目录下，并重命名为flume-1.9.0

   ```shell
   tar -zxvf /opt/software/apache-flume-1.9.0-bin.tar.gz -C /opt/servers/
   mv apache-flume-1.9.0-bin flume-1.9.0
   ```

3. 在/etc/profile中增加环境变量，并执行source /etc/profile，使修改生效

   ```
   export FLUME_HOME=/opt/servers/flume-1.9.0
   export PATH=$PATH:$FLUME_HOME/bin
   ```

4. 将$FLUME_HOME/conf下的 flume-env.sh.template 改名为 flume-env.sh，并添加JAVA_HOME的配置

   ```
   cd $FLUME_HOME/conf
   mv flume-env.sh.template flume-env.sh
   vi flume-env.sh
   ......
   export JAVA_HOME=/opt/servers/jdk1.8
   ```

   