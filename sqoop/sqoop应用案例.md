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