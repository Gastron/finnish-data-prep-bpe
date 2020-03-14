#!/bin/bash
# Runs the BPE estimation algorithm on data produced by local/preprocess_lm_data.sh
# NOTE: you need the sentencepiece tool, installable from source.
# Put the tool into path.sh or local_path.sh if using kaldi-utensils
lm_data_dir='data/lm_prep'
num_units=1500

. cmd.sh
. path.sh
. parse_options.sh

modeldir="exp/bpe"
mkdir -p $modeldir

$train_cmd "$modeldir"/log/spm_train_"$num_units".log \
  spm_train --input="$lm_data_dir"/plain_text \
  --model_prefix="$modeldir"/bpe.$num_units \
  --vocab_size="$num_units" \
  --character_coverage=1.0 \
  --model_type="bpe"

$train_cmd "$lm_data_dir"/log/spm_encode_"$num_units".log \
  spm_encode --model="$modeldir"/bpe."$num_units".model \
  --output_format=piece \< "$lm_data_dir"/plain_text \> "$lm_data_dir"/text.bpe.$num_units
