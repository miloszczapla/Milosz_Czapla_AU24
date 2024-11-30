--Create a physical database with a separate database and schema and give it an appropriate domain-related name.
--Use the relational model you've created while studying DB Basics module.
--Task 2 (designing a logical data model on the chosen topic).
--Make sure you have made any changes to your model after your mentor's comments.
--postgresql create databese doesn't function with if exists, but drop does
--so I first drop database if exists and then create it, it is error free,
--minus is that is erase database and data in it - kida brute force
SELECT
       pg_terminate_backend(pid)
FROM
       pg_stat_activity
WHERE
       datname = 'agency'
       AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS agency;

CREATE DATABASE agency;

--remember to change database afterwards with comand below
--\c agency
--Create Schema
CREATE SCHEMA IF NOT EXISTS political_campaign;

--create types that will be handly later, similar idea with drop like in previous case. 
--I prefer type creation over case because it is better practice in my opinion
--I don't like CASCADE option at all but it is there to comply with task requirments
DROP TYPE IF EXISTS political_campaign.gender_enum CASCADE;

CREATE TYPE political_campaign.gender_enum AS enum ('M', 'W');

DROP TYPE IF EXISTS political_campaign.martial_enum CASCADE;

CREATE TYPE political_campaign.martial_enum AS enum ('Single', 'Widowed', 'Married', 'Divorced');

--next I create tables that are present in logical schema from the elections table going down
--we take only "new" election after 2000 - it is comment  also for surveys, problems, volunteer_avabilities
CREATE TABLE IF NOT EXISTS political_campaign.elections (
       id Serial PRIMARY KEY,
       date Date CHECK (date > '2000-01-01') NOT NULL,
       position varchar(200) NOT NULL
);

--responders_number should be positive and larger than 0 otherwise it doesn't make sense to have survey
CREATE TABLE IF NOT EXISTS political_campaign.surveys (
       id Serial PRIMARY KEY,
       election_id INT NOT NULL REFERENCES political_campaign.elections(id),
       date Date NOT NULL CHECK (date > '2000-01-01'),
       responders_number INT CHECK (responders_number > 0) NOT NULL,
       subject varchar(200) NOT NULL,
       result text NOT NULL
);

CREATE TABLE IF NOT EXISTS political_campaign.problems (
       id Serial PRIMARY KEY,
       election_id INT REFERENCES political_campaign.elections(id) NOT NULL,
       occurance_date Date CHECK (occurance_date > '2000-01-01') NOT NULL,
       TYPE varchar(126) NOT NULL,
       description text NOT NULL
);

--net worth should be greater than 0, like in real life  
--also there is an option to generate age based on
--added material status column comparet to the diagram, enum types used 
--full name is generated based on name and surname
CREATE TABLE IF NOT EXISTS political_campaign.candidates (
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
       gender political_campaign.gender_enum NOT NULL,
       martial_status political_campaign.martial_enum NOT NULL
);

--budget should be greater than 0, like in real life  
CREATE TABLE IF NOT EXISTS political_campaign.candidatures (
       candidature_id Serial PRIMARY KEY,
       candidate_id INT REFERENCES political_campaign.candidates(id) NOT NULL,
       election_id INT REFERENCES political_campaign.elections(id) NOT NULL,
       budget INT CHECK (budget > 0) NOT NULL
);

--net worth should be greater than 0, like in real life  
CREATE TABLE IF NOT EXISTS political_campaign.donors (
       id Serial PRIMARY KEY,
       name varchar(50) NOT NULL,
       surname varchar(50),
       is_private boolean NOT NULL,
       net_worth int CHECK (net_worth > 0)
);

--support value should be greater than 0, otherwise it is not a support
CREATE TABLE IF NOT EXISTS political_campaign.candidate_donor (
       donor_id INT REFERENCES political_campaign.donors(id) NOT NULL,
       candidate_id INT REFERENCES political_campaign.candidates(id) NOT NULL,
       support_value INT CHECK (support_value > 0) NOT NULL,
       support_description TEXT
);

--number children should be greater than 0, otherwise it is not nice
--net worth should be greater than 0, like in real life  
--enum types used 
--full name is generated based on name and surname
CREATE TABLE IF NOT EXISTS political_campaign.voters (
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
       gender political_campaign.gender_enum NOT NULL,
       martial_status political_campaign.martial_enum NOT NULL,
       children int CHECK (children >= 0)
);

--nothing special here, just many to many connection bridge table
CREATE TABLE IF NOT EXISTS political_campaign.votes (
       voter_id INT REFERENCES political_campaign.voters(id) NOT NULL,
       candidature_id INT REFERENCES political_campaign.candidatures(candidature_id) NOT NULL
);

--cost should be greater than 0, like in real life  
CREATE TABLE IF NOT EXISTS political_campaign.costs (
       id Serial PRIMARY KEY,
       candidature_id INT REFERENCES political_campaign.candidatures(candidature_id) NOT NULL,
       cost INT CHECK (cost > 0) NOT NULL,
       goal VARCHAR(256) NOT NULL,
       description text NOT NULL
);

CREATE TABLE IF NOT EXISTS political_campaign.volunteers (
       id Serial PRIMARY KEY,
       candidature_id INT REFERENCES political_campaign.candidatures(candidature_id) NOT NULL,
       name varchar(50) NOT NULL,
       surname varchar(50) NOT NULL,
       contact_number varchar(50) NOT NULL,
       email varchar(256) NOT NULL,
       role varchar(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS political_campaign.tasks (
       id Serial PRIMARY KEY,
       name varchar(256) NOT NULL,
       description text NOT NULL,
       due_date timestamp NOT NULL
);

--nothing special here, just many to many connection bridge table
CREATE TABLE IF NOT EXISTS political_campaign.volunteer_task (
       volunteer_id INT REFERENCES political_campaign.volunteers(id) NOT NULL,
       task_id INT REFERENCES political_campaign.tasks(id) NOT NULL
);

--tpolitical_campaign.imes of the day should indicate time gap when volunteer should be able to help with
--political_campaign., end time should be later than start time 
CREATE TABLE IF NOT EXISTS political_campaign.volunteer_avabilities (
       id Serial PRIMARY KEY,
       volunteer_id INT REFERENCES political_campaign.volunteers(id) NOT NULL,
       date date CHECK (date > '2001-01-01') NOT NULL,
       start_time time NOT NULL,
       end_time time CHECK (end_time > start_time) NOT NULL
);

--every event should have unique name from marketing point of view it makes sense
CREATE TABLE IF NOT EXISTS political_campaign.events (
       id Serial PRIMARY KEY,
       candidature_id INT REFERENCES political_campaign.candidatures(candidature_id) NOT NULL,
       name varchar(256) NOT NULL UNIQUE,
       description text NOT NULL,
       date date NOT NULL,
       category varchar(256) NOT NULL
);

--I used chatGPT to political_campaign.create sample data for database
-- political_campaign.Insert sample data for political_campaign.
-- Ensure political_campaign. political_campaign.do not duplicate
INSERT INTO
       political_campaign.elections(date, position)
SELECT
       '2024-11-05',
       'Presidential Election'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.elections
              WHERE
                     date = '2024-11-05'
                     AND position = 'Presidential Election'
       );

INSERT INTO
       political_campaign.elections(date, position)
SELECT
       '2024-11-10',
       'Senate Election'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.elections
              WHERE
                     date = '2024-11-10'
                     AND position = 'Senate Election'
       );

-- Insert sample data for surveys
INSERT INTO
       political_campaign.surveys (
              election_id,
              date,
              responders_number,
              subject,
              result
       )
SELECT
       id,
       '2024-10-15',
       5000,
       'Voter preferences for the Presidential Election',
       'Candidate A leads with 45%political_campaign. of votes'
FROM
       political_campaign.elections
WHERE
       position = 'Presidential Election'
LIMIT
       1;

INSERT INTO
       political_campaign.surveys (
              election_id,
              date,
              responders_number,
              subject,
              result
       )
SELECT
       id,
       '2024-10-17',
       3000,
       'Senate Election Approval Rating',
       '50% of voters support the incumbent senator'
FROM
       political_campaign.elections
WHERE
       position = 'Senate Election'
LIMIT
       1;

-- Insert sample data for problems
INSERT INTO
       political_campaign.problems (election_id, occurance_date, TYPE, description)
SELECT
       id,
       '2024-10-10',
       'Logistical',
       'Delays in the printing of ballots'
FROM
       political_campaign.elections
WHERE
       position = 'Presidential Election'
LIMIT
       1;

INSERT INTO
       political_campaign.problems (election_id, occurance_date, TYPE, description)
SELECT
       id,
       '2024-10-12',
       'Security',
       'Reports of suspicious activity near polling stations'
FROM
       political_campaign.elections
WHERE
       position = 'Senate Election'
LIMIT
       1;

-- Insert sample data for candidates
INSERT INTO
       political_campaign.candidates (
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
SELECT
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
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.candidates
              WHERE
                     name = 'John'
                     AND surname = 'Doe'
       );

INSERT INTO
       political_campaign.candidates (
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
SELECT
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
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.candidates
              WHERE
                     name = 'Jane'
                     AND surname = 'Smith'
       );

-- Insert sample data for candidatures
-- Inserting candidature for John Doe
INSERT INTO
       political_campaign.candidatures (candidate_id, election_id, budget)
SELECT
       c.id AS candidate_id,
       e.id AS election_id,
       500000 AS budget
FROM
       political_campaign.candidates c
       CROSS JOIN (
              SELECT
                     id
              FROM
                     political_campaign.elections
              WHERE
                     position = 'Presidential Election'
              LIMIT
                     1
       ) e
WHERE
       c.name = 'John'
       AND c.surname = 'Doe'
       AND NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = c.id
                     AND election_id = e.id
       );

-- Inserting candidature for Jane Smith
INSERT INTO
       political_campaign.candidatures (candidate_id, election_id, budget)
SELECT
       c.id AS candidate_id,
       e.id AS election_id,
       300000 AS budget
FROM
       political_campaign.candidates c
       CROSS JOIN (
              SELECT
                     id
              FROM
                     political_campaign.elections
              WHERE
                     position = 'Senate Election'
              LIMIT
                     1
       ) e
WHERE
       c.name = 'Jane'
       AND c.surname = 'Smith'
       AND NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = c.id
                     AND election_id = e.id
       );

-- Insert sample data for donors
INSERT INTO
       political_campaign.donors (name, surname, is_private, net_worth)
SELECT
       'Michael',
       'Green',
       TRUE,
       1000000
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.donors
              WHERE
                     name = 'Michael'
                     AND surname = 'Green'
       );

INSERT INTO
       political_campaign.donors (name, surname, is_private, net_worth)
SELECT
       'Sarah',
       'Blue',
       FALSE,
       500000
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.donors
              WHERE
                     name = 'Sarah'
                     AND surname = 'Blue'
       );

-- Insert sample data for candidate_donor
INSERT INTO
       political_campaign.candidate_donor (
              donor_id,
              candidate_id,
              support_value,
              support_description
       )
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.donors
              WHERE
                     name = 'Michael'
                     AND surname = 'Green'
              LIMIT
                     1
       ), (
              SELECT
                     id
              FROM
                     political_campaign.candidates
              WHERE
                     name = 'John'
                     AND surname = 'Doe'
              LIMIT
                     1
       ), 50000, 'Donation for campaign ads'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.candidate_donor
              WHERE
                     donor_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.donors
                            WHERE
                                   name = 'Michael'
                                   AND surname = 'Green'
                     )
                     AND candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'John'
                                   AND surname = 'Doe'
                     )
       );

INSERT INTO
       political_campaign.candidate_donor (
              donor_id,
              candidate_id,
              support_value,
              support_description
       )
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.donors
              WHERE
                     name = 'Sarah'
                     AND surname = 'Blue'
              LIMIT
                     1
       ) AS donor_id,
       (
              SELECT
                     id
              FROM
                     political_campaign.candidates
              WHERE
                     name = 'John'
                     AND surname = 'Doe'
              LIMIT
                     1
       ) AS candidate_id,
       50000 AS support_value,
       'Donation for campaign ads' AS support_description
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.candidate_donor
              WHERE
                     donor_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.donors
                            WHERE
                                   name = 'Sarah'
                                   AND surname = 'Blue'
                     )
                     AND candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'John'
                                   AND surname = 'Doe'
                     )
       );

-- Insert sample data for voters
INSERT INTO
       political_campaign.voters (
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
SELECT
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
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.voters
              WHERE
                     name = 'Emily'
                     AND surname = 'White'
       );

INSERT INTO
       political_campaign.voters (
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
SELECT
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
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.voters
              WHERE
                     name = 'Robert'
                     AND surname = 'Black'
       );

-- Insert sample data for votes
INSERT INTO
       political_campaign.votes (voter_id, candidature_id)
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.voters
              WHERE
                     name = 'Emily'
                     AND surname = 'White'
              LIMIT
                     1
       ), (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'John'
                                   AND surname = 'Doe'
                            LIMIT
                                   1
                     )
              LIMIT
                     1
       )
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.votes
              WHERE
                     voter_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.voters
                            WHERE
                                   name = 'Emily'
                                   AND surname = 'White'
                     )
                     AND candidature_id = (
                            SELECT
                                   candidature_id
                            FROM
                                   political_campaign.candidatures
                            WHERE
                                   candidate_id = (
                                          SELECT
                                                 id
                                          FROM
                                                 political_campaign.candidates
                                          WHERE
                                                 name = 'John'
                                                 AND surname = 'Doe'
                                   )
                     )
       );

INSERT INTO
       political_campaign.votes (voter_id, candidature_id)
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.voters
              WHERE
                     name = 'Robert'
                     AND surname = 'Black'
              LIMIT
                     1
       ), (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'Jane'
                                   AND surname = 'Smith'
                            LIMIT
                                   1
                     )
              LIMIT
                     1
       )
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.votes
              WHERE
                     voter_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.voters
                            WHERE
                                   name = 'Robert'
                                   AND surname = 'Black'
                     )
                     AND candidature_id = (
                            SELECT
                                   candidature_id
                            FROM
                                   political_campaign.candidatures
                            WHERE
                                   candidate_id = (
                                          SELECT
                                                 id
                                          FROM
                                                 political_campaign.candidates
                                          WHERE
                                                 name = 'Jane'
                                                 AND surname = 'Smith'
                                   )
                     )
       );

-- Insert sample data for costs
INSERT INTO
       political_campaign.costs (candidature_id, cost, goal, description)
SELECT
       c.candidature_id,
       data.cost,
       data.goal,
       data.description
FROM
       (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures ca
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'John'
                                   AND surname = 'Doe'
                     )
                     AND election_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.elections
                            WHERE
                                   position = 'Presidential Election'
                            LIMIT
                                   1
                     )
       ) c
       CROSS JOIN LATERAL (
              VALUES
                     (
                            10000,
                            'Advertising',
                            'TV and social media campaigns'
                     ),
                     (
                            15000,
                            'Staffing',
                            'Hiring campaign staff and volunteers'
                     ),
                     (5000, 'Travel', 'Travel expenses for rallies'),
                     (
                            2000,
                            'Miscellaneous',
                            'Miscellaneous campaign costs'
                     )
       ) AS data (cost, goal, description)
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.costs pc
              WHERE
                     pc.candidature_id = c.candidature_id
                     AND pc.cost = data.cost
                     AND pc.goal = data.goal
                     AND pc.description = data.description
       );

-- Insert sample data for volunteers
INSERT INTO
       political_campaign.volunteers (
              candidature_id,
              name,
              surname,
              contact_number,
              email,
              role
       )
SELECT
       (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'John'
                                   AND surname = 'Doe'
                            LIMIT
                                   1
                     )
              LIMIT
                     1
       ), 'Alice', 'Green', '555-1234', 'alice.green@email.com', 'Campaign Manager'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.volunteers
              WHERE
                     name = 'Alice'
                     AND surname = 'Green'
                     AND email = 'alice.green@email.com'
       );

INSERT INTO
       political_campaign.volunteers (
              candidature_id,
              name,
              surname,
              contact_number,
              email,
              role
       )
SELECT
       (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'Jane'
                                   AND surname = 'Smith'
                            LIMIT
                                   1
                     )
              LIMIT
                     1
       ), 'Bob', 'Blue', '555-5678', 'bob.blue@email.com', 'Event Coordinator'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.volunteers
              WHERE
                     name = 'Bob'
                     AND surname = 'Blue'
                     AND email = 'bob.blue@email.com'
       );

-- Insert sample data for tasks
-- Task for "Create Ads"
INSERT INTO
       political_campaign.tasks (name, description, due_date)
SELECT
       'Create Ads' AS name,
       'Design and place campaign ads in newspapers' AS description,
       '2024-10-20' :: timestamp AS due_date
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.tasks
              WHERE
                     name = 'Create Ads'
                     AND due_date = '2024-10-20' :: timestamp
       );

-- Task for "Host Debate"
INSERT INTO
       political_campaign.tasks (name, description, due_date)
SELECT
       'Host Debate' AS name,
       'Arrange a public debate for candidates' AS description,
       '2024-10-22' :: timestamp AS due_date
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.tasks
              WHERE
                     name = 'Host Debate'
                     AND due_date = '2024-10-22' :: timestamp
       );

-- Insert sample data for volunteer_task
INSERT INTO
       political_campaign.volunteer_task (volunteer_id, task_id)
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.volunteers
              WHERE
                     name = 'Alice'
                     AND surname = 'Green'
              LIMIT
                     1
       ), (
              SELECT
                     id
              FROM
                     political_campaign.tasks
              WHERE
                     name = 'Create Ads'
              LIMIT
                     1
       )
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.volunteer_task
              WHERE
                     volunteer_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.volunteers
                            WHERE
                                   name = 'Alice'
                                   AND surname = 'Green'
                     )
                     AND task_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.tasks
                            WHERE
                                   name = 'Create Ads'
                     )
       );

INSERT INTO
       political_campaign.volunteer_task (volunteer_id, task_id)
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.volunteers
              WHERE
                     name = 'Bob'
                     AND surname = 'Blue'
              LIMIT
                     1
       ), (
              SELECT
                     id
              FROM
                     political_campaign.tasks
              WHERE
                     name = 'Host Debate'
              LIMIT
                     1
       )
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.volunteer_task
              WHERE
                     volunteer_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.volunteers
                            WHERE
                                   name = 'Bob'
                                   AND surname = 'Blue'
                     )
                     AND task_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.tasks
                            WHERE
                                   name = 'Host Debate'
                     )
       );

-- Insert sample data for volunteer_avabilities
INSERT INTO
       political_campaign.volunteer_avabilities (volunteer_id, date, start_time, end_time)
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.volunteers
              WHERE
                     name = 'Alice'
                     AND surname = 'Green'
              LIMIT
                     1
       ), '2024-10-18', '09:00:00', '17:00:00'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.volunteer_avabilities
              WHERE
                     volunteer_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.volunteers
                            WHERE
                                   name = 'Alice'
                                   AND surname = 'Green'
                     )
                     AND date = '2024-10-18'
       );

INSERT INTO
       political_campaign.volunteer_avabilities (volunteer_id, date, start_time, end_time)
SELECT
       (
              SELECT
                     id
              FROM
                     political_campaign.volunteers
              WHERE
                     name = 'Bob'
                     AND surname = 'Blue'
              LIMIT
                     1
       ), '2024-10-20', '08:00:00', '16:00:00'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.volunteer_avabilities
              WHERE
                     volunteer_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.volunteers
                            WHERE
                                   name = 'Bob'
                                   AND surname = 'Blue'
                     )
                     AND date = '2024-10-20'
       );

-- Insert sample data for events
INSERT INTO
       political_campaign.events (
              candidature_id,
              name,
              description,
              date,
              category
       )
SELECT
       (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'John'
                                   AND surname = 'Doe'
                            LIMIT
                                   1
                     )
              LIMIT
                     1
       ), 'Rally at City Park', 'A rally to gather support for Candidate A', '2024-10-18', 'Campaign Event'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.events
              WHERE
                     name = 'Rally at City Park'
                     AND date = '2024-10-18'
       );

INSERT INTO
       political_campaign.events (
              candidature_id,
              name,
              description,
              date,
              category
       )
SELECT
       (
              SELECT
                     candidature_id
              FROM
                     political_campaign.candidatures
              WHERE
                     candidate_id = (
                            SELECT
                                   id
                            FROM
                                   political_campaign.candidates
                            WHERE
                                   name = 'Jane'
                                   AND surname = 'Smith'
                            LIMIT
                                   1
                     )
              LIMIT
                     1
       ), 'Fundraiser Gala', 'A black-tie event to raise funds for the Senate campaign', '2024-10-22', 'Fundraising'
WHERE
       NOT EXISTS (
              SELECT
                     1
              FROM
                     political_campaign.events
              WHERE
                     name = 'Fundraiser Gala'
                     AND date = '2024-10-22'
       );

-- Continue similarly for other `INSERT` statements using SELECT to retrieve foreign keys.
--add record_ts column to every table 
ALTER TABLE
       political_campaign.elections
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.surveys
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.problems
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.candidates
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.candidatures
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.donors
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.candidate_donor
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.voters
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.votes
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.costs
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.volunteers
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.tasks
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.volunteer_task
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.volunteer_avabilities
ADD
       COLUMN IF NOT EXISTS record_ts date DEFAULT current_date NOT NULL;

ALTER TABLE
       political_campaign.events
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