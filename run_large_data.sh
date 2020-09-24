#!/bin/bash
set -eu
stage=1
BPE_units=15000

. path.sh
. parse_options.sh


if [ "$stage" -le 0 ]; then
  mkdir -p data/large_lm_prep
  echo "LM training data"
  local/preprocess_lm_data.py <(xzcat psmit-lm-data/kielipankki.xz) > data/large_lm_prep/plain_text
  echo "LM dev data"
  local/preprocess_lm_data.py <(xzcat psmit-lm-data/parl-transcripts.xz) > data/large_lm_prep/plain_text.valid
fi

if [ "$stage" -le 1 ]; then
  echo "BPE: $BPE_units"
  local/run_bpe.sh --num_units $BPE_units \
      --modeldir exp/bpe_large \
      --lm_data_dir data/large_lm_prep
  local/apply_bpe_model.sh \
    --num_units $BPE_units \
    --modeldir exp/bpe_large \
    data/large_lm_prep/plain_text.valid data/large_lm_prep/valid.bpe."$BPE_units"
fi

if [ "$stage" -le 2 ]; then
  echo "Train LM"
  local/train_varikn.sh \
    "cat data/large_lm_prep/text.bpe.$BPE_units" \
    "cat data/large_lm_prep/valid.bpe.$BPE_units" \
    exp/large.varikn.bpe."$BPE_units"
fi

if [ "$stage" -le 3 ]; then
  echo "Compute perplexity"
  perplexity --arpa exp/large.varikn.bpe."$BPE_units"/varikn.lm.gz \
    data/large_lm_prep/valid.bpe."$BPE_units" \
    exp/large.varikn.bpe."$BPE_units"/valid_perplexity
  cat exp/varikn.bpe."$BPE_units"/valid_perplexity
fi
