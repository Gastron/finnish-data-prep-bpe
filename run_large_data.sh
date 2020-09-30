#!/bin/bash
set -eu
stage=1
BPE_units=15000


. cmd.sh
. path.sh
. parse_options.sh


if [ "$stage" -le 0 ]; then
  echo "Preprocessing LM data..."
  mkdir -p data/large_lm_prep
  echo "...LM training data"
  local/preprocess_lm_data.py <(xzcat psmit-lm-data/kielipankki.xz) > data/large_lm_prep/plain_text
  echo "...LM dev data"
  local/preprocess_lm_data.py <(cut -f2- -d" " 'peters-data/yle-dev-new/text') > data/large_lm_prep/plain_text.valid
fi

if [ "$stage" -le 1 ]; then
  echo "Estimating sentencepiece BPE and segmenting training data"
  echo "Number of units: $BPE_units"
  local/run_bpe.sh --num_units $BPE_units \
      --modeldir exp/bpe_large \
      --lm_data_dir data/large_lm_prep
fi

if [ "$stage" -le 2 ]; then
  echo "Applying BPE on dev data"
  local/apply_bpe_model.sh \
    --num_units $BPE_units \
    --modeldir exp/bpe_large \
    data/large_lm_prep/plain_text.valid data/large_lm_prep/valid.bpe."$BPE_units"
fi

if [ "$stage" -le 3 ]; then
  echo "Training Varigram KN LM"
  local/train_varikn.sh \
    --cmd "$train_cmd --mem 16G --num-threads 4 --time 24:0:0" \
    "cat data/large_lm_prep/text.bpe.$BPE_units" \
    "cat data/large_lm_prep/valid.bpe.$BPE_units" \
    exp/large.varikn.bpe."$BPE_units"
fi

if [ "$stage" -le 4 ]; then
  echo "Computing log likelihood on dev data"
  echo "    Note that variKN perplexity estimation"
  echo "    cannot handle sentencepiece word boundaries"
  echo "    so the reported perplexity is per token"
  echo "    (not comparable between different segmentations)"
  perplexity --arpa exp/large.varikn.bpe."$BPE_units"/varikn.lm.gz \
    data/large_lm_prep/valid.bpe."$BPE_units" \
    exp/large.varikn.bpe."$BPE_units"/valid_perplexity
  cat exp/large.varikn.bpe."$BPE_units"/valid_perplexity
fi
