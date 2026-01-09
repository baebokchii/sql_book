-- Active: 1767840625700@@127.0.0.1@3306@sql_for_data_analysis
DROP TABLE IF EXISTS legislators;

CREATE TABLE legislators (
  full_name VARCHAR(255),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  middle_name VARCHAR(100),
  nickname VARCHAR(100),
  suffix VARCHAR(50),

  other_names_end DATE,
  other_names_middle VARCHAR(100),
  other_names_last VARCHAR(100),

  birthday DATE,
  gender VARCHAR(20),

  id_bioguide VARCHAR(20) PRIMARY KEY,
  id_bioguide_previous_0 VARCHAR(20),

  id_govtrack INT,
  id_icpsr INT,

  id_wikipedia VARCHAR(255),
  id_wikidata VARCHAR(50),
  id_google_entity_id VARCHAR(50),

  id_house_history BIGINT,
  id_house_history_alternate INT,
  id_thomas INT,
  id_cspan INT,
  id_votesmart INT,

  id_lis VARCHAR(20),
  id_ballotpedia VARCHAR(255),
  id_opensecrets VARCHAR(50),

  id_fec_0 VARCHAR(20),
  id_fec_1 VARCHAR(20),
  id_fec_2 VARCHAR(20)
);