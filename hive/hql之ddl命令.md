## HQL之DDL命令

DDL（data definition language），数据定义语言，主要的命令有CREATE、ALTER、DROP等

DDL主要用在定义、修改数据库对象的结构或数据类型

![hive数据库架构](./imgs/hive数据库架构.png)

### 数据库操作

hive有一个默认的数据库default，在操作HQL时，如果不明确的指定要使用哪个库，则使用默认数据库。

hive的数据库名、表名均不区分大小写；

不能使用关键字，尽量不使用特殊符号；

1. 创建数据库

   语法

   ```
   CREATE [REMOTE] (DATABASE|SCHEMA) [IF NOT EXISTS] database_name
     [COMMENT database_comment]
     [LOCATION hdfs_path]
     [MANAGEDLOCATION hdfs_path]
     [WITH DBPROPERTIES (property_name=property_value, ...)];
   ```

   示例

   ```
   -- 创建数据库，在HDFS上存储路径为 /user/hive/warehouse/*.db
   hive (default)> create database mydb;
   hive (default)> dfs -ls /user/hive/warehouse;
   drwxr-xr-x   - root supergroup          0 2022-04-05 03:15 /user/hive/warehouse/mydb.db
   
   -- 避免数据库已经存在时报错，使用 if not exists 进行判断【标准写法】
   hive (default)> create database if not exists mydb;
   
   -- 创建数据库: 添加备注，指定数据库在存放位置
   hive (default)> create database if not exists mydb2
                 > comment 'this is mydb2'
                 > location '/user/hive/mydb2.db';
   hive (default)> dfs -ls /user/hive;
   Found 2 items
   drwxr-xr-x   - root supergroup          0 2022-04-05 03:20 /user/hive/mydb2.db
   drwxr-xr-x   - root supergroup          0 2022-04-05 03:15 /user/hive/warehouse
   ```

2. 查看数据库

   ```
   -- 查看所有数据库
   hive (default)> show databases;
   
   -- 查看数据库信息
   desc database mydb2;
   desc database extended mydb2;
   describe database extended mydb2;
   ```

3. 使用数据库

   ```
   -- 切换到数据库mydb2
   hive (default)> use mydb2;
   OK
   Time taken: 0.038 seconds
   hive (mydb2)>
   ```

4. 删除数据库

   ```
   -- 删除一个空数据库
   drop database dbname;
   
   -- 如果数据库不为空，使用 cascade 强制删除
   drop database dbname cascade;
   ```

### 建表语法

```
CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
[(col_name data_type [column_constraint_specification] [COMMENT col_comment], ... [constraint_specification])]
  [COMMENT table_comment]
  [PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]
  [CLUSTERED BY (col_name, col_name, ...)
  [SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]
  [ROW FORMAT row_format] 
  [STORED AS file_format]
  [LOCATION hdfs_path]
  [TBLPROPERTIES (property_name=property_value, ...)]
  [AS select_statement];

CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
  LIKE existing_table_or_view_name
  [LOCATION hdfs_path];
```

说明

- CREATE TABLE：按给定名称创建表，如果表已经存在则抛出异常；可使用if not exists 规避

- EXTERNAL：创建外部表，否则创建的是内部表(管理表)。 

  删除内部表时，数据和表的定义同时被删除;

  删除外部表时，仅仅删除了表的定义，数据保留;

  在生产环境中，多使用外部表; 

- COMMENT：表的注释

- PARTITIONED BY：对标中数据进行分区，指定表的分区字段

- CLUSTERED BY：创建分桶表，指定分桶字段

- STORED BY：对桶中的一个或多个列排序，较少使用。

- 存储字句

  ```
  ROW FORMAT DELIMITED
  [FIELDS TERMINATED BY char]
  [COLLECTION ITEMS TERMINATED BY char]
  [MAP KEYS TERMINATED BY char]
  [LINES TERMINATED BY char] | SERDE serde_name
  [WITH SERDEPROPERTIES (property_name=property_value,
  property_name=property_value, ...)]
  ```

  建表时可指定 SerDe。如果没有指定 ROW FORMAT 或者 ROW FORMAT DELIMITED，将会使用默认的 SerDe。建表时还需要为表指定列，在指定列的同时也会指定自定义的 SerDe。Hive通过 SerDe 确定表的具体的列的数据。 

  **SerDe是Serialize/Deserilize的简称，hive使用Serde进行行对象的序列与反序列化。** 

- STORED AS SEQUENCEFILE|TEXTFILE|RCFILE

  如果文件数据是纯文本，可以使 用 STORED AS TEXTFILE(缺省);

  如果数据需要压缩，使用 STORED AS SEQUENCEFILE(二进制序列文件)。

- LOCATION：表在HDFS上的存放位置

- TBLPROPERTIES：定义表的属性 

- AS：后面可以接查询语句，表示根据后面的查询结果创建表

- LIKE：like表名，允许用户复制现有的表结构，但是不复制数据

### 内部表&外部表

内部表

文件：/root/t1.dat

```
2;zhangsan;book,TV,code;beijing:chaoyang,shagnhai:pudong
3;lishi;book,code;nanjing:jiangning,taiwan:taibei
4;wangwu;music,book;heilongjiang:haerbin
```

创建表SQL

```
-- 创建内部表
create table t1(
id int,
name string,
hobby array<string>,
addr map<string, string>
)
row format delimited
fields terminated by ";"
collection items terminated by ","
map keys terminated by ":";

-- 显示表的定义，显示的信息较少
hive (default)> desc t1;

-- 显示表的定义，显示的信息多，格式友好
hive (default)> desc formatted t1;

-- 加载数据
hive (default)> load data local inpath '/root/t1.dat' into table t1;

-- 查询数据
hive (default)> select * from t1;

-- 查询数据文件
hive (default)> dfs -ls /user/hive/warehouse/t1;
Found 1 items
-rwxr-xr-x   3 root supergroup        148 2022-04-05 05:16 /user/hive/warehouse/t1/t1.dat

-- 删除表。表和数据同时被删除
hive (default)> drop table t1;

-- 再次查询数据文件，已经被删除
```

外部表

```
-- 创建外部表
create external table t2(
id int,
name string,
hobby array<string>,
address map<string,string>
)
row format delimited
fields terminated by ";"
collection items terminated by ","
map keys terminated by ":";

-- 显示表的定义
hive (default)> desc formatted t2;

-- 加载数据
hive (default)> load data local inpath "/root/t1.dat" into table t2;

-- 查询数据
hive (default)> select * from t2;

-- 删除表。表删除了，目录仍然存在
hive (default)> drop table t2;

-- 再次查询数据文件，仍然存在
hive (default)> dfs -ls -R /user/hive/warehouse;
drwxr-xr-x   - root supergroup          0 2022-04-05 05:52 /user/hive/warehouse/t2
-rwxr-xr-x   3 root supergroup        148 2022-04-05 05:52 /user/hive/warehouse/t2/t1.dat
```

**内部表与外部表的转换** 

```
-- 创建内部表，加载数据，并检查数据文件和表的定义
create table t1(
id int,
name string,
hobby array<string>,
adrress map<string,string>
)
row format delimited
fields terminated by ";"
collection items terminated by ","
map keys terminated by ":";

-- 加载数据
hive (default)> load data local inpath "/root/t1.dat" into table t1;

-- 查看数据文件
hive (default)> dfs -ls /user/hive/warehouse/t1;

-- 显示表的定义，Table Type: MANAGED_TABLE
hive (default)> desc formatted t1;

-- 内部表转换为外部表
hive (default)> alter table t1 set tblproperties('EXTERNAL'='TRUE');

-- 再次查看表的定义，Table Type: EXTERNAL_TABLE，已转换为外部表

-- 外部表转换成内部表
hive (default)> alter table t1 set tblproperties('EXTERNAL'='FALSE');
```



### 分区表

Hive在执行查询时，一般会扫描整个表的数据。由于表的数据量大，全表扫描消耗时间长、效率低。 而有时候，查询只需要扫描表中的一部分数据即可，Hive引入了分区表的概念，将表的数据存储在不同的子目录中，每一个子目录对应一个分区。只查询部分分区数据时，可避免全表扫描，提高查询效率。 

在实际中，通常根据时间、地区等信息进行分区。

```
-- 创建分区表
create table if not exists t3(
id int,
name string,
hobby array<string>,
address map<string,string>
)
partitioned by (dt string)
row format delimited
fields terminated by ";"
collection items terminated by ","
map keys terminated by ":";

-- 加载数据
hive (default)> load data local inpath "/root/t1.dat" into table t3
              > partition(dt="2022-04-01");
hive (default)> load data local inpath "/root/t1.dat" into table t3
              > partition(dt="2022-04-02");
```

> 注意：分区字段不是表中已经存在的数据，可以将分区字段看成伪列

查看分区

```
hive (default)> show partitions t3;
partition
dt=2022-04-01
dt=2022-04-02
```

新增分区并设置数据

```
-- 增加一个分区，不加载数据
hive (default)> alter table t3 add partition(dt="2022-04-03");

-- 增加多个分区，不加载
hive (default)> alter table t3
              > add partition(dt="2022-04-04") partition(dt="2022-04-05");
              
              
-- 增加多个分区。准备数据
hive (default)> dfs -cp /user/hive/warehouse/t3/dt=2022-04-01 /user/hive/warehouse/t3/dt=2022-04-06;
hive (default)> dfs -cp /user/hive/warehouse/t3/dt=2022-04-01 /user/hive/warehouse/t3/dt=2022-04-07;
-- 增加多个分区。加载数据
hive (default)> alter table t3 add
              > partition(dt="2022-04-06") location "/user/hive/warehouse/t3/dt=2022-04-06"
              > partition(dt="2022-04-07") location "/user/hive/warehouse/t3/dt=2022-04-07";
```

修改分区的hdfs路径 

```
hive (default)> alter table t3 partition(dt="2022-04-01") set location "/user/hive/warehouse/t3/dt=2022-04-03";
```

删除分区

```
-- 可以删除一个或多个分区，用逗号隔开
hive (default)> alter table t3 drop partition(dt="2022-04-03"), partition(dt="2022-04-04");
```



### 分桶表

当单个的分区或者表的数据量过大，分区不能更细粒度的划分数据，就需要使用分桶技术将数据划分成更细的粒度。将数据按照指定的字段分成到多个桶中去，即将数据按照字段进行划分，数据按照字段划分到多个文件当中去。分桶的原理:

- MR中：key.hashCode % reductTask
- Hive中：分桶字段.hashCode % 分桶个数 

文件：/root/course.dat

```
-- 测试数据
1       java    90
1       c       78
1       python  91
1       hadoop  80
2       java    75
2       c       76
2       python  80
2       hadoop  93
3       java    98
3       c       74
3       python  89
3       hadoop  91
5       java    93
6       c       76
7       python  87
8       hadoop  88
```

HQL

```
-- 创建分桶表
create table course(
id int,
name string,
score int
)
clustered by (id) into 3 buckets
row format delimited
fields terminated by "\t";

-- 创建普通表
create table course_common(
id int,
name string,
score int
)
row format delimited
fields terminated by "\t";

-- 普通表加载数据
hive (default)> load data local inpath "/root/course.dat" into table course_common;

-- 通过 insert ... select ... 给桶表加载数据
hive (default)> insert into table course select * from course_common;

-- 观察分桶数据。数据按照:(分区字段.hashCode) % (分桶数) 进行分区
hive (default)> dfs -ls -R /user/hive/warehouse/course;
-rwxr-xr-x   3 root supergroup         48 2022-04-05 09:05 /user/hive/warehouse/course/000000_0
-rwxr-xr-x   3 root supergroup         53 2022-04-05 09:05 /user/hive/warehouse/course/000001_0
-rwxr-xr-x   3 root supergroup         63 2022-04-05 09:05 /user/hive/warehouse/course/000002_0
hive (default)> dfs -cat /user/hive/warehouse/course/000000_0;
3	hadoop	91
3	python	89
3	c	74
3	java	98
6	c	76
hive (default)> dfs -cat /user/hive/warehouse/course/000001_0;
7	python	87
1	hadoop	80
1	python	91
1	c	78
1	java	90
hive (default)> dfs -cat /user/hive/warehouse/course/000002_0;
8	hadoop	88
5	java	93
2	python	80
2	c	76
2	java	75
2	hadoop	93
```

分桶规则：分桶字段.hashCode % 分桶数
分桶表加载数据时，使用 insert... select ... 方式进行，网上有资料说要使用分区表需要设置 hive.enforce.bucketing=true，那是Hive 1.x 以前的版本；Hive 2.x 中，删除了该参数，始终可以分桶; 

### 修改表&删除表

```
-- 修改表名；rename
hive (default)> alter table course_common rename to course_common1;

-- 修改列名；change column
hive (default)> alter table course_common1 change column id cid int;

-- 修改字段类型；change column
hive (default)> alter table course_common1 change column cid cid string;
-- 修改字段数据类型时，要满足数据类型转换的要求。如int可以转为string，但是string不能转为int

-- 增加字段
hive (default)> alter table course_common1 add columns(common string);

-- 删除字段；replace columns
-- 这里仅仅是在元数据中删除了字段，并没有改动hdfs上的数据文件
hive (default)> alter table course_common1 replace columns(id string, cname string, score int);

-- 删除表
hive (default)> drop table course_common1;
```



### HQL DDL命令小结

主要对象：数据库、表

表的分类

1. 内部表。删除表时，同时删除元数据和表数据
2. 外部表。删除表时，仅删除元数据，保留表中数据；生产环境多使用外部表
3. 分区表。按照分区字段将表中的数据放置在不同的目录中，提高SQL查询的性能 
4. 分桶表。按照分桶字段，将表中数据分开，分桶字段.hashCode % 分桶数据

主要命令：create、alter 、drop 

