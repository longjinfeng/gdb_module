#!/bin/bash

#**********Const variable****************#
log_path="/data/Logs/Log.0"
pmedia_process="android.process.media"
ptvservice="com.mstar.tv.service"
pcomletvxx="com.letv.*"
pcomstvxx="com.stv.*"
mount_point=

#********Judge whether have anr**********#
is_anr()
{
  file_anr=`ls $log_path |busybox grep anr`

  if [[ "$file_anr" != "" ]];then
      echo 1
  else
      echo 0
  fi

}

#**Judge the traces.txt whether deadlock*#
is_deadlock()
{
  log_path_anr="$log_path""/anr"
  
  lock_fail_str=`find $log_path_anr -name traces* -type f -exec grep -E 'MsOS_LockMutex|pthread_mutex_lock_with_timeout' {} \;`
  
  if [[ "$lock_fail_str" != "" ]];then
	echo 1
  else
        echo 0
  fi

}

#*******Get the processes pids**********#
get_some_pids()
{
  ps | grep $pmedia_process>>/tmp/dumpstack.txt
  ps | grep $ptvservice>>/tmp/dumpstack.txt
  ps | grep $pcomletvxx>>/tmp/dumpstack.txt
  ps | grep $pcomstvxx>>/tmp/dumpstack.txt

  dumppids=`cat /tmp/dumpstack.txt | busybox awk -F" " '{print $2}'`

  echo "PIDs are $dumppids"
  rm -rf /tmp/dumpstack.txt
}

#*****shell cmd:debuggerd -b <pid>*****#
dumpstack()
{ 
  oldIFS=$IFS
  IFS='
  '
  for tmp in $dumppids
  do
    echo "pid is $tmp"
    debuggerd -b $tmp>> /data/dumpallstack.txt
  done	

  IFS=$oldIFS
}

#********get mount point*********#
get_mount_point()
{
   mount_point=`mount | grep usb | busybox awk -F" " '{print $2}'`
   echo $mount_point
}

#********************************#
#***cp the dumpstack to usb *****#
#********************************#
f_looper()
{
  while true
  do
    sleep 4
    echo "in the dumpallstack while looper"   
    tmp=$(is_anr)
    echo $tmp
    if [ "$tmp" == "1" ];then
        echo "Got a anr in the logs"
        log_path_anr="$log_path""/anr"
        echo $log_path_anr
	tmp=$(is_deadlock)
	if [[ "$tmp" == "1" ]];then
	  echo "Is deadlock"
	  get_some_pids
          dumpstack
	  mount_point=$(get_mount_point)
	  echo "aaaaaaaaaaaaaa $mount_point"
          cp -f /data/dumpallstack.txt $mount_point
	  break
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
