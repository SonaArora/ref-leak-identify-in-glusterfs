#!/bin/bash

echo -e "\nEnter the no. for the function which you wants to probe. Press\n
1. dict_ref
2. inode_ref
3. fd_ref"
read func_no

while [ 1 ]
do
    if [ $func_no == 1 ]
    then
        func_name="dict_ref"
        func_name_unref="dict_unref"
        break
    elif [ $func_no == 2 ]
    then
        func_name="__inode_ref"
        func_name_unref="__inode_unref"
        break
    elif [ $func_no == 3 ]
    then
        func_name="__fd_ref"
        func_name_unref="__fd_unref"
        break
    else
        echo -e "\nWrong choice. Enter among the mentioned no."
        read func_no
    fi
done

echo -e "\nEnter Process Id :"
read pid_gluster

status=1

#checking process id is valid or not.

while [ $status ]
do
    if [ -d /proc/$pid_gluster ]
    then
        process=$(cat /proc/$pid_gluster/comm)
        if [[ $process == "gluster"* ]]
        then
            break
        else
            echo -e "$pid_gluster is not a gluster process. Enter an active gluster process id"
            read pid_gluster
        fi
    else
       echo -e "$pid_gluster is not an active process. Enter an active process's id."
       read pid_gluster
    fi
done

dir=/var/run/gluster/leak-output
if [ ! -d $dir ]
then
    mkdir $dir
fi

echo -e "\nEnter the output filename : "
echo -e "(Default path for output file is : /var/run/gluster/leak-output/ )"
read output_file

echo -e "\nEnter probing time interval in minutes : "
echo -e "( Default is 15 minutes )"
read probe_time

#checking probe_time, if empty assign default value
if [ -z "$probe_time" ]
then
    probe_time=900
else
    probe_time=$(( probe_time * 60 ))
fi

gluster_version=`gluster --version | cut -d ' ' -f 2 | grep dev`

#list of client and server xlators

client_module=( /usr/local/lib/glusterfs/$gluster_version/xlator/cluster/dht.so /usr/local/lib/glusterfs/$gluster_version/xlator/cluster/afr.so /usr/local/lib/glusterfs/$gluster_version/xlator/protocol/client.so /usr/local/lib/glusterfs/$gluster_version/xlator/debug/io-stats.so /usr/local/lib/libgfrpc.so.0.0.1 /usr/local/lib/glusterfs/$gluster_version/xlator/meta.so /usr/local/lib/glusterfs/$gluster_version/rpc-transport/socket.so /usr/local/lib/glusterfs/$gluster_version/xlator/mount/fuse.so /usr/lib64/libpthread-2.24.so /usr/lib64/libc-2.24.so /usr/local/lib/glusterfs/$gluster_version/xlator/performance/io-threads.so )

server_module=( /usr/local/lib/glusterfs/$gluster_version/xlator/cluster/dht.so /usr/local/lib/glusterfs/$gluster_version/xlator/cluster/afr.so /usr/local/lib/glusterfs/$gluster_version/xlator/protocol/client.so /usr/local/lib/glusterfs/$gluster_version/xlator/debug/io-stats.so /usr/local/lib/libgfrpc.so.0.0.1 /usr/local/lib/glusterfs/$gluster_version/xlator/meta.so )

#choosing appropriate modules on the basis of type of process

if [ $process == glusterfs ]
then
module=("${client_module[@]}")
elif [ $process == glusterfsd -o $process == glusterd ]
then
module=("${server_module[@]}")
fi

input_file="/root/ex/ref-leak-identify.stp"

#preparing command

com1="stap"
com2=""
com3=" -d "

for val in "${module[@]}"
do
    com2=$com2$com3$val
done

com4=" -g --suppress-time-limits -DMAXSTRINGLEN=900 -S 40,100 -o "
com5=$dir"/"$output_file
com6=" -v "$input_file" -x "$pid_gluster
com7=" "$func_name" "$func_name_unref" "$probe_time

full_com=$com1$com2$com4$com5$com6$com7
echo -e "\n$full_com"
eval "$full_com"
