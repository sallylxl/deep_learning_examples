#!/bin/bash

set -x
GPU_NUMS=${GPU_NUMS:-8}
if [ $GPU_NUMS -eq 8 ];then
    WORKER_NUMS=0
    WORLD_SIZE=1
else
    WORKER_NUMS=$((GPU_NUMS / 8 -1))
    WORLD_SIZE=$((GPU_NUMS / 8))
fi

MODEL="gpt3_5b_2k_bf16" 
DEEP_LEARNING_EXAMPLES_DIR=${DEEP_LEARNING_EXAMPLES_DIR:-"/workspace/deep_learning_examples"} 
BASE_RESULTS_DIR=${BASE_RESULTS_DIR:-${DEEP_LEARNING_EXAMPLES_DIR}/results}

TP=${TP:-1}
PP=${PP:-1}
SEQ_LEN=2048
GBS=${GBS:-2048}
MBS=${MBS:-4}
# Check if the world_size is divisable by TP * PP
global_world_size=$((WORLD_SIZE * 8))
divisor=$((TP * PP))
if (( global_world_size % divisor != 0 )); then
        echo "global_world_size ${global_world_size} is not divisible by TP ${TP} * PP ${PP}"
        exit 1
fi

# Check if the GBS is divisable by MBS * DP
DP=$((global_world_size / divisor))
divisor=$((DP * MBS))
if (( GBS % divisor != 0 )); then
        echo "global batch size ${GBS} is not divisible by micro batch size (${MBS}) times data parallel size (${DP})"
        coefficient=$((GBS / divisor + 1))
        GBS=$((coefficient * divisor))
        echo "Set GBS=${GBS}"
fi

MAX_STEPS=${MAX_STEPS:-128}
ENABLE_CKPT=${ENABLE_CKPT:-0}
RUN_ID=$(date +"%m%dt%H%M%S")

envsubst_py=$(echo "`pwd`" |awk -F 'launcher_scripts' '{print $1"/launcher_scripts/envsubst.py"}')

JOB_PREFIX=$(echo $MODEL | sed 's/_/-/g') \
GBS=${GBS} ENABLE_CKPT=${ENABLE_CKPT} \
RANK="\$RANK" GPU_NUMS=${GPU_NUMS} WORKER_NUMS=${WORKER_NUMS} RUN_ID=${RUN_ID} \
CMD="cd ${DEEP_LEARNING_EXAMPLES_DIR}/training/Megatron-DeepSpeed/llm && \
    DEEP_LEARNING_EXAMPLES_DIR=${DEEP_LEARNING_EXAMPLES_DIR} BASE_RESULTS_DIR=${BASE_RESULTS_DIR} \
    RUN_ID=${RUN_ID} GBS=$GBS MBS=$MBS PP=$PP TP=$TP MAX_STEPS=${MAX_STEPS} \
    ENABLE_CKPT=${ENABLE_CKPT} \
    bash run_ds_${MODEL}.sh" \
python3 $envsubst_py -i pytorchjob-nemo.yaml.template -o pytorchjob-nemo.yaml

kubectl apply -f pytorchjob-nemo.yaml
