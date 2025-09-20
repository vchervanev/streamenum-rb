create table enum_recs(
  id serial primary key,
  num integer,
  str text,
  j_hash_str jsonb,
  j_hash_array jsonb,
  j_hash_bool jsonb,
  j_array_num jsonb,
  j_array_hash jsonb,
  j_deep jsonb
);


insert into enum_recs(num, str, j_hash_str, j_hash_array, j_hash_bool, j_array_num, j_array_hash, j_deep) values
(1, 'one', '{"a": "A", "b": "B"}', '{"a": ["A"], "b": ["B"]}', '{"a": true, "b": false}', '[1, 2, 3]', '[{"a": 1}, {"b": 2}]', '{"a": {"b": {"c": {"d": 1}}}}'),
(1, 'one', '{"a": "AA", "b": "BB"}', '{"a": ["AA"], "b": ["B"]}', '{"a": false, "b": true}', '[11, 2, 33]', '[{"a": 1}, {"b": 22}]', '{"a": {"b": {"c": {"d": 1}}}}'),
(9, 'nine', '{"a": "AA", "b": "B"}', '{"a": ["AA"], "b": ["BB"]}', '{"a": true, "b": true}', '[1, 22, 3]', '[{"a": 11}, {"b": 2}]', '{"a": {"b": {"c": {"d": 2}}}}');
