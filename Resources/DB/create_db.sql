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

