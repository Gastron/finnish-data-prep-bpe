#!/bin/bash
# Runs an already estimated BPE model on some other data.
# NOTE: you need the sentencepiece tool, installable from source.
# Put the tool into path.sh or local_path.sh if using kaldi-utensils
lm_data_dir='data/lm_prep'
num_units=1500

. cmd.sh
. path.sh
. parse_options.sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <file-to-process> <outfile>"
  exit 1
fi

infile=$1
outfile=$2

modeldir="exp/bpe"
mkdir -p $modeldir

$train_cmd "$lm_data_dir"/log/spm_encode_"$num_units"_$(basename $infile).log \
  spm_encode --model="$modeldir"/bpe."$num_units".model \
  --output_format=piece \< $infile \> $outfile 
