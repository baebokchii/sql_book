-- Active: 1767840625700@@127.0.0.1@3306@sql_for_data_analysis
DROP table if exists legislators_terms;
CREATE TABLE legislators_terms (
  id_bioguide VARCHAR(20),
  term_number INT,
  term_id VARCHAR(50) PRIMARY KEY,
  term_type VARCHAR(20),
  term_start DATE,
  term_end DATE,
  state VARCHAR(10),
  district INT,
  `class` INT,
  party VARCHAR(50),
  how VARCHAR(100),
  url VARCHAR(255),
  address VARCHAR(255),
  phone VARCHAR(50),
  fax VARCHAR(50),
  contact_form VARCHAR(255),
  office VARCHAR(100),
  state_rank VARCHAR(50),
  rss_url VARCHAR(255),
  caucus VARCHAR(100)
);


