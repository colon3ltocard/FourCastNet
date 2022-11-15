#!/bin/sh

set -eu

CWD=$(basename "$PWD")
CONTAINER_NAME="fourcastnet"
CONFIG="$PWD"/config
WEIGHTS_DIR=/media/frank/data/FourCastNet/FCN_weights_v0
OUTPUT_DIR=/media/frank/data/FourCastNet/inference_results
STATS_DIR=/media/frank/data/FourCastNet/stats_v0
OOS_DIR=/media/frank/data/FourCastNet/out_of_sample

build() {
    docker build . --tag "$CONTAINER_NAME" --build-arg dev_id=$(id -u)  --build-arg labia_gid=$(id -g) -f docker/Dockerfile.mf
}

clean() {
    docker system prune -f
}

dev() {
    docker run --rm --gpus=all --entrypoint=/bin/bash \
        -v $CONFIG:/home/guibertf/fourcastnet/config \
        -v $WEIGHTS_DIR:/home/guibertf/fourcastnet/weights \
	    -v $OUTPUT_DIR:/home/guibertf/fourcastnet/inference_results \
	    -v $STATS_DIR:/home/guibertf/fourcastnet/stats_v0 \
	    -v $OOS_DIR:/home/guibertf/fourcastnet/out_of_sample \
        -it "$CONTAINER_NAME"
}
run() {
    shift
    docker run --rm --gpus=all \
        -v $CONFIG:/home/guibertf/fourcastnet/config \
        -v $WEIGHTS_DIR:/home/guibertf/fourcastnet/weights \
	    -v $OUTPUT_DIR:/home/guibertf/fourcastnet/inference_results \
	    -v $STATS_DIR:/home/guibertf/fourcastnet/stats_v0 \
	    -v $OOS_DIR:/home/guibertf/fourcastnet/out_of_sample \
        -it "$CONTAINER_NAME"
}

tests() {
    docker run --rm --gpus=all \
        -v $SCRATCHDIR:/home/huggingface/.cache/huggingface \
        -v $OUTPUTDIR:/home/huggingface/output \
        "$CWD" "abstract art"
    docker run --rm --gpus=all \
        -v $SCRATCHDIR:/home/huggingface/.cache/huggingface \
        -v $OUTPUTDIR:/home/huggingface/output \
        "$CWD" --model "runwayml/stable-diffusion-v1-5" \
            --H 512 --W 512 --n_samples 2 --n_iter 2 --seed 42 \
            --scale 7.5 --ddim_steps 80 --attention-slicing \
            --half --skip --negative-prompt "red roses" \
            --prompt "bouquet of roses"
}

case ${1:-build} in
    build) build ;;
    clean) clean ;;
    dev) dev "$@" ;;
    run) run "$@" ;;
    test) tests ;;
    *) echo "$0: No command named '$1'" ;;
esac

