CREATE TABLE history_game (game_id integer,game_name text);
CREATE TABLE history_info (game_id integer,info text);

CREATE TABLE history_import (game_id integer,info_type text,info_data text);

.separator "%%"
.import "./history_converted" history_import

INSERT INTO history_game (game_id,game_name)
SELECT game_id,info_data FROM history_import 
WHERE info_type="name";

INSERT INTO history_info (game_id,info)
SELECT game_id,info_data FROM history_import 
WHERE info_type="info";

CREATE INDEX idx_hg_name on history_game (game_name);
CREATE INDEX idx_hi_id on history_info (game_id);

CREATE TABLE play_stats (game_name text,play_count integer,last_play date,play_time integer,fav integer);
CREATE INDEX idx_ps_name on play_stats (game_name);
CREATE INDEX idx_ps_fav on play_stats (fav);
