#!/bin/bash

#**********Const variable****************#
log_path="/data/Logs/Log.0"
pmedia_process="android.process.media"
ptvservice="com.mstar.tv.service"
pcomletvxx="com.letv.*"
pcomstvxx="com.stv.*"


#********Judge whether have anr**********#
is_anr()
{
  file_an=`ls $log_path | grep anr`

  if [ "$file_anr" != "" ];then
      return 1
  fi

  return 0
}

#**Judge the traces.txt whether deadlock*#
is_deadlock()
{
  log_path_anr=$log_path."/anr"
  lock_fail_str=`ls log_path_anr | busybox xargs grep -E MsOS_LockMutex|__pthread_mutex_lock_with_timeout`
  
  if [ "$lock_fail_str" != "" ];then
	return 1
  fi  

  return 0
}

#*******Get the processes pids**********#
get_some_pids()
{
  ps | grep $pmedia_process>>/tmp/dumpstack.txt
  ps | grep $ptvservice>>/tmp/dumpstack.txt
  ps | grep $pcomletvxx>>/tmp/dumpstack.txt
  ps | grep $pcomstvxx>>/tmp/dumpstack.txt

  dumppids=`cat /tmp/dumpstack.txt | busybox awk -F" " '{print $2}'`

  rm -rf /tmp/dumpstack.txt
}

#*****shell cmd:debuggerd -b <pid>*****#
dumpstack()
{ 
  oldIFS=$IFS
  IFS="\n"
  for tmp in $dumppids
  do
    debuggerd -b $tmp>> /data/dumpallstack.txt
  done	

  IFS=$oldIFS
}

#********get mount point*********#
get_mount_point()
{
   mount_point= `mount | grep usb | busybox awk -F" " '{print $2}'`
}

#********************************#
#***cp the dumpstack to usb *****#
#********************************#
f_looper()
{
  while true
  do
    sleep 4
    
    is_anr
    if [ $? == 1 ];then
	is_deadlock
	if [ $? == 1 ];then
	  get_some_pids
          dumpstack
	  get_mount_point
          cp /data/dumpallstack.txt $mount_point
	  return
	fi
    fi

    
  done
}

#*************************************#
#**      Main function              **#
#*************************************#

f_looper

if [ $? != 0 ];then
   echo "There are some errors in the bash..."
fi

#************ end*********************#
