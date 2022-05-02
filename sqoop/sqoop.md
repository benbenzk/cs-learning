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

   ## Sqoop应用案例

在Sqoop中

- 导入是指：从关系型数据库向大数据集群(HDFS、HIVE、HBASE)传输数据；使用import关键字;

- 导出是指：从大数据集群向关系型数据库传输数据；使用export关键字；

### 测试数据脚本

```sql
-- 用于在MySQL中生成测试数据
CREATE DATABASE sqoop;
use sqoop;

CREATE TABLE sqoop.goodtbl(
  gname varchar(50),
  serialNumber int,
  price int,
  stock_number int,
  create_time date);
DROP FUNCTION IF EXISTS rand_string;
DROP PROCEDURE IF EXISTS batchInsertTestData;

SET GLOBAL log_bin_trust_function_creators = 1;


-- 替换语句默认的执行符号，将; 替换成 //
DELIMITER //
CREATE FUNCTION rand_string (n INT) RETURNS VARCHAR(255)
CHARSET 'utf8'
BEGIN
    DECLARE char_str varchar(200) DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE return_str varchar(255) DEFAULT '';
    DECLARE i INT DEFAULT 0;
    WHILE i < n DO
        SET return_str = concat(return_str, substring(char_str, FLOOR(1 + RAND()*36), 1));
        SET i = i+1;
    END WHILE;
    RETURN return_str;
END
//

-- 第一个参数表示：序号从几开始；第二个参数表示：插入多少条记录
CREATE PROCEDURE batchInsertTestData(m INT, n INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < n DO
        insert into sqoop.goodtbl (gname, serialNumber, price, stock_number, create_time)
        values (rand_string(6), i+m, ROUND(RAND()*100), FLOOR(RAND()*100), now());
        SET i = i+1;
    END WHILE;
END
//
DELIMITER ;
call batchInsertTestData(1, 100);
```

> 以下案例需要启动：HDFS、YARN、MySQL 对应的服务

### 第一节 导入数据

#### MySQL导入到HDFS

1. 导入全部数据

   ```shell
   sqoop import \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --table goodtbl \
   --target-dir /root/sqoop \
   --delete-target-dir \
   --num-mappers 1 \
   --fields-terminated-by "\t"
   ```

   参数说明

   - target-dir：将数据导入HDFS的路径；
   - delete-target-dir：如果目标文件夹在HDFS上已经存在，那么再次运行就会报错。可以使用--delete-target-dir来先删除目录。也可以使用append参数，表示追加数据；
   - num-mappers：启动多少个Map Task；默认启动4个Map Task；也可以写成 -m 1；
   - fields-terminated-by：HDFS文件中数据的分隔符；

2. 导入查询数据

   ```
   sqoop import \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --target-dir /root/sqoop \
   --append \
   -m 1 \
   --fields-terminated-by "\t" \
   --query 'select gname,serialNumber,price,stock_number,create_time from goodtbl where price>88 and $CONDITIONS;'
   ```

   说明

   - 查询语句的where子句中必须包含'$CONDITIONS'
   - 如果query后使用的是双引号，则$CONDITIONS前必须加转移符，查询语句外最好使用单引号，防止shell识别为自己的变量

3. 导入指定的列

   ```
   sqoop import \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --target-dir /root/sqoop \
   --delete-target-dir \
   --num-mappers 1 \
   --fields-terminated-by "\t" \
   --columns gname,serialNumber,price \
   --table goodtbl
   ```

   > 注意：columns中如果涉及到多列，用逗号分隔，不能添加空格

4. 导入查询数据（使用关键字）

   ```
   sqoop import \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --target-dir /root/flume \
   --delete-target-dir \
   -m 1 \
   --fields-terminated-by "\t" \
   --table goodtbl \
   --where "price>=68"
   ```

5. 启动多个Map Task导入数据

   在goodtbl中增加数据：call batchInsertTestData(1, 1000000);

   ```
   sqoop import \
   -Dorg.apache.sqoop.splitter.allow_text_splitter=true \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --target-dir /root/sqoop \
   --delete-target-dir \
   --fields-terminated-by "\t" \
   --table goodtbl \
   --split-by gname \
   #加主键后添加此参数测试
   -m 4
   #给goodtbl表增加主键
   alter table goodtbl add primary key(serialNumber);
   ```

   说明

   - 使用多个Map Task进行数据导入时，sqoop 要对每个Task的数据进行分区

      - 如果 MySQL 中的表有主键，指定 Map Task 的个数就行

      - 如果 MySQL 中的表没有主键，要使用 split-by 指定分区字段

      - 如果分区字段是字符类型，使用 sqoop 命令的时候要添加：-

        Dorg.apache.sqoop.splitter.allow_text_splitter=true。即

        ```
        sqoop import \
        -Dorg.apache.sqoop.splitter.allow_text_splitter=true \
        --connect jdbc:mysql://bigdata03:3306/sqoop \
        ... ...
        ```

   - 查询语句的where子句中的'$CONDITIONS'，也是为了做数据分区使用的，即使只有1个Map Task

#### MySQL导入到Hive

在hive中创建表

```mysql
create table mydb.goodtbl(
  gname string,
  serialNumber int,
  price int,
  stock_number int,
  create_time date
);
```

sqoop导入

```
sqoop import \
--connect jdbc:mysql://bigdata03:3306/sqoop \
--username hive \
--password 123456 \
--table goodtbl \
--hive-import \
--create-hive-table \
--fields-terminated-by "\t" \
--hive-overwrite \
--hive-table mydb.goodtbl \
-m 1
```

参数说明

- hive-import：必须参数，指定导入hive
- hive-database：Hive库名(缺省值default)
- hive-table：Hive表名
- fields-terminated-by：Hive字段分隔符
- hive-overwrite：覆盖中已经存在的数据
- create-hive-table：创建好 hive 表，但是表可能存在错误。***不建议使用这个参数，建议提前建好表***

### 第2节 导出数据

Hive/HDFS导出到RDBMS

1. 提前创建MySQL表

   ```
   CREATE TABLE sqoop.goodtbl2(
     gname varchar(50),
     serialNumber int,
     price int,
     stock_number int,
     create_time date
   );
   ```

2. 导出

   ```
   sqoop export \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --table goodtbl2 \
   --num-mappers 1 \
   --export-dir /user/hive/warehouse/mydb.db/goodtbl \
   --input-fields-terminated-by "\t"
   ```

### 第3节 增量数据导入

#### 变化数据捕捉（CDC）

前面都是执行的全量数据导入。如果数据量很小，则采取完全源数据抽取；如果源数据量很大，则需要抽取发生变化的数据，这种数据抽取模式叫做变化数据捕获，简称CDC(Change Data Capture)。

CDC大体分为两种：侵入式和非侵入式。侵入式指CDC操作会给源系统带来性能影响，只要CDC操作以任何一种方式对源数据库执行了SQL操作，就认为是侵入式的。

常用的4种CDC方法是（前三种是侵入式的）

- 基于时间戳的CDC。

  抽取过程可以根据某些属性列来判断哪些数据是增量的，最常见的属性列有以下两种

   - 时间戳：最好有两个列，一个插入时间戳，表示何时创建，一个更新时间戳，表示最后一次更新的时间;
   - 序列：大多数数据库都提供自增功能，表中的列定义成自增的，很容易地根据该列识别新插入的数据;

  时间戳的CDC是最简单且常用的，但是有如下缺点

   - 不能记录删除记录的操作
   - 无法识别多次更新
   - 不具有实时能力

- 基于触发器的CDC。当执行INSERT、UPDATE、DELETE这些SQL语句时，激活数据库里的触发器，使用触发器可捕获变更的数据，并把数据保存在中间临时表里。然后这些变更数据再从临时表取出。大多数场合下，不允许向操作型数据库里添加触发器，且这种方法会降低系统性能，基本不会被采用。

- 基于快照的CDC。 可以通过比较源表和快照表来获得数据变化。基于快照的CDC可以检测到插入、更新和删除的数据，这是相对于基于时间戳的CDC方案的优点；其缺点是需要大量存储空间来保存快照。

- 基于日志的CDC。最复杂的和没有侵入性的CDC方法是基于日志的方式。数据库会把每个插入、更新、删除操作记录到日志里。解析日志文件，就可以获取相关信息。每个关系型数据库日志格式不一致，没有通用的产品。阿里巴巴的canal可以完成MySQL日志文件解析。

增量导入数据分为两种方式

1. 基于递增列的增量数据导入（Append方式）
2. 基于时间列的数据增量导入（LastModified方式）

#### Append方式

1. 准备初识数据

   ```
   -- 在MySQL命令行中删除MySQL表中的全部数据
   truncate table sqoop.goodtbl;
   
   -- 在Hive命令行中删除Hive表中的全部数据
   truncate table mydb.goodtbl;
   
   -- 向MySQL的表中插入100条数据
   call batchInsertTestData(1, 100);
   ```

2. 将数据导入Hive

   ```
   sqoop import \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --table goodtbl \
   --incremental append \
   --hive-import \
   --fields-terminated-by "\t" \
   --hive-table mydb.goodtbl \
   --check-column serialNumber \
   --last-value 50 \
   -m 1
   ```

   参数说明

   - check-column 用来指定一些列（即可以指定多个列），这些列在增量导入时用来检查这些数据是否作为增量数据进行导入，和关系型数据库中的自增字段及时间戳类似。这些被指定的列的类型不能使用任意字符类型，如char、varchar等类型都不可以
   - last-value 指定上一次导入中检查列指定字段最大值

3. 检查hive表中是否有数据，有多少条数据

4. 再向MySQL中插入1000条数据，编号从200开始`call batchInsertTestData(200, 1000);`

5. 再次执行增量导入，将数据从MySQL导入Hive中；此时要将last-value改为100

   ```
   sqoop import \
   --connect jdbc:mysql://bigdata03:3306/sqoop \
   --username hive \
   --password 123456 \
   --table goodtbl \
   --incremental append \
   --hive-import \
   --fields-terminated-by "\t" \
   --hive-table mydb.goodtbl \
   --check-column serialNumber \
   --last-value 100 \
   -m 1
   ```

6. 再次检查hive表中是否有数据，有多少条数据

### 第4节 执行job

执行数据增量导入有两种实现方式

1. 每次手工配置last-value，手工调度
2. 使用job，给定初始last-value，定时任务每天定时调度

很明显方式2更简便，步骤如下

1. 创建口令文件

   ```
   echo -n "123456" > sqoopPWD.pwd
   hdfs dfs -mkdir -p /sqoop/pwd
   hdfs dfs -put sqoopPWD.pwd /sqoop/pwd
   hdfs dfs -chmod 400 /sqoop/pwd/sqoopPWD.pwd
   ```

2. 创建sqoop job

   ```
   sqoop job --create myjob1 -- import \
   --connect jdbc:mysql://bigdata03:3306/sqoop?useSSL=false \
   --username hive \
   --password-file /sqoop/pwd/sqoopPWD.pwd \
   --table goodtbl \
   --incremental append \
   --hive-import \
   --hive-table mydb.goodtbl \
   --check-column serialNumber \
   --last-value 0 \
   -m 1
   
   # 查看已创建的job
   sqoop job --list
   
   # 查看job详细运行参数
   sqoop job --show myjob1
   ```

3. 执行job

   ```
   sqoop job --exec myjob1
   ```

4. 删除job

   ```
   sqoop job --delete myjob1
   ```

5. 查看数据

**实现原理**

因为job执行完成后，会把当前check-column的最大值记录到meta中，下次再调起时把此值赋给last-value。 缺省情况下元数据保存在 ~/.sqoop/，其中metastore.db.script文件记录了对last-value的更新操作:

```shell
cat ~/.sqoop/metastore.db.script | grep incremental.last.value
```

## Sqoop常用命令及参数

### 第1节 常用命令

<table>
  <thead>
    <tr>
      <td width="10%">序号</td>
      <td width="20%">命令</td>
      <td width="30%">类</td>
      <td>说明</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td><td>import</td><td>ImportTool</td>
      <td>将数据导入到集群</td>
    </tr>
    <tr>
      <td>2</td><td>export</td><td>ExportTool</td>
      <td>将集群数据导出</td>
    </tr>
    <tr>
      <td>3</td><td>codegen</td><td>CodeGenTool</td>
      <td>获取数据库中某张表数据生成Java并打包Jar</td>
    </tr>
    <tr>
      <td>4</td><td>create-hive-table</td><td>CreateHiveTableToo</td>
      <td>创建Hive表</td>
    </tr>
    <tr>
      <td>5</td><td>eval</td><td>EvalSqlTool</td>
      <td>查看SQL执行结果</td>
    </tr>
    <tr>
      <td>6</td><td>import-all-tables</td><td>ImportAllTablesTool</td>
      <td>入某个数据库下所有表到HDFS中</td>
    </tr>
    <tr>
      <td>7</td><td>job</td><td>JobTool</td>
      <td>用来生成一个sqoop的任务，生成后，该任务并不执行，除非使用命令执行该任务。</td>
    </tr>
    <tr>
      <td>8</td><td>list-databases</td><td>ListDatabasesTool</td>
      <td>列出所有数据库名</td>
    </tr>
    <tr>
      <td>9</td><td>list-tables</td><td>ListTablesTool</td>
      <td>列出某个数据库下所有表</td>
    </tr>
    <tr>
      <td>10</td><td>merge</td><td>MergeTool</td>
      <td>将HDFS中不同目录下面的数据合在一起，并存放在指定的目录中</td>
    </tr>
    <tr>
      <td>11</td><td>metastore</td><td>MetastoreTool</td>
      <td>记录sqoop job的元数据信息， 如果不启动metastore实例，则默认的元数据存储目录为：~/.sqoop，如果要更改存储目录，可以在配置文件sqoop- site.xml中进行更改。</td>
    </tr>
    <tr>
      <td>12</td><td>help</td><td>HelpTool</td>
      <td>打印sqoop帮助信息</td>
    </tr>
    <tr>
      <td>13</td><td>version</td><td>VersionTool</td>
      <td>打印sqoop版本信息</td>
    </tr>
  </tbody>
</table>

### 第2节 常用参数

1. 公用参数 - 数据库连接

   <table>
     <thead>
       <tr>
         <td width="10%">序号</td>
         <td width="40%">参数</td>
         <td width="50%">说明</td>
       </tr>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--connect</td>
         <td>连接关系型数据库的URL</td>
       </tr>
       <tr>
         <td>2</td><td>--connection-manager</td>
         <td>指定要使用的连接管理类</td>
       </tr>
       <tr>
         <td>3</td><td>--driver</td>
         <td>Hadoop根目录</td>
       </tr>
       <tr>
         <td>4</td><td>--help</td>
         <td>打印帮助信息</td>
       </tr>
       <tr>
         <td>5</td><td>--username</td>
         <td>连接数据库的用户名 </td>
       </tr>
       <tr>
         <td>6</td><td>--password </td>
         <td>连接数据库的密码</td>
       </tr>
       <tr>
         <td>7</td><td>--verbose</td>
         <td>在控制台打印出详细信息</td>
       </tr>
     </tbody>
   </table>

2. 公用参数 - import

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--enclosed-by</td>
         <td>给字段值前加上指定的字符</td>
       </tr>
       <tr>
         <td>2</td><td>--escaped-by</td>
         <td>对字段中的双引号加转义符</td>
       </tr>
       <tr>
         <td>3</td><td>--fields-terminated-by</td>
         <td>设定每个字段是以什么符号作为结束，默认为逗号</td>
       </tr>
       <tr>
         <td>4</td><td>-lines-terminated-by</td>
         <td>设定每行记录之间的分隔符，默认是\n</td>
       </tr>
       <tr>
         <td>5</td><td>--mysql-delimiters</td>
         <td>Mysql默认的分隔符设置，字段之间以逗号分隔，行之间 以\n分隔，默认转义符是\，字段值以单引号包裹</td>
       </tr>
       <tr>
         <td>6</td><td>--optionally-enclosed-by</td>
         <td>给带有双引号或单引号的字段值前后加上指定字符</td>
       </tr>
     </tbody>
   </table>
3. 公用参数 - export
   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--input-enclosed-by</td>
         <td>对字段值前后加上指定字符</td>
       </tr>
       <tr>
         <td>2</td><td>--input-escaped-by</td>
         <td>对含有转移符的字段做转义处理</td>
       </tr>
       <tr>
         <td>3</td><td>--input-fields-terminated-by</td>
         <td>字段之间的分隔符</td>
       </tr>
       <tr>
         <td>4</td><td>--input-lines-terminated-by</td>
         <td>行之间的分隔符</td>
       </tr>
       <tr>
         <td>5</td><td>--input-optionally-enclosed-by</td>
         <td>给带有双引号或单引号的字段前后加上指定字符</td>
       </tr>
     </tbody>
   </table>

4. 公用参数 - hive

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--hive-delims-replacement</td>
         <td>用自定义的字符串替换掉数据中的\r\n和\013 \010等字符</td>
       </tr>
       <tr>
         <td>2</td><td>--hive-drop-import-delims</td>
         <td>在导入数据到hive时，去掉数据中的 \r\n\013\010这样的字符</td>
       </tr>
       <tr>
         <td>3</td><td>--map-column-hive</td>
         <td>生成hive表时，可以更改生成字段的数据类型</td>
       </tr>
       <tr>
         <td>4</td><td>--hive-partition-key</td>
         <td>创建分区，后面直接跟分区名，分区字段的默认 类型为string</td>
       </tr>
       <tr>
         <td>5</td><td>--hive-partition-value</td>
         <td>导入数据时，指定某个分区的值</td>
       </tr>
       <tr>
         <td>6</td><td>--hive-home</td>
         <td>hive的安装目录，可以通过该参数覆盖之前默认配置的目录</td>
       </tr>
       <tr>
         <td>7</td><td>--hive-import</td>
         <td>将数据从关系数据库中导入到hive表中</td>
       </tr>
       <tr>
         <td>8</td><td>--hive-overwrite</td>
         <td>覆盖掉在hive表中已经存在的数据</td>
       </tr>
       <tr>
         <td>9</td><td>--create-hive-table</td>
         <td>默认是false，即如果目标表已经存在了，那么创建任务失败</td>
       </tr>
       <tr>
         <td>10</td><td>--hive-table</td>
         <td>后面接要创建的hive表,默认使用MySQL的表名</td>
       </tr>
       <tr>
         <td>11</td><td>--table</td>
         <td>指定关系数据库的表名</td>
       </tr>
     </tbody>
   </table>

5. import参数

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--append</td>
         <td>将数据追加到HDFS中已经存在的DataSet中，如果使用该参数，sqoop会把数据先导入到临时文件目录，再合并</td>
       </tr>
       <tr>
         <td>2</td><td>--as-avrodatafile</td>
         <td>将数据导入到一个Avro数据文件中</td>
       </tr>
       <tr>
         <td>3</td><td>--as-sequencefile</td>
         <td>将数据导入到一个sequence文件中</td>
       </tr>
       <tr>
         <td>4</td><td>--as-textfile</td>
         <td>将数据导入到一个普通文本文件中</td>
       </tr>
       <tr>
         <td>5</td><td>--boundary-query</td>
         <td>边界查询，导入的数据为该参数的值(一条sql语 句)所执行的结果区间内的数据</td>
       </tr>
       <tr>
         <td>6</td><td>--columns<col1, col2, col3></td>
         <td>指定要导入的字段</td>
       </tr>
       <tr>
         <td>7</td><td>--direct</td>
         <td>直接导入模式，使用的是关系数据库自带的导入导
出工具，以便加快导入导出过程</td>
</tr>
<tr>
<td>8</td><td>--direct-split-size</td>
<td>在使用上面direct直接导入的基础上，对导入的流 按字节分块，即达到该阈值就产生一个新的文件</td>
</tr>
<tr>
<td>9</td><td>--inline-lob-limit</td>
<td>设定大对象数据类型的最大值</td>
</tr>
<tr>
<td>10</td><td>--m或–num- mappers</td>
<td>启动N个map来并行导入数据，默认4个。</td>
</tr>
<tr>
<td>11</td><td>--query或--e</td>
<td>将查询结果的数据导入，使用时必须伴随参-- target-dir，--hive-table，如果查询中有where条 件，则条件后必须加上$CONDITIONS关键字</td>
</tr>
<tr>
<td>12</td><td>--split-by</td>
<td>按照某一列来切分表的工作单元，不能与--autoreset-to-one-mapper连用(请参考官方文 档)</td>
</tr>
<tr>
<td>13</td><td>--table</td>
<td>关系数据库的表名</td>
</tr>
<tr>
<td>14</td><td>--target-dir</td>
<td>指定HDFS路径</td>
</tr>
<tr>
<td>15</td><td>--warehouse-dir</td>
<td>与14参数不能同时使用，导入数据到HDFS时指定的目录</td>
</tr>
<tr>
<td>16</td><td>--where</td>
<td>从关系数据库导入数据时的查询条件</td>
</tr>
<tr>
<td>17</td><td>--z或--compress</td>
<td>允许压缩</td>
</tr>
<tr>
<td>18</td><td>--compression-codec</td>
<td>指定hadoop压缩编码类，默认为gzip(Use Hadoop codec default gzip)</td>
</tr>
<tr>
<td>19</td><td>--null-string</td>
<td>string类型的列如果null，替换为指定字符串</td>
</tr>
<tr>
<td>20</td><td>--null-non-string</td>
<td>非string类型的列如果null，替换为指定字符串</td>
</tr>
<tr>
<td>21</td><td>--check-column</td>
<td>作为增量导入判断的列名</td>
</tr>
<tr>
<td>22</td><td>--incremental</td>
<td>mode:append或lastmodified</td>
</tr>
<tr>
<td>23</td><td>--last-value</td>
<td>指定某一个值，用于标记增量导入的位置</td>
</tr>
</tbody>
   </table> 

6. export参数

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--direct</td>
         <td>利用数据库自带的导入导出工具，以便于提高效率</td>
       </tr>
       <tr>
         <td>2</td><td>--export-dir</td>
         <td>存放数据的HDFS的源目录</td>
       </tr>
       <tr>
         <td>3</td><td>-m或--num-mappers</td>
         <td>启动N个map来并行导入数据，默认4个</td>
       </tr>
       <tr>
         <td>4</td><td>--table</td>
         <td>指定导出到哪个RDBMS中的表</td>
       </tr>
       <tr>
         <td>5</td><td>--update-key</td>
         <td>对某一列的字段进行更新操作</td>
       </tr>
       <tr>
         <td>6</td><td>--update-mode</td>
         <td>updateonly allowinsert(默认)</td>
       </tr>
       <tr>
         <td>7</td><td>--input-null-string</td>
         <td>请参考import该类似参数说明</td>
       </tr>
       <tr>
         <td>8</td><td>--input-null-non-string</td>
         <td>请参考import该类似参数说明</td>
       </tr>
       <tr>
         <td>9</td><td>--staging-table</td>
         <td>创建一张临时表，用于存放所有事务的结果，然后将所有
事务结果一次性导入到目标表中，防止错误。</td>
</tr>
<tr>
<td>10</td><td>--clear- staging-table</td>
<td>如果第9个参数非空，则可以在导出操作执行前，清空临时事务结果表</td>
</tr>
</tbody>
</table>