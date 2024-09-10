#!/bin/bash

set -x
GPU_NUMS=${GPU_NUMS:-128}
if [ $GPU_NUMS -eq 8 ];then
    WORKER_NUMS=0
    WORLD_SIZE=1
else
    WORKER_NUMS=$((GPU_NUMS / 8 -1))
    WORLD_SIZE=$((GPU_NUMS / 8))
fi

MODEL="llama2_70b_bf16"
DEEP_LEARNING_EXAMPLES_DIR=${DEEP_LEARNING_EXAMPLES_DIR:-"/workspace/deep_learning_examples"}
BASE_RESULTS_DIR=${BASE_RESULTS_DIR:-${DEEP_LEARNING_EXAMPLES_DIR}/results}

DEEP_LEARNING_EXAMPLES_DIR=${DEEP_LEARNING_EXAMPLES_DIR} \
BASE_RESULTS_DIR=${BASE_RESULTS_DIR} \
TP=${TP:-4} \
PP=${PP:-4} \
CP=0 \
SEQ_LEN=4096 \
GBS=${GBS:-2048} \
MBS=${MBS:-1} \
MAX_STEPS=${MAX_STEPS:-128} \
JOB_PREFIX=$(echo $MODEL | sed 's/_/-/g') \
MODEL=${MODEL} \
RUN_ID=$(date +"%m%dt%H%M%S") \
ENABLE_CKPT=${ENABLE_CKPT:-0} \
UB_TP_COMM_OVERLAP=${UB_TP_COMM_OVERLAP:-0} \
GPU_TYPE=${GPU_TYPE:-h100} \
WORLD_SIZE=$WORLD_SIZE RANK="\$RANK" GPU_NUMS=${GPU_NUMS} WORKER_NUMS=${WORKER_NUMS} \
        envsubst < pytorchjob-nemo.yaml.template |kubectl apply -f -
