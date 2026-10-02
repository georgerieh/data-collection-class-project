-- -- https://github.com/metabrainz/musicbrainz-server/blob/master/admin/sql/CreateTables.sql - scripts taken from official source
-- Find all /Users/{user}/ occurences and change it to your path. This build is tested on Mac, and not on Windows/Linux.
-- from here: https://data.metabrainz.org/pub/musicbrainz/data/fullexport/20260930-002222/ (if not accessible, select the latest here: https://data.metabrainz.org/pub/musicbrainz/data/fullexport/)
-- download mbdump-derived.tar.bz2 and mbdump.tar.bz2. 
-- Do so only if you have 100GB free of storage
-- uncomment everything
-- It will take more than 10 minutes 

CREATE TABLE IF NOT EXISTS track ( -- replicate (verbose)
    id                  SERIAL,
    gid                 UUID NOT NULL,
    recording           INTEGER NOT NULL, -- references recording.id
    medium              INTEGER NOT NULL, -- references medium.id
    position            INTEGER NOT NULL,
    number              TEXT NOT NULL,
    name                VARCHAR NOT NULL,
    artist_credit       INTEGER NOT NULL, -- references artist_credit.id
    length              INTEGER CHECK (length IS NULL OR length > 0),
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_data_track       BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE artist ( -- replicate (verbose)
    id                  SERIAL,
    gid                 UUID NOT NULL,
    name                VARCHAR NOT NULL,
    sort_name           VARCHAR NOT NULL,
    begin_date_year     SMALLINT,
    begin_date_month    SMALLINT,
    begin_date_day      SMALLINT,
    end_date_year       SMALLINT,
    end_date_month      SMALLINT,
    end_date_day        SMALLINT,
    type                INTEGER, -- references artist_type.id
    area                INTEGER, -- references area.id
    gender              INTEGER, -- references gender.id
    comment             VARCHAR(255) NOT NULL DEFAULT '',
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended               BOOLEAN NOT NULL DEFAULT FALSE
      CONSTRAINT artist_ended_check CHECK (
        (
          -- If any end date fields are not null, then ended must be true
          (end_date_year IS NOT NULL OR
           end_date_month IS NOT NULL OR
           end_date_day IS NOT NULL) AND
          ended = TRUE
        ) OR (
          -- Otherwise, all end date fields must be null
          (end_date_year IS NULL AND
           end_date_month IS NULL AND
           end_date_day IS NULL)
        )
      ),
    begin_area          INTEGER, -- references area.id
    end_area            INTEGER -- references area.id
);

CREATE TABLE IF NOT EXISTS artist_credit_name ( -- replicate (verbose)
    artist_credit       INTEGER NOT NULL, -- PK, references artist_credit.id CASCADE
    position            SMALLINT NOT NULL, -- PK
    artist              INTEGER NOT NULL, -- references artist.id CASCADE
    name                VARCHAR NOT NULL,
    join_phrase         TEXT NOT NULL DEFAULT ''
);

copy track FROM '/Users/{user}/Downloads/mbdump/mbdump/track' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');
copy artist FROM '/Users/{user}/Downloads/mbdump/mbdump/artist' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');
copy artist_credit_name FROM '/Users/{user}/Downloads/mbdump/mbdump/artist_credit_name' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');


CREATE TABLE recording ( -- replicate (verbose)
    id                  SERIAL,
    gid                 UUID NOT NULL,
    name                VARCHAR NOT NULL,
    artist_credit       INTEGER NOT NULL, -- references artist_credit.id
    length              INTEGER CHECK (length IS NULL OR length > 0),
    comment             VARCHAR(255) NOT NULL DEFAULT '',
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    video               BOOLEAN NOT NULL DEFAULT FALSE
);


CREATE TABLE release_group ( -- replicate (verbose)
    id                  SERIAL,
    gid                 UUID NOT NULL,
    name                VARCHAR NOT NULL,
    artist_credit       INTEGER NOT NULL, -- references artist_credit.id
    type                INTEGER, -- references release_group_primary_type.id
    comment             VARCHAR(255) NOT NULL DEFAULT '',
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
	last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW()

);

CREATE TABLE release_group_meta ( -- replicate
    id                  INTEGER NOT NULL, -- PK, references release_group.id CASCADE
    release_count       INTEGER NOT NULL DEFAULT 0,
    first_release_date_year   SMALLINT,
    first_release_date_month  SMALLINT,
    first_release_date_day    SMALLINT,
    rating              SMALLINT CHECK (rating >= 0 AND rating <= 100),
    rating_count        INTEGER
);

copy recording FROM '/Users/{user}/Downloads/mbdump/mbdump/recording' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');
copy release_group FROM '/Users/{user}/Downloads/mbdump/mbdump/release_group' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');
copy release_group_meta FROM '/Users/{user}/Downloads/mbdump-derived/mbdump/release_group_meta' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');

CREATE TABLE tag ( -- replicate (verbose)
    id                  SERIAL,
    name                VARCHAR(255) NOT NULL,
    ref_count           INTEGER NOT NULL DEFAULT 0
);


CREATE TABLE recording_tag ( -- replicate (verbose)
    recording           INTEGER NOT NULL, -- PK, references recording.id
    tag                 INTEGER NOT NULL, -- PK, references tag.id
    count               INTEGER NOT NULL,
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

copy tag FROM '/Users/{user}/Downloads/mbdump-derived/mbdump/tag' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');
copy recording_tag FROM '/Users/{user}/Downloads/mbdump-derived/mbdump/recording_tag' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');


CREATE TABLE medium ( -- replicate (verbose)
    id                  SERIAL,
    release             INTEGER NOT NULL, -- references release.id
    position            INTEGER NOT NULL,
    format              INTEGER, -- references medium_format.id
    name                VARCHAR NOT NULL DEFAULT '',
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    track_count         INTEGER NOT NULL DEFAULT 0,
    gid                 UUID NOT NULL
);

CREATE TABLE release ( -- replicate (verbose)
    id                  SERIAL,
    gid                 UUID NOT NULL,
    name                VARCHAR NOT NULL,
    artist_credit       INTEGER NOT NULL, -- references artist_credit.id
    release_group       INTEGER NOT NULL, -- references release_group.id
    status              INTEGER, -- references release_status.id
    packaging           INTEGER, -- references release_packaging.id
    language            INTEGER, -- references language.id
    script              INTEGER, -- references script.id
    barcode             VARCHAR(255),
    comment             VARCHAR(255) NOT NULL DEFAULT '',
    edits_pending       INTEGER NOT NULL DEFAULT 0 CHECK (edits_pending >= 0),
    quality             SMALLINT NOT NULL DEFAULT -1,
    last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

copy medium FROM '/Users/{user}/Downloads/mbdump/mbdump/medium' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');
copy release FROM '/Users/{user}/Downloads/mbdump/mbdump/release' WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\b', NULL E'\\N');

CREATE INDEX IF NOT EXISTS idx_medium_pk ON medium (id);
CREATE INDEX IF NOT EXISTS idx_medium_release ON medium (release);
CREATE INDEX IF NOT EXISTS idx_release_pk ON release (id);
CREATE INDEX IF NOT EXISTS idx_release_rg ON release (release_group);
CREATE INDEX IF NOT EXISTS idx_acn_credit ON artist_credit_name (artist_credit, position);


CREATE TABLE temp_view AS (
    SELECT 
        t.id AS track_id,
        t.name AS track_name,
        a.name AS artist_name,
        -- Calculate the minimum year, month, and day safely across releases
        CONCAT_WS('-', 
            MIN(CASE WHEN rgm.first_release_date_year BETWEEN 1800 AND 2026 THEN rgm.first_release_date_year END),
            LPAD(MIN(CASE WHEN rgm.first_release_date_year BETWEEN 1800 AND 2026 THEN rgm.first_release_date_month END)::text, 2, '0'),
            LPAD(MIN(CASE WHEN rgm.first_release_date_year BETWEEN 1800 AND 2026 THEN rgm.first_release_date_day END)::text, 2, '0')
        ) AS first_release_date,
        tg.genres
    FROM track t
    -- 1. Get Primary Artist Name
    LEFT JOIN artist_credit_name acn 
           ON t.artist_credit = acn.artist_credit AND acn.position = 0
    LEFT JOIN artist a 
           ON acn.artist = a.id

    -- 2. Direct FK chain to Release Group Meta
    LEFT JOIN medium m 
           ON t.medium = m.id
    LEFT JOIN release rel 
           ON m.release = rel.id
    LEFT JOIN release_group_meta rgm 
           ON rel.release_group = rgm.id

    -- 3. Pre-aggregated genres per recording
    LEFT JOIN (
        SELECT rt.recording, string_agg(tg.name, ', ') AS genres
        FROM recording_tag rt
        JOIN tag tg ON rt.tag = tg.id
        GROUP BY rt.recording
    ) tg ON t.recording = tg.recording

    -- Group by unique track, artist, and genre attributes
    GROUP BY t.id, t.name, a.name, tg.genres
);

COPY (SELECT * FROM temp_view WHERE genres iS not null AND  SUBSTRING(first_release_date FROM '\d{4}')::integer BetWEEN 2025 and 2026 ORDER BY SUBSTRING(first_release_date FROM '\d{4}')::integer DESC LIMIT 100) TO '/Users/iamgeorgerieh/Downloads/track_enriched.csv' WITH (FORMAT csv, HEADER true);
	