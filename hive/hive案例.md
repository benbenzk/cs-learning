# Hive案例

## 第1节 需求描述

针对销售数据，完成统计：

1. 按年统计销售额
2. 销售金额在10w以上的订单
3. 每年销售额的差值
4. 年度订单金额前10位（年度、订单号、订单金额、排名）
5. 季度订单金额前10位（年度、季度、订单id、订单金额、排名）
6. 求所有交易日中订单金额最高的前10位
7. 每年度销售额最大的交易日
8. 年度最畅销的商品（即每年销售金额最大的商品）

## 第2节 数据说明

<table>
  <tbody>
    <tr><td colspan=3><b><i>日期表（dimdate）</i></b></td></tr>
    <tr><td>dt</td><td>date</td><td>日期</td></tr>
    <tr><td>yearmonth</td><td>int</td><td>年月</td></tr>
    <tr><td>year</td><td>smallint</td><td>年</td></tr>
    <tr><td>month</td><td>tinyint</td><td>月</td></tr>
    <tr><td>day</td><td>tinyint</td><td>日</td></tr>
    <tr><td>week</td><td>tinyint</td><td>周几</td></tr>
    <tr><td>weeks</td><td>tinyint</td><td>第几周</td></tr>
    <tr><td>quat</td><td>tinyint</td><td>季度</td></tr>
    <tr><td>tendays</td><td>tinyint</td><td>旬</td></tr>
    <tr><td>halfmonth</td><td>tinyint</td><td>半月</td></tr>
    <tr><td colspan=3><b><i>订单表（sale）</i></b></td></tr>
    <tr><td>orderid</td><td>string</td><td>订单号</td></tr>
    <tr><td>locationid</td><td>string</td><td>交易位置</td></tr>
    <tr><td>dt</td><td>date</td><td>交易日期</td></tr>
    <tr><td colspan=3><b><i>订单销售明细表（saledetail）</i></b></td></tr>
    <tr><td>orderid</td><td>string</td><td>订单号</td></tr>
    <tr><td>rownum</td><td>int</td><td>行号</td></tr>
    <tr><td>itemid</td><td>string</td><td>货品</td></tr>
    <tr><td>num</td><td>int</td><td>数量</td></tr>
    <tr><td>price</td><td>double</td><td>单价</td></tr>
    <tr><td>amount</td><td>double</td><td>金额</td></tr>
  </tbody>
</table>

## 第3节 实现

1. 创建表SQL

   createtable.sql，将数据存放在ORC文件中

   ```sql
   drop database sale cascade;
   create database if not exists sale;
   
   create table sale.dimdate_ori(
     dt date,
     yearmonth int,
     year smallint,
     month tinyint,
     day tinyint,
     week tinyint,
     weeks tinyint,
     quat tinyint,
     tendays tinyint,
     halfmonth tinyint
   )row format delimited fields terminated by ",";
   
   create table sale.sale_ori(
     orderid string,
     locationid string,
     dt date
   )row format delimited fields terminated by ",";
   
   create table sale.saledetail_ori(
     orderid string,
     rownum int,
     goods string,
     num int,
     price double,
     amount double
   )row format delimited fields terminated by ",";
   
   
   create table sale.dimdate(
     dt date,
     yearmonth int,
     year smallint,
     month tinyint,
     day tinyint,
     week tinyint,
     weeks tinyint,
     quat tinyint,
     tendays tinyint,
     halfmonth tinyint
   ) stored as orc;
   
   create table sale.sale(
     orderid string,
     locationid string,
     dt date
   ) stored as orc;
   
   create table sale.saledetail(
     orderid string,
     rownum int,
     goods string,
     num int,
     price double,
     amount double
   ) stored as orc;
   ```

   执行sql

   ```shell
   hive -f createtable.hql
   ```

2. 数据导入

   loaddata.sql

   ```sql
   -- 加载数据
   use sale;
   load data local inpath "/root/data/tbDate.dat" overwrite into table dimdate_ori;
   load data local inpath "/root/data/tbSale.dat" overwrite into table sale_ori;
   load data local inpath "/root/data/tbSaleDetail.dat" overwrite into table saledetail_ori;
   
   -- 导入数据
   insert into table dimdate select * from dimdate_ori;
   insert into table sale select * from sale_ori;
   insert into table saledetail select * from saledetail_ori;
   ```

   执行sql

   ```
   hive -f loaddata.hql
   ```

3. SQL实现

   ```sql
   -- 1.按年统计销售额
   select year(B.dt) year, round(sum(A.amount)/10000, 2) amount
   	from saledetail A join sale B on A.orderid=B.orderid
    group by year(B.dt);
    
   -- 2.销售金额在 10W 以上的订单
   select orderid, round(sum(amount)/10000, 2) amount
   	from saledetail
    group by orderid
   having sum(amount)>100000;
   
   -- 3.每年销售额的差值
   with tmp as(
     select year(B.dt) year, sum(A.amount) amount
     	from saledetail A join sale B on A.orderid=B.orderid
   	 group by year(B.dt)
   )
   select year, round(amount/10000, 2) amount,
   			 round(nvl(lag(amount) over(order by year), 0)/10000, 2) preamount,
   			 round(nvl(amount - lag(amount) over(order by year), 0)/10000, 2) diff
   	from tmp;
   -- 4.年度订单金额前10位（年度、订单号、订单金额、排名）
   with tmp as(
     select year(B.dt) year, B.orderid, sum(A.amount) amount
   		from saledetail A join sale B on A.orderid=B.orderid
    	 group by year(B.dt),B.orderid
   )
   select year, orderid, round(amount, 2) amount, rank
   	from (
       select year, orderid, amount, 
       			 dense_rank() over(partition by year order by amount desc) rank
       	from tmp
     ) as tmp2
    where rank<=10;
   
   -- 5.季度订单金额前10位（年度、季度、订单id、订单金额、排名）
   with tmp as (
     select year(B.dt) year,
   			 	 case when month(B.dt) <=3 then 1
   			 				when month(B.dt) <=6 then 2
   			 				when month(B.dt) <=9 then 3
   			 				else 4 end quat,
   			 	 B.orderid,
   			 	 sum(A.amount) amount
   		from sale A join saledetail B on A.orderid=B.orderid
    	 group by year(B.dt),
    				 case when month(B.dt) <=3 then 1
   			 				when month(B.dt) <=6 then 2
   			 				when month(B.dt) <=9 then 3
   			 				else 4 end, B.orderid
   )
   select year, quat, round(amount/10000, 2), rank
   	from(
       select year, quat, amount,
       			 dense_rank() over(partition by year, quat order by amount desc) rank
       	from tmp
     ) tmp2
    where rank <= 10;
   
   -- 6.求所有交易日中订单金额最高的前10位
   with tmp as (
   select A.dt, A.orderid, round(sum(B.amount), 2) amount
     from sale A join saledetail B on A.orderid=B.orderid
   group by A.dt, A.orderid
   )
   select dt, orderid, amount, rank
   from(
     select dt, orderid, amount, dense_rank() over(order by amount desc) rank
     	from tmp
   ) tmp1
   where rank <= 10;
   
   -- 7.每年度销售额最大的交易日
   with tmp2 as(
     select year, dt, amount, dense_rank() over(partition by year order by amount desc) rank
    	from(
       select year(A.dt) year, A.dt, sum(B.amount) amount
   			from sale A join saledetail B on A.orderid=B.orderid
    		 group by A.dt
     ) tmp
   )
   select year, dt, round(amount, 2) amount
   	from tmp2
    where rank=1;
   
   -- 8.年度最畅销的商品（即每年销售金额最大的商品）
   with tmp2 as(
     select year, goods, amount, dense_rank() over(partition by year order by amount desc) rank
     	from (
         select year(A.dt) year, B.goods, round(sum(B.amount), 2) amount
         	from sale A join saledetail B on A.orderid=B.orderid
          group by year(A.dt), B.goods
       ) tmp
   )
   select year, goods, amount
   	from tmp2
    where rank=1;
   ```

   



