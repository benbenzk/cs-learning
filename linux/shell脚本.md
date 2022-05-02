#### shell脚本

- 定义：把单个命令按照一定的逻辑和规则，组装到一个文件中，后面执行的时候就可以直接执行到这个文件

- 脚本后缀：约定俗称以.sh结尾，不强制

- 第一行内容：#!/bin/bash，表示将shell的执行环境引入

- 示例：hello.sh

  ```
  #!/bin/bash
  # first command
  echo hello
  ```

  ```
  # hello.sh为只读权限
  [root@bigdata01 ~]# ls -ll hello.sh
  -rw-r--r-- 1 root root 39 9月  18 01:15 hello.sh
  ```

- 执行：sh hello.sh或bash hello.sh或./hello.sh

  1. 其实sh和bash在之前是对应两种类型的shell，不过后来统一了，我们就不再区分了，所以在shell脚本中第一行引入/bin/bash，或者/bin/sh都是一样的。

  2. 很多资料都会说需要先给脚本添加执行权限，然后才能执行，为什么sh和bash直接可以执行？指定sh或bash执行hello.sh脚本，表示把hello.sh脚本中的内容作为参数直接传给了sh命令来执行，所以这个脚本有没有执行权限就无所谓了

  3. 执行./hello.sh会报`-bash: ./hello.sh: 权限不够`的错误信息，赋予脚本权限即可`chmod u+x hello.sh`

- **单步执行 - 方便调试**

  ```
  [root@bigdata01 ~]# bash -x hello.sh
  + echo hello
  hello
  ```

  

**hello.sh问题？？？**

```
[root@bigdata01 ~]# hello.sh
-bash: hello.sh: command not found
```

解决：

```
[root@bigdata01 ~]# vi /etc/profile

# 增加配置
export PATH=.:$PATH
```

然后生效环境变量`source /etc/profile`即可



#### shell变量

- shell为弱类型语言，变量不需要声明，初始化也不需要指定类型

- 变量命名只能使用数字、字母和下划线，且不能以数字开头

- 变量赋值是通过`=`赋值，在变量、等号和值之间不能出现空格！

  ```
  [root@bigdata01 ~]# name=zhangsan
  ```

- 打印变量的值，通过`echo`命令

  ```
  # 变量简化写法 $name
  [root@bigdata01 ~]# echo $name
  zhangsan
  # 变量完整写法${name}
  [root@bigdata01 ~]# echo ${name}
  zhangsan
  
  # 完整写法后面拼接字符串111
  [root@bigdata01 ~]# echo ${name}111
  zhangsan111
  # 简化写法则打印空，表示是一个变量name111
  [root@bigdata01 ~]# echo $name111
  
  # 如果拼接的字符串开头为空字符串
  [root@bigdata01 ~]# echo $name 111
  zhangsan 111
  ```

**变量分类**

1. 本地变量

   - 格式： VAR_NAME=VALUE

   - 生效范围：只对当前shell进程有效，关闭shell进程就失效了，对当前shell进程的子进程和其它shell进程无效。我们开启一个shell的命令行窗口就是开启了一个shell进程，子进程可以在原有窗口执行`bash`表示一个字进程，执行`exit`即可退出字进程

   - 使用pstree命令查看当前进程树信息

     ```
     [root@bigdata01 ~]# yum install -y psmisc
     ```

2. 环境变量

   - 格式：export VAR_NAME=VALUE

   - 用于设置临时环境变量，关闭当前shell进程后就环境变量失效。

   - 生效范围：对当前进程和子进程有效，对其它shell进程无效。

   - 临时生效，shell进程关闭后失效

     ```
     root@bigdata01 ~]# export age=18
     [root@bigdata01 ~]# echo $age
     18
     ```

   - 永久生效，通过配置文件/etc/profile生效

     ```
     [root@bigdata01 ~]# vi /etc/profile
     
     # 增加以下配置
     export age=19
     ```

     通过`source /etc/profile`生效

3. 位置变量

   如果我们想给shell脚本动态的传递一些参数，这个时候我们就需要用到位置变量，类似于`$0 $1 $2`  

   - 脚本执行格式：test.bash ab cd ef

   - 脚本测试

     ```
     [root@bigdata01 ~]# cat test.bash
     #!/bin/bash
     echo $0
     echo $1
     echo $2
     echo $3
     # 执行脚本
     [root@bigdata01 ~]# sh test.bash ab cd
     test.bash
     ab
     cd
     
     ```

   - 变量结果说明

     $0：脚本名称

     $1：脚本后面的第1个参数

     $2：脚本后面的第2个参数

     $3：脚本后面的第三个参数，没有传递为空

     多个参数使用空格分割

4. 特殊变量

   - `$?`：表示是上一条命令的状态码，范围在0～255。命令执行成功，返回状态码为0，如果失败则在1～255之间，不同的状态码表示不同的错误信息

     ```
     [root@bigdata01 ~]# echo 1
     1
     [root@bigdata01 ~]# echo $?
     0
     
     [root@bigdata01 ~]# name
     -bash: name: 未找到命令
     [root@bigdata01 ~]# echo $?
     127
     ```

     **常用状态码**

     | 状态码 | 描述                     |
     | ------ | ------------------------ |
     | 0      | 命令成功结束             |
     | 1      | 通用未知错误             |
     | 2      | 误用shell命令            |
     | 126    | 命令不可执行             |
     | 127    | 没有找到命令             |
     | 128    | 无效退出参数             |
     | 128+x  | linux信号x的严重错误     |
     | 130    | 命令通过ctrl+c控制码越界 |
     | 255    | 退出码越界               |

   - `$#`: 获取shell脚本传递参数的个数

     ```
     [root@bigdata01 ~]# cat paramnum.sh
     #!/bin/bah
     echo $#
     
     [root@bigdata01 ~]# sh paramnum.sh 1 2 3 4
     4
     ```

     

**变量和引号的特殊使用**

- 单引号`''`：不解析变量

  ```
  [root@bigdata01 ~]# name=zhangsan
  [root@bigdata01 ~]# echo '$name'
  $name
  ```

- 双引号`""`：解析变量

  ```
  [root@bigdata01 ~]# echo "$name"
  zhangsan
  ```

- 反引号：执行反引号内值的命令

  ```
  [root@bigdata01 ~]# name=pwd
  # 反引号首先获取$name的值pwd，然后去执行这个值的命令
  [root@bigdata01 ~]# echo `$name`
  /root
  ```

  反引号的另一种写法

  ```
  [root@bigdata01 ~]# echo $($name)
  /root
  ```

- 特殊案例，获取`'pwd'`这个字符串

  ```
  [root@bigdata01 ~]# echo '"$name"'
  "$name"
  [root@bigdata01 ~]# echo "'$name'"
  'pwd'
  ```




#### for循环

for循环有2种格式

1. 适合迭代多次，步长一致的情况

   ```
   for((i=0;i<10;i++))
   do
   循环体
   done
   ```

   例：for1.bash

   ```
   #!/bin/bash
   for((i=0;i<10;i++))
   do
   echo $i
   done
   ```

   do也可以和for写在一行，只是需要加一个分号

   ```
   #!/bin/bash
   for((i=0;i<10;i++));do
   echo $i
   done
   ```

2. 适合没有规律的列表，或者是有限的几种情况进行迭代是比较方便的

   ```
   for i in 1 2 3
   do
   循环体...
   done
   ```

   例：

   ```
   #!/bin/bash
   for i in 1 2 3
   do
   echo $i
   done
   ```



#### while循环

主要适用于循环次数未知，或不便于使用for直接生成较大列表时的情况

while循环的格式

```
while 测试条件
do
循环体...
done
```

注意：这里的测试条件为“真”则进入循环，测试条件为假则退出循环

**测试条件支持两种格式**

1. test EXPR
2. [ EXPR ]，中括号和表达式之间的空格不能少

EXPR表达式里面写的就是具体的比较逻辑，shell中的比较有一些不同之处，针对整型数据和字符串数据是不一样的

- 整型测试：-gt(大于)、-lt(小于)、-ge(大于等于)、-le(小于等于)、-eq(等于)、-ne(不等于)

  针对整型数据，需要用整形测试中的gt、lt等写法，而不是`>`和`<`，这里需要注意

- 字符串测试：=(等于)、!=(不等于)

整型测试例：

```
#!/bin/bash
while test 2 -gt 1
do
echo yes
sleep 1
done
```

或

```
#!/bin/bash
while [ 2 -gt 1 ]
do
echo yes
sleep 1
done
```

字符串测试例：

```
#!/bin/bash
while [ 'abc' = 'abc' ]
do
echo equal
sleep 1
done
```

  

#### if判断

1. 单分支

   ```
   if 测试条件
   then
   		选择分支	
   fi
   ```

   测试条件和while中的一致

   例：if1.sh

   ```
   #!/bin/bash
   flag=$1
   if [ $flag -eq 1 ]
   then
   echo one
   fi
   ```

   执行脚本

   ```
   [root@bigdata01 ~]# sh if1.sh 1
   one
   ```

   如果不传参数

   ```
   [root@bigdata01 ~]# sh if1.sh
   if1.sh: 第 3 行:[: -eq: 期待一元表达式
   ```

   那么我可以可以改善脚本

   ```
   #!/bin/bash
   if [ $# -lt 1 ]
   then
   echo 'not found param'
   exit 100
   fi
   
   flag=$1
   if [ $flag -eq 1 ]
   then
   echo one
   fi
   ```

   然后再执行

   ```
   [root@bigdata01 ~]# sh if1.sh
   not found param
   [root@bigdata01 ~]# sh if1.sh 1
   one
   ```

2. 双分支

   ```
   if 测试条件
   then
   		选择分支1
   else
   		选择分支2
   fi
   ```

   例：if2.sh

   ```
   [root@bigdata01 ~]# sh if2.sh
   not found param
   [root@bigdata01 ~]# sh if2.sh 1
   one
   [root@bigdata01 ~]# sh if2.sh 2
   other
   ```

3. 多分支

   ```
   if 测试条件1
   then
   		选择分支1
   elif 测试条件2
   then
   		选择分支2
   ...
   else
   		选择分支n
   fi
   ```

   例：if3.sh

   ```
   #!/bin/bash
   if [ $# -lt 1 ]
   then
   echo 'no param'
   exit 100
   fi
   
   flag=$1
   if [ $flag -eq 1 ]
   then
   echo one
   elif [ $flag -eq 2 ]
   then
   echo two
   elif [ $flag -eq 3 ]
   then
   echo three
   else
   echo 'not support'
   fi
   ```

   运行结果

   ```
   [root@bigdata01 ~]# sh if3.sh
   no param
   [root@bigdata01 ~]# sh if3.sh 1
   one
   [root@bigdata01 ~]# sh if3.sh 2
   two
   [root@bigdata01 ~]# sh if3.sh 3
   three
   [root@bigdata01 ~]# sh if3.sh 4
   not support
   [root@bigdata01 ~]# sh if3.sh 4
   not support
   ```

   

#### shell扩展

- 后台模式运行脚本：`nohup test.sh &`
- 标准输出(1)，标准错误输出(2)，重定向(>或者>>)
- 后台脚本部署`nohup sh hello.sh > /dev/null 2>&1 &`

