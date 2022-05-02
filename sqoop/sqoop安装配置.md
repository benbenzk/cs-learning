## Sqoop概述

Sqoop是一款开源的工具，主要用于在Hadoop(Hive)与传统的数据库(mysql、 postgresql等)间进行数据的传递。可以将关系型数据库(MySQL, Oracle, Postgres等)中的数据导入到HDFS中，也可以将HDFS的数据导进到关系型数据库中。 

Sqoop项目开始于2009年，最早是作为Hadoop的一个第三方模块存在，后来为了让使用者能够快速部署，也为了让开发人员能够更快速的迭代开发，Sqoop独立成为一个Apache项目。

![sqoop](./imgs/sqoop.png)

将导入或导出命令转换为MapReduce程序来实现。翻译出的MapReduce中主要是对inputformat和outputformat进行定制。

## Sqoop安装配置

Sqoop官网 http://sqoop.apache.org/

Sqoop下载 http://www.apache.org/dyn/closer.lua/sqoop/ 

1. 下载、上传并解压
    将下载的安装包 sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz 上传到虚拟机中; 解压缩软件包; 

   ```
   tar -zxvf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
   mv sqoop-1.4.7.bin__hadoop-2.6.0 /opt/servers/sqoop-1.4.7
   ```

2. 增加环境变量，并使其生效

   ```
   export SQOOP_HOME=/opt/servers/sqoop-1.4.7
   export PATH=$PATH:$SQOOP_HOME/bin
   ```

   生效`source /etc/profile`

3. 创建、修改配置文件

   ```
   #配置目录
   cd $SQOOP_HOME/conf
   cp sqoop-env-template.sh sqoop-env.sh
   vi sqoop-env.sh
   
   # 在文件最后增加以下内容
   export HADOOP_COMMON_HOME=/opt/servers/hadoop-2.9.2/
   export HADOOP_MAPRED_HOME=/opt/servers/hadoop-2.9.2/
   export HIVE_HOME=/opt/servers/hive-2.3.7
   ```

4. 拷贝JDBC驱动程序

   ```
   #拷贝jdbc驱动到sqoop的lib目录下（备注：建立软链接也可以）
   ln -s /opt/servers/hive-2.3.7/lib/mysql-connector-java-8.0.16.jar /opt/servers/sqoop-1.4.7/lib/
   ```

5. 拷贝jar

   - 将`$HIVE_COMMON/lib`下的hive-common-2.3.7.jar拷贝到`$SQOOP_HOME/lib`目录下。如不拷贝在MySQL往Hive导数据的时候将会出现错误: ClassNotFoundException: org.apache.hadoop.hive.conf.HiveConf

     ```
     # 硬拷贝 和 建立软链接都可以，选择一个执行即可。下面是硬拷贝
     cp $HIVE_HOME/lib/hive-common-2.3.7.jar $SQOOP_HOME/lib
     
     #建立软链接
     ln -s $HIVE_HOME/lib/hive-common-2.3.7.jar $SQOOP_HOME/lib/hive-common-2.3.7.jar
     ```

   - 将`$HADOOP_HOME/share/hadoop/tools/lib/json-20170516.jar`拷贝到`$SQOOP_HOME/lib/`目录下;否则在创建sqoop job时会报: java.lang.NoClassDefFoundError: org/json/JSONObject 

     ```
     cp $HADOOP_HOME/share/hadoop/tools/lib/json-20170516.jar $SQOOP_HOME/lib
     ```

   - 安装验证

     ```
     [root@bigdata03 ~]# sqoop version
     ......
     Please set $ZOOKEEPER_HOME to the root of your Zookeeper installation.
     22/05/02 03:36:39 INFO sqoop.Sqoop: Running Sqoop version: 1.4.7
     Sqoop 1.4.7
     git commit id 2328971411f57f0cb683dfb79d19d4d19d185dd8
     Compiled by maugli on Thu Dec 21 15:59:58 STD 2017
     
     # 测试Sqoop是否能够成功连接数据库
     [root@bigdata03 ~]# sqoop list-databases --connect jdbc:mysql://bigdata03:3306/?userSSL=false --username hive --password 123456
     ......
     Loading class `com.mysql.jdbc.Driver'. This is deprecated. The new driver class is `com.mysql.cj.jdbc.Driver'. The driver is automatically registered via the SPI and manual loading of the driver class is generally unnecessary.
     mysql
     information_schema
     performance_schema
     sys
     hivemetadata
     hue
     ```

     