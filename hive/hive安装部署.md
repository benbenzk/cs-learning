## Hive安装部署

安装前提：3台已安装了hadoop的虚拟机

安装软件：Hive(2.3.7) + MySQL(8.0.16)

备注：Hive的元数据默认存储在自带的derby数据库中，生产用多采用MySQL

| 软件   | Bigdata01 | bigdata02 | bigdata03 |
| ------ | --------- | --------- | --------- |
| Hadoop | ✔️         | ✔️         | ✔️         |
| MySQL  |           |           | ✔️         |
| Hive   |           |           | ✔️         |

>Hive安装包 - apache-hive-2.3.7-bin.tar.gz
>
>MySQL安装包 - mysql-8.0.16-2.el7.aarch64.rpm-bundle.tar
>
>MySQL的JDBC驱动程序 - mysql-connector-java-8.0.16.jar
>
>**安装步骤**
>
>1、安装MySQL
>
>2、安装配置Hive
>
>3、Hive添加常用配置

### 第1步：MySQL安装

> **安装步骤**
> 1、环境准备(删除有冲突的依赖包、安装必须的依赖包) 
> 2、安装MySQL 
> 3、修改root口令(找到系统给定的随机口令、修改口令) 
> 4、在数据库中创建hive用户

1. 删除mariadb

   ```shell
   [root@bigdata03 ~]# rpm -qa | grep mariadb
   mariadb-libs-5.5.68-1.el7.aarch64
   [root@bigdata03 ~]# rpm -e --nodeps mariadb-libs-5.5.68-1.el7.aarch64
   ```

2. 安装依赖

   ```
   yum install -y perl
   yum install -y net-tools
   ```

3. 安装MySQL

   ```shell
   cd /opt/soft/
   tar xvf mysql-8.0.16-2.el7.aarch64.rpm-bundle.tar
   rpm -ivh mysql-community-common-8.0.16-2.el7.aarch64.rpm
   rpm -ivh mysql-community-libs-8.0.16-2.el7.aarch64.rpm
   rpm -ivh mysql-community-client-8.0.16-2.el7.aarch64.rpm
   rpm -ivh mysql-community-server-8.0.16-2.el7.aarch64.rpm
   ```

4. 启动数据库

   ```shell
   #启动
   systemctl start mysqld.service
   #开机启动
   systemctl enable mysqld.service
   ```
   
5. 查找root密码

   ```shell
   grep password /var/log/mysqld.log
   ```

6. 修改root口令

   ```
   #进入MySQL，使用前面查询到的口令
   mysql -u root -p
   # 设置口令强度;将root口令设置为123456;刷新
   mysql> set global validate_password.policy=0;
   mysql> set global validate_password.length=1;
   mysql> alter user root@localhost identified by '123456';
   mysql> flush privileges;
   ```

7. 创建hive用户

   ```
   -- 创建用户设置口令、授权、刷新
   CREATE USER 'hive'@'%' IDENTIFIED BY '123456';
   GRANT ALL ON *.* TO 'hive'@'%';
   FLUSH PRIVILEGES;
   ```

### 第2步：Hive安装

> 安装步骤
>
> 1. 下载、上传、解压缩 
> 2. 修改环境变量
> 3. 修改hive配置
> 4. 拷贝JDBC的驱动程序
> 5. 初始化元数据库

1. 解压缩

   ```
   cd /opt/software/
   tar zxvf apache-hive-2.3.7-bin.tar.gz -C /opt/servers/
   cd /opt/servers/
   mv apache-hive-2.3.7-bin hive-2.3.7
   ```

2. 修改环境变量

   ```
   #在/etc/profile文件中增加环境变量
   export HIVE_HOME=/opt/servers/hive-2.3.7
   export PATH=$PATH:$HIVE_HOME/bin
   ```

   执行`source /etc/profile`使环境变量生效

3. 修改Hive配置

   ```
   [root@bigdata03 ~]# cd $HIVE_HOME/conf
   [root@bigdata03 conf]# vi hive-site.xml
   ```

   ```xml
   <?xml version="1.0" encoding="UTF-8" standalone="no"?>
   <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
   <configuration>
     <!-- hive元数据的存储位置 -->
     <property>
       <name>javax.jdo.option.ConnectionURL</name>
       <value>jdbc:mysql://bigdata03:3306/hivemetadata?createDatabaseIfNotExist=true&amp;useSSL=false&amp;allowPublicKeyRetrieval=true&amp;serverTimezone=Asia/Shanghai</value>
       <description>JDBC connect string for a JDBC metastore</description>
     </property>
     <!-- 指定驱动程序 -->
     <property>
       <name>javax.jdo.option.ConnectionDriverName</name>
       <value>com.mysql.cj.jdbc.Driver</value>
       <description>Driver class name for a JDBC metastore</description>
     </property>
     <!-- 连接数据库的用户名 -->
     <property>
       <name>javax.jdo.option.ConnectionUserName</name>
       <value>hive</value>
       <description>username to use against metastore database</description>
     </property>
     <!-- 连接数据库的口令 -->
     <property>
       <name>javax.jdo.option.ConnectionPassword</name>
       <value>123456</value>
       <description>password to use against metastore database</description>
     </property>
   </configuration>
   ```

   > 注意
   >
   > jdbc的连接串，如果没有useSSL=false会有大量警告
   >
   > 在xml文件中`&amp;`表示`&`

4. 拷贝MySQL JDBC驱动程序

   将mysql-connector-java-8.0.16.jar拷贝到$HIVE_HOME/lib

5. 初始化元数据库

   ```
   [root@bigdata03 ~]# schematool -dbType mysql -initSchema
   ......
   Metastore connection URL:	 jdbc:mysql://bigdata03:3306/hivemetadata?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=Asia/Shanghai
   Metastore Connection Driver :	 com.mysql.cj.jdbc.Driver
   Metastore connection User:	 hive
   Starting metastore schema initialization to 2.3.0
   Initialization script hive-schema-2.3.0.mysql.sql
   Initialization script completed
   schemaTool completed
   ```

6. 启动Hive，执行命令

   ```
   # 启动hive服务之前，请先启动hdfs、yarn的服务
   [root@bigdata03 ~]# hive
   hive> show functions;
   ```

### 第3步：Hive属性设置

可在hive-site.xml中增加以下常用配置

#### 数据存储位置

```xml
  <!-- 数据默认的存储位置(HDFS) -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
    <description>location of default database for the warehouse</description>
  </property>
```

#### 显示当前库

```xml
  <!-- 在命令行中，显示当前操作的数据库 -->
  <property>
    <name>hive.cli.print.current.db</name>
    <value>true</value>
    <description>Whether to include the current database in the Hive prompt.</description>
  </property>
```

#### 显示表头属性

```xml
  <!-- 在命令行中，显示数据的表头 -->
  <property>
    <name>hive.cli.print.header</name>
    <value>true</value>
  </property>
```

#### 本地模式

```xml
  <!-- 操作小规模数据时，使用本地模式，提高效率 -->
  <property>
    <name>hive.exec.mode.local.auto</name>
    <value>true</value>
    <description>Let Hive determine whether to run in local mode automatically</description>
  </property>
```

当 Hive的输入数据量非常小时，Hive通过本地模式在单台机器上处理所有的任务。对于小数据集，执行时间会明显被缩短。

当一个job满足如下条件才能真正使用本地模式：

job的输入数据量必须小于参数:hive.exec.mode.local.auto.inputbytes.max (默认128MB) 

job的map数必须小于参数:hive.exec.mode.local.auto.tasks.max (默认4) 

job的reduce数必须为0或者1 

#### 日志配置

进入hive命令行的日志如下

```
which: no hbase in (.:.:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/opt/servers/jdk1.8/bin:/opt/servers/hadoop-2.9.2/bin:/opt/servers/hadoop-2.9.2/sbin:/opt/servers/jdk1.8/bin:/opt/servers/hadoop-2.9.2/bin:/opt/servers/hadoop-2.9.2/sbin:/opt/servers/hive-2.3.7/bin)
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/opt/servers/hive-2.3.7/lib/log4j-slf4j-impl-2.6.2.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/opt/servers/hadoop-2.9.2/share/hadoop/common/lib/slf4j-log4j12-1.7.25.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]

Logging initialized using configuration in file:/opt/servers/hive-2.3.7/conf/hive-log4j2.properties Async: true
Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions. Consider using a different execution engine (i.e. spark, tez) or using Hive 1.X releases.
hive (default)>
```

进入hive命令行有一大坨日志，看着很恶心，想要去除，怎么办呢？ 通过分析日志可知默认有重复的日志依赖，所以需要删除一个

```
jar:file:/opt/servers/hive-2.3.7/lib/log4j-slf4j-impl-2.6.2.jar
jar:file:/opt/servers/hadoop-2.9.2/share/hadoop/common/lib/slf4j-log4j12-1.7.25.jar
```

这里是hive中的一个日志依赖包和hadoop中的日志依赖包冲入了，我们删除Hive的日志依赖包，因为hadoop是共用的，尽量不要删它里面的东西。

```
[root@bigdata03 ~]# cd /opt/servers/hive-2.3.7/lib
[root@bigdata03 lib]# mv log4j-slf4j-impl-2.6.2.jar log4j-slf4j-impl-2.6.2.jar.bak
```

再次启动查看，剩下的就属于正常的了。

当遇到Hive发生错误时，我们需要查看Hive日志，可以通过配置文件来找到默认日志文件所在的位置。

```
[root@bigdata03 conf]# mv hive-log4j2.properties.template hive-log4j2.properties
# 添加以下内容
property.hive.log.level = WARN
property.hive.root.logger = DRFA
property.hive.perflogger.log.level = INFO
#log默认存放在/tmp/root，修改这个位置
property.hive.log.dir = /opt/servers/hive-2.3.7/logs
property.hive.log.file = hive.log

[root@bigdata03 conf]# mv hive-exec-log4j2.properties.template hive-exec-log4j2.properties
# 添加以下内容
property.hive.log.level = WARN
property.hive.root.logger = FA
property.hive.query.id = hadoop
property.hive.log.dir = /opt/servers/hive-2.3.7/logs
property.hive.log.file = ${sys:hive.query.id}.log
```

Hadoop 2.x中NameNode RPC 缺省的端口号8020，经常使用的端口号9000, 对端口号要敏感

#### 参数配置方式

查看参数配置信息

```
-- 查看全部参数
hive> set;

-- 查看某个参数
hive (default)> set hive.exec.mode.local.auto;
hive.exec.mode.local.auto=false
```

> 参数配置的3种方式
>
> 1. 用户自定义配置文件（hive-site.xml）
> 2. 启动hive时指定参数(-hiveconf) 
> 3. hive命令行指定参数(set) 
>
> 配置信息的优先级：set > -hiveconf > hive-site.xml > hive-default.xml



1. 配置文件方式

   默认配置文件：hive-default.xml

   用户自定义配置文件：hive-site.xml

   配置优先级：hive-site.xml > hive-default.xml

   配置文件的设定对本机启动的所有Hive进程有效;

   配置文件的设定对本机所有启动的Hive进程有效; 

2. 启动时指定参数值

   启动Hive时，可以在命令行添加 -hiveconf param=value 来设定参数，这些设定仅 

   对本次启动有效。 

   ```
   [root@bigdata03 ~]# hive -hiveconf hive.exec.mode.local.auto=true
   hive (default)> set hive.exec.mode.local.auto;
   hive.exec.mode.local.auto=true
   ```

3. 命令行修改参数

   可在 Hive 命令行中使用SET关键字设定参数，同样仅对本次启动有效 

   ```
   hive (default)> set hive.exec.mode.local.auto=false;
   hive (default)> set hive.exec.mode.local.auto;
   hive.exec.mode.local.auto=false
   ```
