create table if not exists loc_staging (
  state string,
  locid int,
  zip bigint,
  year int
) row format delimited fields terminated by '|' stored as textfile;

LOAD DATA LOCAL INPATH '../../data/files/loc.txt' OVERWRITE INTO TABLE loc_staging;

create table if not exists loc_orc (
  state string,
  locid int,
  zip bigint
) partitioned by(year int) stored as orc;

-- basicStatState: NONE colStatState: NONE
explain extended select * from loc_orc;

set hive.stats.autogather=false;
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;

insert overwrite table loc_orc partition(year) select * from loc_staging;

-- stats are disabled. basic stats will report the file size but not raw data size. so initial statistics will be PARTIAL

-- basicStatState: PARTIAL colStatState: NONE
explain extended select * from loc_orc;

-- partition level analyze statistics for specific parition
analyze table loc_orc partition(year=2001) compute statistics;

-- basicStatState: PARTIAL colStatState: NONE
explain extended select * from loc_orc where year='__HIVE_DEFAULT_PARTITION__';

-- basicStatState: PARTIAL colStatState: NONE
explain extended select * from loc_orc;

-- basicStatState: COMPLETE colStatState: NONE
explain extended select * from loc_orc where year=2001;

-- partition level analyze statistics for all partitions
analyze table loc_orc partition(year) compute statistics;

-- basicStatState: COMPLETE colStatState: NONE
explain extended select * from loc_orc where year='__HIVE_DEFAULT_PARTITION__';

-- basicStatState: COMPLETE colStatState: NONE
explain extended select * from loc_orc;

-- basicStatState: COMPLETE colStatState: NONE
explain extended select * from loc_orc where year=2001 or year='__HIVE_DEFAULT_PARTITION__';

-- both partitions will be pruned
-- basicStatState: NONE colStatState: NONE
explain extended select * from loc_orc where year=2001 and year='__HIVE_DEFAULT_PARTITION__';

-- partition level partial column statistics
analyze table loc_orc partition(year=2001) compute statistics for columns state,locid;

-- basicStatState: COMPLETE colStatState: NONE
explain extended select zip from loc_orc;

-- basicStatState: COMPLETE colStatState: PARTIAL
explain extended select state from loc_orc;

-- column statistics for __HIVE_DEFAULT_PARTITION__ is not supported yet. Hence colStatState reports PARTIAL
-- basicStatState: COMPLETE colStatState: PARTIAL
explain extended select state,locid from loc_orc;

-- basicStatState: COMPLETE colStatState: COMPLETE
explain extended select state,locid from loc_orc where year=2001;

-- basicStatState: COMPLETE colStatState: NONE
explain extended select state,locid from loc_orc where year!=2001;

-- basicStatState: COMPLETE colStatState: PARTIAL
explain extended select * from loc_orc;
