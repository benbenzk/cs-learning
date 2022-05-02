## HQL之DQL命令

DQL（Data Query Language）数据查询语言

### select语法

```
SELECT [ALL | DISTINCT] select_expr, select_expr, ...
  FROM table_reference
  [WHERE where_condition]
  [GROUP BY col_list]
  [ORDER BY col_list]
  [CLUSTER BY col_list | [DISTRIBUTE BY col_list] [SORT BY col_list]]
 [LIMIT [offset,] rows]
```

### SQL语句书写注意事项

- SQL语句对大小写不敏感
- SQL语句可以写一行（简单SQL），也可以写多行（复杂SQL）
- 关键字不能缩写，也不能分行
- 各字句一般要分行
- 使用缩写格式，提高SQL语句的可读性（重要）

测试文件/root/emp.dat

```
7369,SMITH,CLERK,7902,2010-12-17,800,,20
7499,ALLEN,SALESMAN,7698,2011-02-20,1600,300,30
7521,WARD,SALESMAN,7698,2011-02-22,1250,500,30
7566,JONES,MANAGER,7839,2011-04-02,2975,,20
7654,MARTIN,SALESMAN,7698,2011-09-28,1250,1400,30
7698,BLAKE,MANAGER,7839,2011-05-01,2850,,30
7782,CLARK,MANAGER,7839,2011-06-09,2450,,10
7788,SCOTT,ANALYST,7566,2017-07-13,3000,,20
7839,KING,PRESIDENT,,2011-11-07,5000,,10
7844,TURNER,SALESMAN,7698,2011-09-08,1500,0,30
7876,ADAMS,CLERK,7788,2017-07-13,1100,,20
7900,JAMES,CLERK,7698,2011-12-03,950,,30
7902,FORD,ANALYST,7566,2011-12-03,3000,,20
7934,MILLER,CLERK,7782,2012-01-23,1300,,10
```

加载数据SQL

```
-- 建表并加载数据
create table emp(
empno int,
ename string,
job string,
mgr int,
hiredate DATE,
sal int,
comm int,
deptno int
)
row format delimited
fields terminated by ",";

-- 加载数据
hive (default)> load data local inpath "/root/emp.dat" into table emp;
```

### 基本查询

```
-- 省略from子句的查询
select 8*888;
select current_date;

-- 使用列别名
select 8*888 product;
select current_date as currdate;

-- 全表查询
select * from tmp;

-- 选择特定列查询
select ename,sal,comm from emp;

-- 使用函数
select count(*) from emp;

-- count(colname)按字段进行count，不统计NULL
select sum(sal) from emp;
select max(sal) from emp;
select min(sal) from emp;
select avg(sal) from emp;

-- 使用limit子句限制返回的行数
select * from emp limit 3;
```

### WHERE子句

where子句紧随from子句，使用where子句，过滤满足条件的数据；

⚠️ where子句中不能使用列的别名

```
select * from emp
 where sal > 2000;
```

where子句中会涉及到较多的比较运算和逻辑运算。

### 比较运算符

| 运算符                    | 说明                                                         |
| ------------------------- | ------------------------------------------------------------ |
| =、==、<=>                | 等于                                                         |
| <>、!=                    | 不等于                                                       |
| <、<=、>、>=              | 大于等于、小于等于                                           |
| is [not] null             | 如果A等于NULL，则返回TRUE，反之返回FALSE。<br>使用NOT关键字结果相反 |
| in(value1,value2, ... )   | 匹配列表中的值                                               |
| LIKE                      | 简单正则表达式，也称通配符模式。<br>'%x'表示必须以字母'x'结尾；<br>'%x%'表示包含有字母'x'，可以位于字符串任意位置。<br>使用NOT关键字结果相反。<br>%代表匹配零个活多个字符（任意个字符）；<br>_代表匹配一个字符。 |
| [NOT] BETWEEN ... AND ... | 范围的判断，使用NOT关键字结果相反。                          |
| RLIKE、REGEXP             | 基于java的正则表达式，匹配返回TRUE，反之返回FALSE。<br>匹配使用的是JDK中的正则表达式接口实现的，因为正则也依据其中的规则。<br>例如，正则表达式必须和整个字符串A相匹配，而不是只需与其字符串匹配。 |

通常情况下NULL参与运算，返回值为NULL；NULL<=>NULL的结果为true。

### 逻辑运算符

常用：and、or、not

```
-- 比较运算符
hive (default)> select null=null;
NULL
hive (default)> select null==null;
NULL
hive (default)> select null<=>null;
true

-- 使用is null判空
select * from emp where comm is null;

-- 使用in
select * from emp where deptno in (20,30);

-- 使用between ... and ...
select * from emp where sal between 1000 and 2000;

-- 使用like
select ename, sal from emp where ename like '%L%';

-- 使用rlike。正则表达式，名字以A或S开头
select ename,sal from emp where ename rlike '^(A|S).*';
```

### group by 子句

group by语句通常与聚组函数一起使用，按照一个活多个列对数据进行分组，对每个分组进行聚合操作。

```
-- 计算emp表每个部门的平均工资
hive (default)> select deptno, avg(sal) from emp group by deptno;

-- 计算emp每个部门中每个岗位的最高薪水
hive (default)> select deptno,job,max(sal) from emp group by deptno,job;
```

- where子句针对表中的数据发挥作用;having针对查询结果(聚组以后的结果) 发挥作用；
- where子句不能有分组函数；
- having子句可以有分组函数 having只用于group by分组统计之后 

```
-- 求每个部门的平均薪水大于2000的部门
select deptno, avg(sal) from emp
group by deptno
having avg(sal) > 2000;
```



### 表连接

Hive支持通常的SQL JOIN语句。默认情况下，仅支持等值连接，不支持非等值连接。

JOIN 语句中经常会使用表的别名。使用别名可以简化SQL语句的编写，使用表名前缀可以提高SQL的解析效率。 

连接查询操作分为两大类：内连接和外连接，而外连接可进一步细分为三种类型: 

1. 内连接: [inner] join 
2. 外连接 (outer join) 
   - 左外连接。 left [outer] join，左表的数据全部显示
   - 右外连接。 right [outer] join，右表的数据全部显示
   - 全外连接。 full [outer] join，两张表的数据都显示 

数据文件

```
/data/u1.dat
1,a
2,b
3,c
4,d
5,e
6,f

/data/u2.dat
4,d
5,e
6,f
7,g
8,h
9,i

create table if not exists u1(
id int,
name string
)
row format delimited
fields terminated by ",";

create table if not exists u2(
id int,
name string
)
row format delimited
fields terminated by ",";

load data local inpath "/root/u1.dat" into table u1;
load data local inpath "/root/u2.dat" into table u2;

-- 内连接
select * from u1 join u2 on u1.id=u2.id;

-- 左外连接
select * from u1 left join u2 on u1.id=u2.id;

-- 右外连接
select * from u1 right join u2 on u1.id=u2.id;

-- 全外连接
select * from u1 full join u2 on u1.id=u2.id;
```

#### 多表连接

连接n张表，至少需要 n-1 个连接条件。例如：连接四张表，至少需要三个连接条件。 

多表连接查询，查询老师对应的课程，以及对应的分数，对应的学生：

```
select *
  from techer t left join course c on t.t_id = c.t_id
                left join score  s on s.c_id = c.c_id
                left join student stu on s.s_id = stu.s_id;
```

Hive总是按照从左到右的顺序执行，Hive会对每对JOIN连接对象启动一个MapReduce任务。 

上面的例子中会首先启动一个MapReduce job对表t和表c进行连接操作；然后再启动一个MapReduce job将第一个MapReduce job的输出和表s进行连接操作; 然后再继续直到全部操作。

#### 笛卡尔积

满足以下条件将会产生笛卡尔集:

- 没有连接条件
- 连接条件无效、
- 所有表中的所有行互相连接

如果表A、B分别有M、N条数据，其笛卡尔积的结果将有 M*N 条数据;缺省条件下 hive不支持笛卡尔积运算; 

```
hive (default)> set hive.strict.checks.cartesian.product=false;
hive (default)> select * from u1,u2;
```

### 排序子句【重点】

#### 全局排序order by

order by子句出现在select语句的结尾；

order by子句对最终的结果进行排序；

默认使用升序ASC；可以使用DESC，跟在字段名之后表示降序；

order by执行全局排序，只有一个reduce；

```
-- 普通排序
select * from emp order by deptno;

-- 按别名排序
select empno,ename,job,mgr,sal+nvl(comm,0) salcomm,deptno from emp order by salcomm desc;

-- 多列排序
select empno,ename,job,mgr,sal+nvl(comm,0) salcomm,deptno from emp order by dept, salcomm desc;

-- 排序字段要出现在select子句中。以下语句无法执行(因为select子句中缺少deptno)
hive (default)> select empno,ename,job,mgr,sal+nvl(comm,0) salcomm from emp order by deptno, salcomm desc;
FAILED: SemanticException [Error 10004]: Line 1:69 Invalid table alias or column reference 'deptno': (possible column names are: empno, ename, job, mgr, salcomm)
```

#### 每个MR内部排序（sort by）

对于大规模数据而言order by效率低；

在很多业务场景，我们并不需要全局有序的数据，此时可以使用sort by；

sort by为每个reduce产生一个排序文件，在reduce内部进行排序，得到局部有序的结果; 

```
-- 设置reduce个数
set mapreduce.job.reduces=2;

-- 按照工资降序查看员工信息
select * from emp sort by sal desc;

-- 将查询结果导入到文件中（按照工资降序）。生成两个输出文件，每个文件内部数据按工资降序排列
insert overwrite local directory '/data/output/sortsal' select * from emp sort by sal desc;
```

#### 分区排序（distribute by）

distribute by 将特定的行发送到特定的reducer中，便于后继的聚合与排序操作；

distribute by 类似于MR中的分区操作，可以结合sort by操作，使分区数据有序；

distribute by 要写在sort by之前；

```
-- 启动2个reducer task；先按deptno分区，在分区内按 sal+comm 排序
set mapreduce.job.reduces=2;
insert overwrite local directory "/data/output/distby"
select empno,ename,job,deptno,sal+nvl(comm,0) salcomm from emp
distribute by deptno
sort by salcomm desc;
-- 上例中，数据被分到了统一区，看不出分区的结果

-- 将数据分到3个区中，每个分区都有数据
set mapreduce.job.reduces=3;
insert overwrite local directory "/data/output/distby1"
select empno,ename,job,deptno,sal+nvl(comm,0) salcomm from emp
distribute by deptno
sort by salcomm desc;
```

#### cluster by

当distribute by 与 sort by是同一个字段时，可使用cluster by简化语法;

cluster by 只能是升序，不能指定排序规则; 

```
-- 以下sql是等价的
select * from emp distribute by deptno sort by deptno;
select * from emp cluster by deptno;
```

#### 总结 

order by：执行全局排序，效率低；生产环境中慎用

sort by：使数据局部有序(在reduce内部有序)

distribute by：按照指定的条件将数据分组，常与sort by联用，使数据局部有序

cluster by：当distribute by 与 sort by是同一个字段时并且是升序时，可使用cluster by简化语法 