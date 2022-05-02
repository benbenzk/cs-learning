## HQL之DML命令

DML(Data Manipulation Language)，数据操纵语言

DML主要有3种形式：插入（INSERT）、删除（DELETE）、更新（UPDATE）。 

事务（Transaction）是一组单元化操作，这些操作要么都执行，要么都不执行，是一个不可分割的工作单元。 

事务具有的四个要素，这四个基本要素通常称为ACID特性

1. 原子性(Atomicity)

   一个事务是一个不可再分割的工作单位，事务中的所有操作要么都发生，要么都不发生。

2. 一致性(Consistency)

   事务的一致性是指事务的执行不能破坏数据库数据的完整性和一致性， 一个事务在执行之前和执行之后，数据库都必须处于一致性状态。

3. 隔离性 (Isolation)

   在并发环境中，并发的事务是相互隔离的，一个事务的执行不能被其他事务干扰。即不同的事务并发操纵相同的数据时，每个事务都有各自完整的数据空间，即一个事务内部的操作及使用的数据对其他并发事务是隔离的，并发执行的各个事务之间不能互相干扰。

4. 持久性(Durability)

   事务一旦提交，它对数据库中数据的改变就应该是永久性的。

### 第1节 Hive事务

Hive从0.14版本开始支持事务和**行级更新**，但缺省是不支持的，需要一些附加的配置。要想支持**行级insert、update、delete**，需要配置Hive支持事务。

**Hive事务的限制** 

- Hive提供行级别的ACID语义
- BEGIN、COMMIT、ROLLBACK 暂时不支持，所有操作自动提交
- 目前只支持 ORC 的文件格式
- 默认事务是关闭的，需要设置开启
- 要是使用事务特性，表必须是分桶的
- 只能使用内部表 如果一个表用于ACID写入(INSERT、UPDATE、DELETE)，必须在表中设置表属性 : "transactional=true"
- 必须使用事务管理器org.apache.hadoop.hive.ql.lockmgr.DbTxnManager
- 目前支持快照级别的隔离。就是当一次数据查询时，会提供一个数据一致性的快照
- LOAD DATA语句目前在事务表中暂时不支持 

HDFS不支持文件的修改；并且当有数据追加到文件时，HDFS不对读数据的用户提供一致性。为了在HDFS上支持数据的更新：

- 表和分区的数据都被存在基本文件中(base files) 
- 新的记录和更新，删除都存在增量文件中(delta files) 
- 一个事务操作创建一系列的增量文件
- 在读取的时候，将基础文件和修改，删除合并，最后返回给查询 

### 第二节 Hive事务操作实例

测试数据文件/data/zxz_data.dat

```
name1,1,010-83596208,2020-01-01
name2,2,027-63277201,2020-01-02
name3,3,010-83596208,2020-01-03
name4,4,010-83596208,2020-01-04
name5,5,010-83596208,2020-01-05
```

SQL

```sql
-- 这些参数也可以设置在hive-site.xml中
set hive.support.concurrency = true;

-- hive 0.x and 1.x only
set hive.enforce.bucketing = true;

set hive.exec.dynamic.partition.mode = nonstrict;
set hive.txn.manager = org.apache.hadoop.hive.ql.lockmgr.DbTxnManager;

-- 创建表用于更新。满足条件：内部表、ORC格式、分桶、设置表属性
create table zxz_data(
name string,
nid int,
phone string,
ntime date
)
clustered by(nid) into 5 buckets
stored as orc
tblproperties("transactional"="true");

-- 创建临时表，用于向分桶表插入数据
create table temp1(
name string,
nid int,
phone string,
ntime date
)
row format delimited
fields terminated by ",";

-- 向临时表载入数据
load data local inpath "/root/zxz_data.dat" overwrite into table temp1;
-- 向事务表中加载数据
insert into table zxz_data select * from temp1;

-- DML操作
delete from zxz_data where nid=3;
dfs -ls /user/hive/warehouse/mydb.db/zxz_data;

-- 不支持
insert into zxz_data values ("name3", 3, "010-83596208", current_data);
-- 执行
insert into zxz_data values ("name3", 3, "010-83596208", "2022-04-20");

insert into zxz_data select "name3", 3, "010-83596208", current_date;
dfs -ls /user/hive/warehouse/mydb.db/zxz_data;

insert into zxz_data values
("name6", 6, "010-83596208", "2022-03-21"),
("name7", 7, "010-83596208", "2022-03-22"),
("name8", 9, "010-83596208", "2022-03-23"),
("name9", 8, "010-83596208", "2022-03-24");
dfs -ls /user/hive/warehouse/mydb.db/zxz_data;

update zxz_data set name=concat(name, "00") where nid>3;
dfs -ls /user/hive/warehouse/mydb.db/zxz_data;

-- 分桶字段不能修改，下面的语句不能执行
-- Updating values of bucketing columns is not supported
update zxz_data set nid = nid + 1;
```

