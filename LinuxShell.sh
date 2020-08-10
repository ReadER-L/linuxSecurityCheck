#!/bin/bash
#author:reader-l
#####################################################
# 写这个主要是为了2020年护网行动中的Linux基线检查环节，同时为了学习shell编程
REPORTMAINDIR=/tmp/checkDir
mkdir $REPORTMAINDIR
clear
echo "输出结果放在/tmp/checkDir中"
echo " ____________________________________________________________________ "
echo "|                                                                    |"
echo "|                     Linux基线检查脚本                                |"
echo "|                   AUTHOR：reader-l                                  |"
echo "|____________________________________________________________________|"
echo "blog: https://reader-l.github.io"
echo
echo "STARTING >>>>>>"
echo
echo "Running Time: `date |awk '{print $6" "$2" "$3" "$4}'`"
echo
echo "######################################################################"
echo
#####################################################
#第一步，首先确定执行该脚本的用户是root用户。
echo "Are you root?"
echo ""
if [ -f /usr/bin/id ];
then /usr/bin/id | grep "uid=0" > /dev/null 2>&1
    if [ $? -eq 0 ];
    then echo "Yes,you are root !!"
    echo ""
    else 
    echo "su root first please!!"
    echo ""
    exit 
    fi
else
echo "check /usr/bin/id is exist."
exit
fi

#第二步，创建结果存放的log文件

REPORTMAINFILE=$REPORTMAINDIR/report.log


#####################################################
#为了避免重复写入，我们需要判断检查结果文件是否为空
# if [ -s $REPORTMAINFILE ];then
#     echo "文件不为空，如需覆盖，请将文件清空后，再执行该脚本"
#     exit 0
# fi


#####################################################
#第三步，正式开始检查，先检查身份鉴别部分,
echo "***************************"
echo "1.身份鉴别部分检查..."
echo "***************************"
echo "检查是否存在非root账号的账号UID为0的帐号"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo  "检查是否存在拥有高权限的可疑用户，从查看/etc/passwd文件内容入手" >> $REPORTMAINFILE
echo "-----------------------------------------------------" >>$REPORTMAINFILE
cat /etc/passwd >> $REPORTMAINFILE
echo "" >> $REPORTMAINFILE
echo "检查结果如下：">> $REPORTMAINFILE
echo "" >> $REPORTMAINFILE
UIDS=`awk -F[:] 'NR!=1{print $3}' /etc/passwd`
flag=0
for i in $UIDS;do
    if [ $i -eq 0 ];then 
        echo "存在非root账号的账号UID为0的可疑帐号：不符合要求，请整改！！！" >> $REPORTMAINFILE
    else
        flag=1
    fi
done
if [ $flag -eq 1 ];then 
    echo "不存在非root帐号的帐号UID为0的可疑帐号：符合要求" >> $REPORTMAINFILE
fi
echo "[OK!!!]"

#####################################################
echo "***************************"
echo "检查是否存在空密码的帐号..."
echo "***************************"
echo "" >> $REPORTMAINFILE 

echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo "检查是否存在登陆系统的空口令的用户帐号，从查看/etc/passwd和/etc/shadow文件内容入手"  >>$REPORTMAINFILE
echo "-----------------------------------------------------" >>$REPORTMAINFILE
cat /etc/shadow >> $REPORTMAINFILE
echo "" >> $REPORTMAINFILE
echo "检查结果如下：" >> $REPORTMAINFILE
echo "" >> $REPORTMAINFILE
###先查看home directory 主目录，判断有哪些用户帐号登陆，信息存在了/home目录下了。
test=`cat /etc/passwd |grep /home |  awk -F[:] '{print $1}'`
echo "">> $REPORTMAINFILE
echo "这些用户是在/home目录下的:" >> $REPORTMAINFILE
echo $test >> $REPORTMAINFILE
for i in $test;do
    if [ -f /usr/bin/cat ];then
        tmp=`/usr/bin/cat /etc/shadow | grep $i | awk -F[:] '{print $2}'`
        if [ $tmp = 0 ] || [ $tmp = '!' ];then
            echo $i  >> $REPORTMAINFILE
            echo "存在空口令用户帐号，请查看该用户帐号是否危险！！"  >> $REPORTMAINFILE
            echo "" >> $REPORTMAINFILE
        fi
    fi
done
echo "[OK!!]"


#####################################################
echo "***************************"
echo "检查密码策略..."
echo "***************************"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo "检查密码策略">>$REPORTMAINFILE
echo "-----------------------------------------------------" >>$REPORTMAINFILE

if [ -f /etc/login.defs ];then
    grep "^PASS" /etc/login.defs >> $REPORTMAINFILE
    passmax=`cat /etc/login.defs | grep PASS_MAX_DAYS | grep -v "^#" | awk '{print $2}'`
    passmin=`cat /etc/login.defs | grep PASS_MIN_DAYS | grep -v "^#" | awk '{print $2}'`
    passlen=`cat /etc/login.defs | grep PASS_MIN_LEN | grep -v "^#"| awk '{print $2}'`
    passage=`cat /etc/login.defs | grep PASS_WARN_AGE | grep -v "^#" | awk '{print $2}'`
    
    if [ $passmax -le 90 -a $passmax -gt 0 ];then  #&&[ $passmax !="" ]
        echo -e "口令生存周期为${passmax}天:符合要求"  >> $REPORTMAINFILE
    else
        echo -e "口令生存周期为${passmax}天:\033[31m 不符合要求\033[0m,建议设置不大于90天"  >> $REPORTMAINFILE
    fi

    if [ $passmin -eq 0 ] && [ $passmin!="" ];then
        echo -e "口令更改最小时间间隔为${passmin}天:符合要求"  >> $REPORTMAINFILE
    else
        echo -e "口令更改最小时间间隔为${passmin}天:\033[31m 不符合要求\033[0m，建议设置等于0天,这样可以随时修改密码" >> $REPORTMAINFILE
    fi

    if [ $passlen -ge 10 &> /dev/null ];then
        echo -e "口令最小长度为${passlen}:符合要求" >> $REPORTMAINFILE
    else
        echo -e "未正确设置口令最短长度要求：\033[31m不符合要求\033[0m，建议设置最小长度大于等于10">> $REPORTMAINFILE
    fi

    if [ $passage -ge 7 -a $passage -lt $passmax ] && [ $passage!="" ];then
        echo -e "口令过期警告时间天数为${passage}:符合要求" >> $REPORTMAINFILE
    else
        echo -e "口令过期警告时间天数为${passage}:\033[31m 不符合要求\033[0m，密码到期前7天必须提醒" >> $REPORTMAINFILE
    fi
    echo -e "\n"
    
else
    echo "no /etc/login.defs file" >>$REPORTMAINFILE
fi
echo "" >>$REPORTMAINFILE
echo "[OK!!]"

#####################################################
echo "***************************"
echo "查看/etc/pam.d/system-auth文件..."
echo "***************************"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo "查看/etc/pam.d/system-auth文件"  >>$REPORTMAINFILE
echo "-----------------------------------------------------" >>$REPORTMAINFILE
if [ -f /etc/pam.d/system-auth ];then
    cat /etc/pam.d/system-auth >>$REPORTMAINFILE
else
    echo ""
    echo "/etc/pam.d/system-auth文件不存在"
fi
echo "" >>$REPORTMAINFILE
echo "[OK!!!]"


#####################################################

echo "***************************"
echo "2.访问控制部分检查..."
echo "***************************"
echo "***************************"
echo "检查敏感文件的权限..."
echo "***************************"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo -n "检查敏感文件的权限">>$REPORTMAINFILE
echo ""
echo "-----------------------------------------------------" >>$REPORTMAINFILE
if [ -f /etc/passwd ];then
    passwdFile=`ls -l /etc/passwd | awk '{print $1}'`
else
    echo "passwd文件 is not exist"
fi
if [ -f /etc/shadow ];then
    shadowFile=`ls -l /etc/shadow | awk '{print $1}'`
else
    echo "shadow文件 is not exist"
fi
if [ -f /etc/group ];then
    groupFile=`ls -l /etc/group | awk '{print $1}'`
else
    echo "group文件 is not exist"
fi

if [ -f /etc/securetty ];then
    securettyFile=`ls -l /etc/securetty | awk '{print $1}'`
else
    echo "securetty is not exist"
fi

if [ -f /etc/securetty ];then
    serviceFile=`ls -l /etc/services | awk '{print $1}'`
else
    echo "services文件 is not exist"
fi
#file6=`ls -l /etc/xinetd.conf | awk '{print $1}'`
#file7=`ls -l /etc/grub.conf | awk '{print $1}'`
#file8=`ls -l /etc/lilo.conf | awk '{print $1}'`

if [ $passwdFile="-rw-r--r--" ];then
 echo -e "0x4、/etc/passwd文件权限为644:符合要求" >> $REPORTMAINFILE
else
  echo -e "0x4、/etc/passwd文件权限不为644:\033[31m 不符合要求\033[0m，建议设置权限为644" >> $REPORTMAINFILE
fi

if [ $shadowFile="-r--------" ];then
  echo -e "0x5、/etc/shadow文件权限为400:符合要求" >> $REPORTMAINFILE
else
  echo -e "0x5、/etc/shadow文件权限不为400:\033[31m 不符合要求\033[0m，建议设置权限为400" >> $REPORTMAINFILE
fi

if [ $groupFile="-rw-r--r--" ];then
  echo -e "0x6、/etc/group文件权限为644:符合要求" >>$REPORTMAINFILE
else
  echo -e "0x6、/etc/group文件权限不为644:\033[31m 不符合要求\033[0m，建议设置权限为644" >> $REPORTMAINFILE
fi

if [ $securettyFile="-rw-------" ];then
  echo -e "0x7、/etc/security文件权限为600:符合要求" >> $REPORTMAINFILE
else
  echo -e "0x7、/etc/security文件权限不为600:\033[31m 不符合要求\033[0m，建议设置权限为600" >> $REPORTMAINFILE
fi

if [ $serviceFile="-rw-r--r--" ];then
  echo -e "0x8、/etc/services文件权限为644:符合要求" >> $REPORTMAINFILE
else
  echo -e "0x8、/etc/services文件权限不为644:\033[31m 不符合要求\033[0m，建议设置权限为644" >> $REPORTMAINFILE
fi
echo [OK!!!]

###########################################################
echo "***************************"
echo "3.服务端口进程部分检查..."
echo "***************************"
echo "系统端口监听检查中..."
echo "***************************"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo "系统端口监听检查">>$REPORTMAINFILE
echo "-----------------------------------------------------" >>$REPORTMAINFILE
netstat -anplit >>$REPORTMAINFILE
echo ""
echo [OK!!!]

echo -e "\n"
echo "**************************"
echo "系统用户登陆信息统计"
echo "**************************"
echo -e "-----------------------------------------------------" >>$REPORTMAINFILE
echo -e "系统用户登陆检查 " >>$REPORTMAINFILE
echo -e "-----------------------------------------------------" >>$REPORTMAINFILE

last1=`last -15`
echo -e "下表是登陆成功用户信息:\n$last1">>$REPORTMAINFILE
echo -e "——————————————————————————————————————————————————————————————————————————————" >>$REPORTMAINFILE
last2=`lastb -15`
echo -e "下表是远程失败登陆日志:\n$last2" >>$REPORTMAINFILE


echo "***************************"
echo "用service --status-all命令查看服务..."
echo "***************************"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo -n "用service --status-all命令查看服务">>$REPORTMAINFILE
echo ""
echo "-----------------------------------------------------" >>$REPORTMAINFILE
service --status-all >>$REPORTMAINFILE
echo "" >>$REPORTMAINFILE
echo "[OK!!!]"

echo "***************************"
echo "查看进程信息..."
echo "***************************"
echo "-----------------------------------------------------" >>$REPORTMAINFILE
echo "进程信息检查">>$REPORTMAINFILE
echo "-----------------------------------------------------" >>$REPORTMAINFILE
ps -auxww >>$REPORTMAINFILE 2>/dev/null
echo "" >>$REPORTMAINFILE
echo "" >>$REPORTMAINFILE
echo "[OK!!!]"