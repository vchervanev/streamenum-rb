sh data/stream.sh  \
  | ruby streamenum.rb \
  -j j_hash_str,j_hash_array,j_hash_bool,j_array_num,j_array_hash,j_deep \
  -l 3 \
  -v \
  >> data/sample-output.json