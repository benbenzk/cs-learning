## HQL之数据操作

### 数据导入

#### 装载数据Load

语法

```
LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION (partcol1=val1, partcol2=val2 ...)]
```

- LOAD DATA INPATH ...  从HDFS加载数据到HIVE表中；HDFS文件移动到Hive表指定的位置。
- LOAD DATA LOCAL INPATH ... 从本地文件系统加载数据到Hive表中；本地文件会拷贝到Hive表指定的位置
- INPATH 加载数据的路径
- OVERWRITE 覆盖表中已有数据；否则表示追加数据
- PARTITION 将数据加载到指定的分区

准备工作

```
数据文件（/root/sourceA.txt）
1,fish1,SZ
2,fish2,SH
3,fish3,HZ
4,fish4,QD
5,fish5,SR

-- 创建表
create table tabA(
id int,
name string,
area string
)
row format delimited
fields terminated by ",";

-- 拷贝文件到HDFS
hdfs dfs -put sourceA.txt /data
```

装载数据

```
-- 加载本地文件到表tabA
load data local inpath '/root/sourceA.txt' into table tabA;
-- 检查本地文件还在

-- 加载hdfs文件到表tabA
load data inpath '/data/sourceA.txt' into table tabA;
-- 检查HDFS文件，已经被转移

-- 加载数据覆盖表中已有数据
load data inpath "/data/sourceA.txt" overwrite into table tabA;

-- 创建表时加载数据
hdfs dfs -mkdir /user/hive/tabB
hdfs dfs -put sourceA.txt /user/hive/tabB

create table tabB(
id int,
name string,
area string
)
row format delimited
fields terminated by ","
location "/user/hive/tabB";

```

#### 插入数据Insert

```
-- 创建分区表
create table tabC(
id int,
name string,
area string
)
partitioned by (month string)
row format delimited
fields terminated by ",";

-- 插入数据
insert into table tabC
partition(month="20220401")
values (5, 'wangwu', 'BJ'), (4, 'lishi', 'SH'), (3, 'zhangsan', 'TJ');

-- 插入查询的结果数据
insert into table tabC partition(month="20220402")
select id,name,area from tabC where month="20220401";

-- 多表（多分区）插入模式
hive (default)> from tabC
              > insert overwrite table tabC partition(month="20220403")
              > select id,name,area where month="20220402"
              > insert overwrite table tabC partition(month="20220404")
              > select id,name,area where month="20220402";
```

#### 创建表并插入数据（as select）

```
-- 据查询结果创建表
create table if not exists tabD
as select * from tabC;
```

#### 使用import导入数据（没有实验成功！！！！）

```
import table tabC partition(month="20220405") from "/data/tabC4";
```

### 数据导出

```
-- 将查询结果导出到本地
insert overwrite local directory "/root/tabC" select * from tabC;

-- 将查询结果格式化输出到本地
insert overwrite local directory "/root/tabC2"
row format delimited
fields terminated by " "
select * from tabC;

-- 将查询结果导出到HDFS
insert overwrite directory "/data/tabC3"
row format delimited
fields terminated by ";"
select * from tabC;

-- dfs 命令导出数据到本地；本质是执行数据文件的拷贝
hive (default)> dfs -get /user/hive/warehouse/tabc /root/tabC4;

-- hive 命令导出数据到本地；执行查询将查询结果重定向到文件
[root@bigdata03 ~]# hive -e "select * from tabC" > a.log

-- export导出数据到HDFS；使用export导出数据时，不仅有数还有表的元数据信息
hive (default)> export table tabC to "/data/tabC4";

-- export导出的数据，可以使用import命令导入到Hive表中
-- 使用like tname创建的表结构与原表一致。create ... as select ...结构可能不一致
hive (default)> create table tabE like tabc;
hive (default)> import table tabE from "/data/tabC4";

-- 截断表，清空数据。（注意：仅能操作内部表）
hive (default)> truncate table tabE;

-- 以下语句报错，外部表不能执行truncate操作
-- 修改表tabC为外部表
hive (default)> alter table tabC set tblproperties("EXTERNAL"="TRUE");
-- 清空数据，提示失败不能清空非内部表
hive (default)> truncate table tabC;
FAILED: SemanticException [Error 10146]: Cannot truncate non-managed table tabC.
```

### 总结

**数据导入：**load data/insert/create table ... as select ... /import table

**数据导出：**insert overwrite ... directory ... /hdfs dfs -get/hive -e "select ..." > a.log/export table ...

hive的数据导入与导出还可以使用其它工具：Sqoop、DataX等

