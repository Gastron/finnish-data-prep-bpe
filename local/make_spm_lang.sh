#!/bin/bash
# This script creates a dict directory for utils/prepare_lang.sh
# It also creates the important lexicon_placeholders.txt file
# which is used by subword-kaldi/local/make_lfst_spm.py

set -eu

prepare_lang_extra_opts= #Use for "--phone-symbol-table data/lang/phones.txt"

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ "$#" -ne 3 ]; then
   echo "Usage: $0 vocab dict_dir lang_dir"
   echo "e.g.:  $0 data/train/vocab data/dict data/lang_spm"
   exit 1;
fi

vocab=$1
dictdir=$2
langdir=$3

mkdir -p $dictdir 
mkdir -p tmp
tmpdir=$(mktemp -d -p tmp)

echo "SIL" > ${tmpdir}/silence_phones.txt
echo "SPN" >> ${tmpdir}/silence_phones.txt
echo "NSN" >> ${tmpdir}/silence_phones.txt
sort -u < ${tmpdir}/silence_phones.txt > ${dictdir}/silence_phones.txt
echo "SIL" > ${dictdir}/optional_silence.txt

# Filter special tokens from vocab:
sed -e '/^<unk>$/d' -e '/^<s>$/d' -e '/^<\/s>$/d' -e '/^▁$/d' <${vocab} > ${tmpdir}/vocab.filtered

subword-kaldi/local/make_spm_lexicon.py \
  --g2p-cmd "phonetisaurus-g2pfst --model=data/g2p/g2p_wfsa --print_scores=false --wordlist={filepath} | sed 's/\t$/\tSPN/'" \
   ${tmpdir}/vocab.filtered > ${dictdir}/lexicon.txt 

# Add <unk> and the sentencepiece space back. SOS/EOS are added by utils/prepare_lang.sh
echo -e "<unk>\tSPN" >> ${dictdir}/lexicon.txt
echo -e "▁\tSIL" >> ${dictdir}/lexicon.txt

# Filter the lexicon for a list of phones.
cut -f2- < ${dictdir}/lexicon.txt | tr ' ' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d' | sort -u | grep -v -F -f ${dictdir}/silence_phones.txt > ${dictdir}/nonsilence_phones.txt

subword-kaldi/local/make_spm_lexicon.py \
  --g2p-cmd "phonetisaurus-g2pfst --model=data/g2p/g2p_wfsa --print_scores=false --wordlist={filepath} | sed 's/\t$/\tSPN/'" \
  --add-placeholders \
  ${tmpdir}/vocab.filtered > ${dictdir}/lexicon_placeholders.txt

# Add just <unk>  to placeholder lexicon. The sentencepiece space is handled by subword-kaldi/local/make_lfst_spm.py
echo -e "<unk>\tSPN" >> ${dictdir}/lexicon_placeholders.txt

# Now, dict directory is ready.
rm -Rf ${tmpdir}

extra=3 #Need 3 extra disambig symbols for sentencepiece
utils/prepare_lang.sh --num-extra-phone-disambig-syms $extra ${dictdir} "<unk>" ${langdir}/local ${langdir} 

# Overwrite L_disambig.fst
subword-kaldi/local/make_lfst_spm.py $(tail -n$extra ${langdir}/phones/disambig.txt) \
  --lexicon-file ${langdir}/local/lexiconp_disambig.txt ${dictdir}/lexicon_placeholders.txt |\
  fstcompile --isymbols=${langdir}/phones.txt --osymbols=${langdir}/words.txt --keep_isymbols=false --keep_osymbols=false |\
  fstaddselfloops  ${langdir}/phones/wdisambig_phones.int ${langdir}/phones/wdisambig_words.int |\
  fstarcsort --sort_type=olabel > ${langdir}/L_disambig.fst
