#!/bin/bash
set -eu
stage=1
BPE_units=1500

. path.sh
. parse_options.sh


if [ "$stage" -le 0 ]; then
  mkdir -p data/lm_prep
  echo "LM training data"
  # NOTE: Need to remove first column from the text, as that is the Kaldi uttid
  local/preprocess_lm_data.py <(cut -f2- -d" " 'peters-data/all_cleaned/text') > data/lm_prep/plain_text
  echo "LM dev data"
  local/preprocess_lm_data.py <(cut -f2- -d" " 'peters-data/yle-dev-new/text') > data/lm_prep/plain_text.valid
fi

if [ "$stage" -le 1 ]; then
  echo "BPE: $BPE_units"
  local/run_bpe.sh --num_units $BPE_units
  local/apply_bpe_model.sh \
    --num_units $BPE_units \
    data/lm_prep/plain_text.valid data/lm_prep/valid.bpe."$BPE_units"
fi

if [ "$stage" -le 2 ]; then
  echo "Train LM"
  local/train_varikn.sh \
    "cat data/lm_prep/text.bpe.$BPE_units" \
    "cat data/lm_prep/valid.bpe.$BPE_units" \
    exp/varikn.bpe."$BPE_units"
fi

if [ "$stage" -le 3 ]; then
  echo "Compute perplexity"
  perplexity --arpa exp/varikn.bpe."$BPE_units"/varikn.lm.gz \
    data/lm_prep/valid.bpe."$BPE_units" \
    exp/varikn.bpe."$BPE_units"/valid_perplexity
  cat exp/varikn.bpe."$BPE_units"/valid_perplexity
fi
