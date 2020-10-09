module load /usr/bin/python2.7
export PYTHONPATH=$PYTHONPATH:~/.local/lib
export PATH=$PATH:~/.local/bin

export JAVA_OPTIONS="-Xms256M -Xmx512M -XX:MaxPermSize=512M -Djava.awt.headless=true"

shopt -s expand_aliases

source ./Benchmark_Parameters.sh
source ./Benchmark_Macros_Couchbase.sh

version="1.0.3"

if (type clush > /dev/null); then
  alias psh=clush
  alias dshbak=clubak
  CLUSTER_SHELL=1
elif (type pdsh > /dev/null); then
  CLUSTER_SHELL=1
  alias psh=pdsh
fi
parg="-a"

green='\e[0;32m'
red='\e[0;31m'
NC='\e[0m' 

sep='==================================='
hssize=$DATABASE_RECORDS_COUNT
prefix="Records"

if [ -f ./TPCx-IoT-result-"$prefix".log ]; then
   mv ./TPCx-IoT-result-"$prefix".log ./TPCx-IoT-result-"$prefix".log.`date +%Y%m%d%H%M%S`
fi
   
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}Running $prefix test${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}IoT data size is $hssize${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}All Output will be logged to file ./TPCx-IoT-result-$prefix.log${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log

if [ $CLUSTER_SHELL -eq 1 ]
then
   echo -e "${green}$sep${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo -e "${green} Running Cluster Validation Suite${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo -e "${green}$sep${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo "" | tee -a ./TPCx-IoT-result-"$prefix".log

   source ./IoT_cluster_validate_suite.sh | tee -a ./TPCx-IoT-result-"$prefix".log

   echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo -e "${green} End of Cluster Validation Suite${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
else
   echo -e "${red}CLUSH NOT INSTALLED for cluster audit report${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
   echo -e "${red}To install clush follow USER_GUIDE.txt${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
fi

echo -e "${green}Checking if the IoT Data Table exists already ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo $CHECK_IF_TABLE_EXISTS | $SUT_SHELL > log
cat log | grep "Table $IOT_DATA_TABLE does exist"
if [ $? != 0 ] 
then
echo $CREATE_TABLE | $SUT_SHELL
else 
echo -e "${green}**** Table already exists, will not recreate *****" | tee -a ./TPCx-IoT-result-"$prefix".log
fi

rm log
rm driver_host_list.txt 

if [ "$NUM_CLIENTS" -gt "1" ]; then
 echo -e "${green}Running $prefix test with $NUM_CLIENTS clients ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
 num_records_per_client=$(echo "$DATABASE_RECORDS_COUNT/$NUM_CLIENTS" | bc)
 echo $num_records_per_client
else
 echo -e "${green}Running $prefix test with $NUM_CLIENTS client ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
 num_records_per_client=$DATABASE_RECORDS_COUNT
fi
pids=""

mkdir -p confFiles
PWD=$(pwd)
insertstart=0
for ((c=1; c<=$NUM_CLIENTS; c++))
do

    cp ./tpcx-iot/workloads/workloadiot.template ./confFiles/workloadiot-$c
    echo "insertstart="$insertstart >> ./confFiles/workloadiot-$c
    echo "operationcount="$num_records_per_client >> ./confFiles/workloadiot-$c
    insertstart=$(echo "$insertstart+$num_records_per_client+1" | bc)
done

sort client_driver_host_list.txt | uniq >> driver_host_list.txt

j=1
for k in `cat driver_host_list.txt`;
do
scp ./confFiles/workloadiot-$j $k:$PWD/tpcx-iot/workloads/workloadiot
clush -w $k -B "rm -rf $PWD/logs"
clush -w $k -B "mkdir -p $PWD/logs"
j=$(echo $j+1 | bc)
done

for i in `seq 1 2 `;
do
benchmark_result=1

echo -e "${green}$sep${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}Deleting Previous Data - Start - `date`${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo $TRUNCATE_TABLE | $SUT_SHELL

sleep $SLEEP_BETWEEN_RUNS
echo -e "${green}Deleting Previous Data - End - `date`${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}$sep${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log

echo -e "${green}Warmup Run - Start - `date`${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log

echo "cat driver_host_list.txt" | tee -a ./TPCx-IoT-result-"$prefix".log
for x in $(cat driver_host_list.txt)
do
    echo $x | tee -a ./TPCx-IoT-result-"$prefix".log
done

for k in $(cat driver_host_list.txt)
do

echo $DATABASE_CLIENT
echo $WARMUP_RECORDS_COUNT
echo $prefix
echo $i
echo $k
echo $PWD
echo $NUM_INSTANCES_PER_CLIENT
echo $NUM_THREADS_PER_INSTANCE
echo $SUT_PARAMETERS

echo "nohup $PWD/TPC-IoT-client.sh $WARMUP_RECORDS_COUNT $prefix $i $k" | tee -a ./TPCx-IoT-result-"$prefix".log
clush -w $k -B "nohup $PWD/TPC-IoT-client.sh $WARMUP_RECORDS_COUNT $prefix $i $k $DATABASE_CLIENT $PWD $NUM_INSTANCES_PER_CLIENT $NUM_THREADS_PER_INSTANCE $SUT_PARAMETERS workloadiot warmup > $PWD/logs/IoT-Workload-run-time-warmup$i-$k.txt" &
pids="$pids $!"
done

echo "master file pids = $pids" | tee -a ./TPCx-IoT-result-"$prefix".log
wait $pids
echo "All drivers have completed" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}Warmup Run - End - `date`${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log

max=0
# for k in `cat driver_host_list.txt`;
for k in $(cat driver_host_list.txt)
do
t=$(clush -w $k -B "grep 'Total Time' $PWD/logs/TPCx-IoT-result-$prefix-$k-warmup$i.log")
echo $t
n=$(echo $t|awk '{print $13}')
 if (( $(bc <<< "$n > $max") ))
 then
    max="$n"
 fi
done

echo $max
total_time_warmup_in_seconds=$max

echo -e "${green}Measured Run - Start - `date`${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
pids=""

for k in `cat driver_host_list.txt`;
do
echo $k
clush -w $k -B "nohup $PWD/TPC-IoT-client.sh $DATABASE_RECORDS_COUNT $prefix $i $k $DATABASE_CLIENT $PWD $NUM_INSTANCES_PER_CLIENT $NUM_THREADS_PER_INSTANCE $SUT_PARAMETERS workloadiot run > $PWD/logs/IoT-Workload-run-time-run$i-$k.txt" &
pids="$pids $!"
done

echo "master file run pids = $pids"
wait $pids
echo "All drivers have completed" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}Measured Run - End - `date`${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
max=0
for k in `cat driver_host_list.txt`;
do
t=$(clush -w $k -B "grep 'Total Time' $PWD/logs/TPCx-IoT-result-$prefix-$k-run$i.log")
#echo $t
n=$(echo $t|awk '{print $13}')
 if (( $(bc <<< "$n > $max") ))
 then
    max="$n"
 fi
done
echo $max

echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log

start=`date +%s%3N`
echo -e "${green}Starting Data Validation ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
repl=$(./IoTDataCheck.sh)
r="$((repl))"
if [ $repl -lt 2 ]; then
 echo -e  "${red}Data Validation Failure === Replication factor is lower than 2 ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
 benchmark_result=0
else
 echo -e "${green}Data Validation Success === Replication factor is greater than 2 ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log 
fi

echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}Starting count of rows in table ${NC}"| tee -a ./TPCx-IoT-result-"$prefix".log

source ./IoTDataRowCount.sh $i

  echo -e "${green}Data Validation Success === Run result is ok, $num_rows records are inserted  ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log

echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log

end=`date +%s%3N`
total_time_for_validation_in_seconds=`expr $end - $start`
total_time_for_validation=$(echo "scale=3;$total_time_for_validation_in_seconds/1000" | bc)
total_time_in_seconds="$(echo "scale=4;$max" | bc)"
echo "Total time: $total_time_in_seconds"
  
if (($benchmark_result == 1))
then
total_time_in_seconds="$(echo "scale=4;$max" | bc)"

echo -e "${green}Test Run $i : Total Time In Seconds = $total_time_in_seconds ${NC}" | tee -a $PWD/TPCx-IoT-result-"$prefix".log

scale_factor=$hssize
perf_metric=$(echo "scale=4;$scale_factor/$total_time_in_seconds" | bc)
echo -e "${green}$sep============${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}md5sum of core components:${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
md5sum ./TPC-IoT-master.sh ./tpcx-iot/lib/core-0.13.0-SNAPSHOT.jar ./IoT_cluster_validate_suite.sh | tee -a $PWD/TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log

echo -e "${green}$sep============${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}TPCx-IoT Performance Metric (IoTps) Report ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}Test Run $i details : Total Time For Warmup Run In Seconds = $total_time_warmup_in_seconds ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log

echo -e "${green}Test Run $i details : Total Time In Seconds = $total_time_in_seconds ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}                      Total Number of Records = $scale_factor ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}TPCx-IoT Performance Metric (IoTps): $perf_metric ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo "" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${green}$sep============${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
else
echo -e "${red}$sep${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${red}No Performance Metric (IoTps) as some tests Failed ${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log
echo -e "${red}$sep${NC}" | tee -a ./TPCx-IoT-result-"$prefix".log

fi  


done
