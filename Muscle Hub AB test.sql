--MuscleHub Gym did an A/B test where Group A received a fitness test and Group B didn't to see if providing a fitness test let to more applications and more purchases

--joining the tables - this is the funnel
SELECT visits.first_name,
       visits.last_name,
       visits.email,
       visits.gender,
       visits.visit_date,
       fitness_test.fitness_test_date,
       application.application_date,
       purchase.purchase_date
FROM visits
LEFT JOIN
    (SELECT *
    FROM fitness_tests) AS fitness_test
ON visits.email = fitness_test.email
LEFT JOIN
    (SELECT *
    FROM applications) AS application
ON visits.email = application.email
LEFT JOIN
    (SELECT *
    FROM purchases) AS purchase
ON visits.email = purchase.email;

--create new table which will contain the above query    
CREATE TABLE mh_funnel(first_name     VARCHAR,
last_name                             VARCHAR,
email                                 VARCHAR,
gender                                VARCHAR,
visit_date                            DATE,
fitness_test_date                     DATE,
application_date                      DATE,
purchase_date                         DATE); 

--insert funnel query into new table
INSERT INTO mh_funnel(
    SELECT visits.first_name,
       visits.last_name,
       visits.email,
       visits.gender,
       visits.visit_date,
       fitness_test.fitness_test_date,
       application.application_date,
       purchase.purchase_date
FROM visits
LEFT JOIN
    (SELECT *
    FROM fitness_tests) AS fitness_test
ON visits.email = fitness_test.email
LEFT JOIN
    (SELECT *
    FROM applications) AS application
ON visits.email = application.email
LEFT JOIN
    (SELECT *
    FROM purchases) AS purchase
ON visits.email = purchase.email);


--those who had a fitness test are in group A and those who did not are in group B for A/B test. Also adding ones and zeros to count the visits, fitness tests etc
SELECT *, CASE
          WHEN fitness_test_date IS NOT NULL THEN 'A'
          ELSE 'B'
          END AS ab_group, 
          CASE 
          WHEN visit_date IS NOT NULL THEN 1
          ELSE 0
          END AS visit,
          CASE WHEN fitness_test_date IS NOT NULL THEN 1
          ELSE 0
          END AS fitness_test,
          CASE WHEN application_date IS NOT NULL THEN 1
          ELSE 0
          END AS application,
          CASE WHEN purchase_date IS NOT NULL THEN 1
          ELSE 0
          END AS purchase
FROM mh_funnel;

--creating new table to insert the above query into
CREATE TABLE mh_ab_test(first_name    VARCHAR,
last_name                             VARCHAR,
email                                 VARCHAR,
gender                                VARCHAR,
visit_date                            DATE,
fitness_test_date                     DATE,
application_date                      DATE,
purchase_date                         DATE,
ab_group                              VARCHAR,
visit                                 INTEGER,
fitness_test                          INTEGER,
application                           INTEGER,
purchase                              INTEGER);

--inserting query into new table
INSERT INTO mh_ab_test(SELECT *, CASE
          WHEN fitness_test_date IS NOT NULL THEN 'A'
          ELSE 'B'
          END AS ab_group, 
          CASE 
          WHEN visit_date IS NOT NULL THEN 1
          ELSE 0
          END AS visit,
          CASE WHEN fitness_test_date IS NOT NULL THEN 1
          ELSE 0
          END AS fitness_test,
          CASE WHEN application_date IS NOT NULL THEN 1
          ELSE 0
          END AS application,
          CASE WHEN purchase_date IS NOT NULL THEN 1
          ELSE 0
          END AS purchase
FROM mh_funnel);

--viewing the totals at each funnel step
SELECT SUM(visit) AS visit_total, SUM(fitness_test) AS fitness_test_total, SUM(application) AS application_total, SUM(purchase) AS purchase_total
FROM mh_ab_test;

--grouping by A/B group - 2509 people had the fitness test, 2497 did not
SELECT ab_group, COUNT(ab_group)
FROM mh_ab_test
GROUP BY ab_group;

--viewing totals who made an application for membership and purchased a membership in each group
SELECT ab_group, 
       SUM(application) AS application, 
       (COUNT(application) - SUM(application)) AS no_application, 
       SUM(purchase) AS purchase, 
       (COUNT(purchase) - SUM(purchase)) AS no_purchase
FROM mh_ab_test
GROUP BY ab_group;

--calculating percentages from the above query. The figures are integers so to carry out division you need to cast the integer to float using ::
SELECT ab_group, 
      (application::decimal) / (application + no_application) * 100 AS application_pct,
      (purchase::decimal) / (purchase + no_purchase) * 100 AS purchase_pct
FROM
    (SELECT ab_group, 
            SUM(application) AS application, 
            (COUNT(application) - SUM(application)) AS no_application, 
            SUM(purchase) AS purchase, 
            (COUNT(purchase) - SUM(purchase)) AS no_purchase
    FROM mh_ab_test
    GROUP BY ab_group) AS ab_test_results;

--added columns to show the how many days pass between first visit and application or purchase. Grouping these into A and B groups
SELECT ab_group,
       AVG(app_visit_diff) AS avg_no_days_before_application,
       AVG(purchase_visit_diff) AS avg_no_days_before_purchase
FROM  
    (SELECT *, CASE 
              WHEN application_date IS NOT NULL THEN application_date - visit_date
              END AS app_visit_diff,
              CASE
              WHEN purchase_date IS NOT NULL THEN purchase_date - visit_date
              END AS purchase_visit_diff
    FROM mh_ab_test) AS days_passed
GROUP BY ab_group;
