#!/bin/bash

export JAVA_OPTIONS="-Xms256M -Xmx512M -XX:MaxPermSize=512M -Djava.awt.headless=true"

echo "Enter client file" | tee -a tmp.log

DATABASE_RECORDS_COUNT=$1
prefix=$2
i=$3
clientId=$4
DATABASE_CLIENT=$5
PWD=$6
NUM_INSTANCES=$7
NUM_THREADS=$8
#echo $NUM_THREADS
SUT_PARAMETERS=$9
WORKLOAD=${10}
LOGFILE_NAME=${11}

mkdir -p ./logs
start=`date +%s%3N`

echo "$PWD $prefix $clientId $LOGFILE_NAME $i" | tee -a tmp.log

echo -e "${green}$sep${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo -e "${green} Running TPCx-IoT Benchmark Suite - Run $i - Epoch $start ${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo -e "${green} TPCx-IoT Version ${version} ${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo -e "${green}$sep${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo "check 1" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
# echo -e "${green}Starting IoT Run $i output being return to $PWD/logs/IoT-run-time-$LOGFILE_NAME$i.txt ${NC}" | tee -a ./TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo -e "${green}Starting IoT Run $i output being return to $PWD/logs/IoT-run-time-$LOGFILE_NAME$i.txt ${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo "check 2" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log

start_string=`grep insertstart $PWD/tpcx-iot/workloads/$WORKLOAD`
INSERT_START=$(echo $start_string | cut -d'=' -f2)
operation_count_string=`grep operationcount $PWD/tpcx-iot/workloads/$WORKLOAD`
DATABASE_RECORDS_COUNT=$(echo $operation_count_string | cut -d'=' -f2)

echo ">>>>>>>> $PWD/TPC-IoT-instances.sh $DATABASE_RECORDS_COUNT $NUM_INSTANCES $NUM_THREADS $INSERT_START $clientId $DATABASE_CLIENT $LOGFILE_NAME"  | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
$PWD/TPC-IoT-instances.sh $DATABASE_RECORDS_COUNT $NUM_INSTANCES $NUM_THREADS $INSERT_START $clientId $DATABASE_CLIENT $PWD $SUT_PARAMETERS $LOGFILE_NAME

result=$?

if [ $result -ne 0 ]; then
 echo -e "${red}======== Error while executing run command database table IoT Workload Result FAILURE========${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
 benchmark_result=0
else
 echo -e "${green}Run Result SUCCESS===All records can be queried and inserted ${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
fi
cat $PWD/logs/IoT-Workload-run-time-$LOGFILE_NAME$i-$clientId.txt >> $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log

echo "" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo "" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo -e "${green}======== Workload IoT Run Result SUCCESS ========${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo -e "${green}======== Time taken by Workload IoT = `grep real $PWD/logs/IoT-Workload-run-time-$LOGFILE_NAME$i.txt | awk '{print $2}'`====${NC}" | tee -a $PWD/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo "" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
echo "" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
end=`date +%s%3N`

total_time=`expr $end - $start`
total_time_in_seconds=$(echo "scale=3;$total_time/1000" | bc)
echo -e "${green}Test Run $i on $clientId details: Total Time = $total_time_in_seconds ${NC}" | tee -a $PWD/logs/TPCx-IoT-result-"$prefix"-"$clientId-$LOGFILE_NAME$i".log
