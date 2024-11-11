--Create a physical database with a separate database and schema and give it an appropriate domain-related name.
--Use the relational model you've created while studying DB Basics module.
--Task 2 (designing a logical data model on the chosen topic).
--Make sure you have made any changes to your model after your mentor's comments.
--postgresql create databese doesn't function with if exists, but drop does
--so I first drop database if exists and then create it, it is error free,
--minus is that is erase database and data in it - kida brute force
DROP DATABASE IF EXISTS politicalcampaign;

CREATE DATABASE politicalcampaign;

--create types that will be handly later, similar idea with drop like in previous case. 
--I prefer type creation over case because it is better practice in my opinion
DROP TYPE IF EXISTS gender_enum;

CREATE TYPE gender_enum AS enum ('M', 'W');

DROP TYPE IF EXISTS martial_enum;

CREATE TYPE martial_enum AS enum ('Single', 'Widowed', 'Married', 'Divorced');

--next I create tables that are present in logical schema from the elections table going down
--we take only "new" election after 2000 - it is comment also for surveys, problems, volunteer_avabilities
CREATE TABLE IF NOT EXISTS politicalcampaign.public.elections (
 id Serial PRIMARY KEY,
 date Date CHECK (date > '2000-01-01') NOT NULL,
 position varchar(200) NOT NULL
);

--responders_number should be positive and larger than 0 otherwise it doesn't make sense to have survey
CREATE TABLE IF NOT EXISTS politicalcampaign.public.surveys (
 id Serial PRIMARY KEY,
 election_id INT NOT NULL REFERENCES elections(id),
 date Date NOT NULL CHECK (date > '2000-01-01'),
 responders_number INT CHECK (responders_number > 0) NOT NULL,
 subject varchar(200) NOT NULL,
 result text NOT NULL
);

CREATE TABLE IF NOT EXISTS politicalcampaign.public.problems (
 id Serial PRIMARY KEY,
 election_id INT REFERENCES elections(id) NOT NULL,
 occurance_date Date CHECK (occurance_date > '2000-01-01') NOT NULL,
 TYPE varchar(126) NOT NULL,
 description text NOT NULL
);

--net worth should be greater than 0, like in real life  
--also there is an option to generate age based on
--added material status column comparet to the diagram, enum types used 
--full name is generated based on name and surname
CREATE TABLE IF NOT EXISTS politicalcampaign.public.candidates (
 id Serial PRIMARY KEY,
 name varchar(50) NOT NULL,
 surname varchar(50) NOT NULL,
 full_name varchar(101) GENERATED ALWAYS AS (name || ' ' || surname) stored,
 country varchar (216) NOT NULL,
 state varchar(512) NOT NULL,
 city varchar(512) NOT NULL,
 zip_code varchar(30) NOT NULL,
 street varchar(30) NOT NULL,
 building_nummber varchar(30) NOT NULL,
 appartment_number varchar(30) NOT NULL,
 political_party varchar(50) NOT NULL,
 born_date date NOT NULL,
 net_worth int CHECK (net_worth > 0),
 gender gender_enum NOT NULL,
 martial_status martial_enum NOT NULL
);

--budget should be greater than 0, like in real life  
CREATE TABLE IF NOT EXISTS politicalcampaign.public.candidatures (
 candidature_id Serial PRIMARY KEY,
 candidate_id INT REFERENCES candidates(id) NOT NULL,
 election_id INT REFERENCES elections(id) NOT NULL,
 budget INT CHECK (budget > 0) NOT NULL
);

--net worth should be greater than 0, like in real life  
CREATE TABLE IF NOT EXISTS politicalcampaign.public.donors (
 id Serial PRIMARY KEY,
 name varchar(50) NOT NULL,
 surname varchar(50),
 is_private boolean NOT NULL,
 net_worth int CHECK (net_worth > 0)
);

--support value should be greater than 0, otherwise it is not a support
CREATE TABLE IF NOT EXISTS politicalcampaign.public.candidate_donor (
 donor_id INT REFERENCES donors(id) NOT NULL,
 candidate_id INT REFERENCES candidates(id) NOT NULL,
 support_value INT CHECK (support_value > 0) NOT NULL,
 support_description TEXT
);

--number children should be greater than 0, otherwise it is not nice
--net worth should be greater than 0, like in real life  
--enum types used 
--full name is generated based on name and surname
CREATE TABLE IF NOT EXISTS politicalcampaign.public.voters (
 id Serial PRIMARY KEY,
 name varchar(50) NOT NULL,
 surname varchar(50) NOT NULL,
 full_name varchar(101) GENERATED ALWAYS AS (name || ' ' || surname) stored,
 country varchar (216) NOT NULL,
 state varchar(512) NOT NULL,
 city varchar(512) NOT NULL,
 zip_code varchar(30) NOT NULL,
 street varchar(30) NOT NULL,
 building_nummber varchar(30) NOT NULL,
 appartment_number varchar(30) NOT NULL,
 born_date date NOT NULL,
 net_worth int CHECK (net_worth > 0),
 gender gender_enum NOT NULL,
 martial_status martial_enum NOT NULL,
 children int CHECK (children >= 0)
);

--nothing special here, just many to many connection bridge table
CREATE TABLE IF NOT EXISTS politicalcampaign.public.votes (
 voter_id INT REFERENCES voters(id) NOT NULL,
 candidature_id INT REFERENCES candidatures(candidature_id) NOT NULL
);

--budget should be greater than 0, like in real life  
CREATE TABLE IF NOT EXISTS politicalcampaign.public.candidatures (
 id Serial PRIMARY KEY,
 candidature_id INT REFERENCES candidatures(candidature_id) NOT NULL,
 cost INT CHECK (budget > 0) NOT NULL,
 goal VARCHAR(256) NOT NULL,
 descriprion text NOT NULL
);

CREATE TABLE IF NOT EXISTS politicalcampaign.public.volunteers (
 id Serial PRIMARY KEY,
 candidature_id INT REFERENCES candidatures(candidature_id) NOT NULL,
 name varchar(50) NOT NULL,
 surname varchar(50) NOT NULL,
 contact_number varchar(50) NOT NULL,
 email varchar(256) NOT NULL,
 role varchar(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS politicalcampaign.public.tasks (
 id Serial PRIMARY KEY,
 candidature_id INT REFERENCES candidatures(candidature_id) NOT NULL,
 name varchar(256) NOT NULL,
 description text NOT NULL,
 due_date timestamp NOT NULL
);

--nothing special here, just many to many connection bridge table
CREATE TABLE IF NOT EXISTS politicalcampaign.public.volunteer_task (
 volunteer_id INT REFERENCES volunteers(id) NOT NULL,
 task_id INT REFERENCES tasks(id) NOT NULL
);

--times of the day should indicate time gap when volunteer should be able to help with
--elections, end time should be later than start time 
CREATE TABLE IF NOT EXISTS politicalcampaign.public.volunteer_avabilities (
 id Serial PRIMARY KEY,
 volunteer_id INT REFERENCES volunteers(id) NOT NULL,
 date date CHECK (date > '2001-01-01') NOT NULL,
 start_time time NOT NULL,
 end_time time CHECK (end_time > start_time) NOT NULL
);

--every event should have unique name from marketing point of view it makes sense
CREATE TABLE IF NOT EXISTS politicalcampaign.public.events (
 id Serial PRIMARY KEY,
 candidature_id INT REFERENCES candidatures(candidature_id) NOT NULL,
 name varchar(256) NOT NULL UNIQUE,
 description text NOT NULL,
 date date NOT NULL,
 category varchar(256) NOT NULL
);

--I used chatGPT to create sample data for database
-- Insert sample data for elections
INSERT INTO
 politicalcampaign.public.elections (date, position)
VALUES
 ('2024-11-05', 'Presidential Election'),
 ('2024-11-10', 'Senate Election');

-- Insert sample data for surveys
INSERT INTO
 politicalcampaign.public.surveys (
  election_id,
  date,
  responders_number,
  subject,
  result
 )
VALUES
 (
  1,
  '2024-10-15',
  5000,
  'Voter preferences for the Presidential Election',
  'Candidate A leads with 45% of votes'
 ),
 (
  2,
  '2024-10-17',
  3000,
  'Senate Election Approval Rating',
  '50% of voters support the incumbent senator'
 );

-- Insert sample data for problems
INSERT INTO
 politicalcampaign.public.problems (election_id, occurance_date, TYPE, description)
VALUES
 (
  1,
  '2024-10-10',
  'Logistical',
  'Delays in the printing of ballots'
 ),
 (
  2,
  '2024-10-12',
  'Security',
  'Reports of suspicious activity near polling stations'
 );

-- Insert sample data for candidates
INSERT INTO
 politicalcampaign.public.candidates (
  name,
  surname,
  country,
  state,
  city,
  zip_code,
  street,
  building_nummber,
  appartment_number,
  political_party,
  born_date,
  net_worth,
  gender,
  martial_status
 )
VALUES
 (
  'John',
  'Doe',
  'USA',
  'California',
  'Los Angeles',
  '90001',
  'Sunset Blvd',
  '123',
  '45A',
  'Progressive Party',
  '1985-03-12',
  1000000,
  'M',
  'Married'
 ),
 (
  'Jane',
  'Smith',
  'USA',
  'Texas',
  'Dallas',
  '75001',
  'Main St',
  '456',
  '67B',
  'Democratic Party',
  '1990-05-22',
  500000,
  'W',
  'Single'
 );

-- Insert sample data for candidatures
INSERT INTO
 politicalcampaign.public.candidatures (candidate_id, election_id, budget)
VALUES
 (1, 1, 500000),
 (2, 2, 300000);

-- Insert sample data for donors
INSERT INTO
 politicalcampaign.public.donors (name, surname, is_private, net_worth)
VALUES
 ('Michael', 'Green', TRUE, 1000000),
 ('Sarah', 'Blue', FALSE, 500000);

-- Insert sample data for candidate_donor
INSERT INTO
 politicalcampaign.public.candidate_donor (
  donor_id,
  candidate_id,
  support_value,
  support_description
 )
VALUES
 (1, 1, 50000, 'Donation for campaign ads'),
 (2, 2, 30000, 'Fundraising event contribution');

-- Insert sample data for voters
INSERT INTO
 politicalcampaign.public.voters (
  name,
  surname,
  country,
  state,
  city,
  zip_code,
  street,
  building_nummber,
  appartment_number,
  born_date,
  net_worth,
  gender,
  martial_status,
  children
 )
VALUES
 (
  'Emily',
  'White',
  'USA',
  'California',
  'San Francisco',
  '94101',
  'Market St',
  '101',
  '1B',
  '1982-07-22',
  300000,
  'W',
  'Single',
  2
 ),
 (
  'Robert',
  'Black',
  'USA',
  'Texas',
  'Austin',
  '73301',
  'Congress Ave',
  '202',
  '3C',
  '1975-04-15',
  1000000,
  'M',
  'Married',
  3
 );

-- Insert sample data for votes
INSERT INTO
 politicalcampaign.public.votes (voter_id, candidature_id)
VALUES
 (1, 1),
 (2, 2);

-- Insert sample data for volunteers
INSERT INTO
 politicalcampaign.public.volunteers (
  candidature_id,
  name,
  surname,
  contact_number,
  email,
  role
 )
VALUES
 (
  1,
  'Alice',
  'Green',
  '555-1234',
  'alice.green@email.com',
  'Campaign Manager'
 ),
 (
  2,
  'Bob',
  'Blue',
  '555-5678',
  'bob.blue@email.com',
  'Event Coordinator'
 );

-- Insert sample data for tasks
INSERT INTO
 politicalcampaign.public.tasks (candidature_id, name, description, due_date)
VALUES
 (
  1,
  'Create Ads',
  'Design and place campaign ads in newspapers',
  '2024-10-20'
 ),
 (
  2,
  'Host Debate',
  'Arrange a public debate for candidates',
  '2024-10-22'
 );

-- Insert sample data for volunteer_task
INSERT INTO
 politicalcampaign.public.volunteer_task (volunteer_id, task_id)
VALUES
 (1, 1),
 (2, 2);

-- Insert sample data for volunteer_avabilities
INSERT INTO
 politicalcampaign.public.volunteer_avabilities (volunteer_id, date, start_time, end_time)
VALUES
 (1, '2024-10-18', '09:00:00', '17:00:00'),
 (2, '2024-10-20', '08:00:00', '16:00:00');

-- Insert sample data for events
INSERT INTO
 politicalcampaign.public.events (
  candidature_id,
  name,
  description,
  date,
  category
 )
VALUES
 (
  1,
  'Rally at City Park',
  'A rally to gather support for Candidate A',
  '2024-10-18',
  'Campaign Event'
 ),
 (
  2,
  'Fundraiser Gala',
  'A black-tie event to raise funds for the Senate campaign',
  '2024-10-22',
  'Fundraising'
 );

--add record_ts column to every table 
ALTER TABLE
 politicalcampaign.public.elections
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.surveys
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.problems
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.candidates
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.candidatures
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.donors
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.candidate_donor
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.voters
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.votes
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.candidatures
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.volunteers
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.tasks
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.volunteer_task
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.volunteer_avabilities
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
 politicalcampaign.public.events
ADD
 COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

--Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
--Create relationships between tables using primary and foreign keys.
--Apply five check constraints across the tables to restrict certain values, including
--date to be inserted, which must be greater than January 1, 2000
--inserted measured value that cannot be negative
--inserted value that can only be a specific value (as an example of gender)
--unique
--not null
--
--Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
--Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.