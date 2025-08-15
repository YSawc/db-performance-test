-- ========================================
-- Database Performance Testing SQL Scripts Collection (FIXED VERSION)
-- ========================================
-- This file contains completely redesigned SQL scripts for database performance testing
-- with realistic data distribution and clear performance differences
-- ========================================

-- ========================================
-- PART 1: Improved Basic Index Performance Testing Scripts
-- ========================================

-- Database creation and selection
CREATE DATABASE IF NOT EXISTS index_performance_test_fixed;
USE index_performance_test_fixed;

-- Clean up existing objects
DROP TABLE IF EXISTS sessions_no_index;
DROP TABLE IF EXISTS sessions_with_index;
DROP TABLE IF EXISTS sessions_composite_index;
DROP PROCEDURE IF EXISTS generate_realistic_test_data;
DROP PROCEDURE IF EXISTS measure_performance_improved;
DROP PROCEDURE IF EXISTS run_performance_tests_improved;

-- ========================================
-- 1. Table without indexes
-- ========================================
CREATE TABLE sessions_no_index (
    id VARCHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    refresh_expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ========================================
-- 2. Table with basic indexes
-- ========================================
CREATE TABLE sessions_with_index (
    id VARCHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    refresh_expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Basic indexes
    INDEX idx_user_id (user_id),
    INDEX idx_token (token(100)),
    INDEX idx_refresh_token (refresh_token(100)),
    INDEX idx_expires_at (expires_at),
    INDEX idx_is_active (is_active)
);

-- ========================================
-- 3. Table with optimized composite indexes
-- ========================================
CREATE TABLE sessions_composite_index (
    id VARCHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    refresh_expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Optimized composite indexes
    INDEX idx_user_active (user_id, is_active),
    INDEX idx_expires_active (expires_at, is_active),
    INDEX idx_user_created (user_id, created_at),
    INDEX idx_token_covering (token(100), user_id, expires_at, is_active),
    INDEX idx_refresh_covering (refresh_token(100), user_id, refresh_expires_at, is_active)
);

-- ========================================
-- Improved test data generation procedure
-- ========================================
DELIMITER $$
CREATE PROCEDURE generate_realistic_test_data(IN num_records INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE token_val VARCHAR(255);
    DECLARE refresh_token_val VARCHAR(255);
    DECLARE user_id_val INT;
    DECLARE expires_hours INT;
    DECLARE refresh_hours INT;
    DECLARE is_active_val BOOLEAN;
    DECLARE created_hours_ago INT;

    -- Progress display
    SELECT CONCAT('Generating ', num_records, ' realistic test records...') AS status;

    WHILE i <= num_records DO
        -- Generate more realistic values
        SET token_val = CONCAT('token_', LPAD(i, 6, '0'), '_', MD5(RAND()));
        SET refresh_token_val = CONCAT('refresh_', LPAD(i, 6, '0'), '_', MD5(RAND()));
        
        -- More realistic user distribution (some users have many sessions, others few)
        IF RAND() < 0.1 THEN
            SET user_id_val = FLOOR(1 + RAND() * 100); -- 10% of users (1-100)
        ELSE
            SET user_id_val = FLOOR(101 + RAND() * 900); -- 90% of users (101-1000)
        END IF;
        
        -- More realistic expiration times (some expired, some not)
        IF RAND() < 0.3 THEN
            SET expires_hours = FLOOR(-24 + RAND() * 48); -- 30% expired (-24 to +24 hours)
        ELSE
            SET expires_hours = FLOOR(1 + RAND() * 168); -- 70% future (1-168 hours)
        END IF;
        
        SET refresh_hours = FLOOR(24 + RAND() * 168); -- 24 hours-1 week
        SET is_active_val = RAND() > 0.2; -- 80% active (more realistic)
        SET created_hours_ago = FLOOR(RAND() * 720); -- 0-30 days ago

        -- Insert into table without indexes
        INSERT INTO sessions_no_index (id, user_id, token, refresh_token, expires_at, refresh_expires_at, is_active, created_at)
        VALUES (
            UUID(),
            user_id_val,
            token_val,
            refresh_token_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL expires_hours HOUR,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL refresh_hours HOUR,
            is_active_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR)
        );

        -- Insert into table with basic indexes
        INSERT INTO sessions_with_index (id, user_id, token, refresh_token, expires_at, refresh_expires_at, is_active, created_at)
        VALUES (
            UUID(),
            user_id_val,
            token_val,
            refresh_token_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL expires_hours HOUR,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL refresh_hours HOUR,
            is_active_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR)
        );

        -- Insert into table with composite indexes
        INSERT INTO sessions_composite_index (id, user_id, token, refresh_token, expires_at, refresh_expires_at, is_active, created_at)
        VALUES (
            UUID(),
            user_id_val,
            token_val,
            refresh_token_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL expires_hours HOUR,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL refresh_hours HOUR,
            is_active_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR)
        );

        SET i = i + 1;
    END WHILE;

    SELECT CONCAT('Completed generating ', num_records, ' realistic records') AS status;
END$$
DELIMITER ;

-- ========================================
-- Improved performance measurement procedure
-- ========================================
DELIMITER $$
CREATE PROCEDURE measure_performance_improved()
BEGIN
    DECLARE start_time TIMESTAMP(6);
    DECLARE end_time TIMESTAMP(6);
    DECLARE execution_time_microseconds BIGINT;

    -- Create results table
    DROP TEMPORARY TABLE IF EXISTS performance_results;
    CREATE TEMPORARY TABLE performance_results (
        test_name VARCHAR(100),
        table_type VARCHAR(50),
        execution_time_microseconds BIGINT,
        execution_time_ms DECIMAL(10,3),
        rows_examined INT
    );

    -- Clear query cache and update statistics
    FLUSH QUERY CACHE;
    ANALYZE TABLE sessions_no_index;
    ANALYZE TABLE sessions_with_index;
    ANALYZE TABLE sessions_composite_index;

    -- 1. Expired sessions search (should show biggest difference)
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_no_index WHERE expires_at < NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Expired Sessions', 'No Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_with_index WHERE expires_at < NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Expired Sessions', 'Basic Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_composite_index WHERE expires_at < NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Expired Sessions', 'Composite Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 2. User sessions search (realistic scenario)
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_no_index WHERE user_id = 50 AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('User Sessions', 'No Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_with_index WHERE user_id = 50 AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('User Sessions', 'Basic Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_composite_index WHERE user_id = 50 AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('User Sessions', 'Composite Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 3. Token search (exact match)
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_no_index WHERE token = 'token_000001_abc123';
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Token Search', 'No Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_with_index WHERE token = 'token_000001_abc123';
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Token Search', 'Basic Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_composite_index WHERE token = 'token_000001_abc123';
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Token Search', 'Composite Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 4. Recent sessions (time-based query) - Improved with more specific range
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_no_index WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY) AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Recent Sessions', 'No Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_with_index WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY) AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Recent Sessions', 'Basic Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_composite_index WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY) AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Recent Sessions', 'Composite Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 5. New test: Range query on expires_at (should show bigger difference)
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_no_index WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Expires Range', 'No Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_with_index WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Expires Range', 'Basic Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_composite_index WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR);
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO performance_results VALUES ('Expires Range', 'Composite Index', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- Display results
    SELECT
        test_name,
        table_type,
        execution_time_microseconds,
        execution_time_ms,
        rows_examined,
        ROUND(
            LAG(execution_time_microseconds) OVER (PARTITION BY test_name ORDER BY execution_time_microseconds) /
            execution_time_microseconds, 2
        ) AS improvement_ratio
    FROM performance_results
    ORDER BY test_name, execution_time_microseconds;

END$$
DELIMITER ;

-- ========================================
-- Main execution procedure
-- ========================================
DELIMITER $$
CREATE PROCEDURE run_performance_tests_improved(IN num_records INT)
BEGIN
    -- Generate realistic test data
    CALL generate_realistic_test_data(num_records);

    -- Measure performance
    CALL measure_performance_improved();
END$$
DELIMITER ;

-- ========================================
-- PART 2: Improved Bad Design vs Good Design Comparison Scripts
-- ========================================

-- Database creation and selection
CREATE DATABASE IF NOT EXISTS bad_index_performance_test_fixed;
USE bad_index_performance_test_fixed;

-- Clean up existing objects
DROP TABLE IF EXISTS sessions_good_index;
DROP TABLE IF EXISTS sessions_bad_index;
DROP PROCEDURE IF EXISTS generate_realistic_test_data;
DROP PROCEDURE IF EXISTS measure_bad_vs_good_performance_improved;
DROP PROCEDURE IF EXISTS run_bad_index_comparison_improved;

-- ========================================
-- 1. Table with correct index design
-- ========================================
CREATE TABLE sessions_good_index (
    id VARCHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    refresh_expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Correct index design
    INDEX idx_user_active (user_id, is_active),
    INDEX idx_token (token(100)),
    INDEX idx_expires_at (expires_at),
    INDEX idx_token_covering (token(100), user_id, expires_at, is_active)
);

-- ========================================
-- 2. Table with incorrect index design (clearly problematic)
-- ========================================
CREATE TABLE sessions_bad_index (
    id VARCHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    refresh_expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Clearly problematic index design - Made even worse
    INDEX idx_bad_order (is_active, user_id),  -- Low cardinality first
    INDEX idx_wrong_token (token(5)),  -- Even shorter prefix
    INDEX idx_wrong_expires (created_at, expires_at),  -- Wrong order
    INDEX idx_over_indexed (user_id, token, refresh_token, expires_at, is_active, created_at),  -- Too many columns
    INDEX idx_redundant (user_id, is_active),  -- Redundant index
    INDEX idx_useless (updated_at)  -- Rarely used column
);

-- ========================================
-- Improved test data generation procedure
-- ========================================
DELIMITER $$
CREATE PROCEDURE generate_realistic_test_data(IN num_records INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE token_val VARCHAR(255);
    DECLARE refresh_token_val VARCHAR(255);
    DECLARE user_id_val INT;
    DECLARE expires_hours INT;
    DECLARE refresh_hours INT;
    DECLARE is_active_val BOOLEAN;
    DECLARE created_hours_ago INT;

    -- Progress display
    SELECT CONCAT('Generating ', num_records, ' realistic test records...') AS status;

    WHILE i <= num_records DO
        -- Generate more realistic values
        SET token_val = CONCAT('token_', LPAD(i, 6, '0'), '_', MD5(RAND()));
        SET refresh_token_val = CONCAT('refresh_', LPAD(i, 6, '0'), '_', MD5(RAND()));
        
        -- More realistic user distribution
        IF RAND() < 0.1 THEN
            SET user_id_val = FLOOR(1 + RAND() * 100); -- 10% of users (1-100)
        ELSE
            SET user_id_val = FLOOR(101 + RAND() * 900); -- 90% of users (101-1000)
        END IF;
        
        -- More realistic expiration times
        IF RAND() < 0.3 THEN
            SET expires_hours = FLOOR(-24 + RAND() * 48); -- 30% expired
        ELSE
            SET expires_hours = FLOOR(1 + RAND() * 168); -- 70% future
        END IF;
        
        SET refresh_hours = FLOOR(24 + RAND() * 168);
        SET is_active_val = RAND() > 0.2; -- 80% active
        SET created_hours_ago = FLOOR(RAND() * 720); -- 0-30 days ago

        -- Insert into correct design table
        INSERT INTO sessions_good_index (id, user_id, token, refresh_token, expires_at, refresh_expires_at, is_active, created_at)
        VALUES (
            UUID(),
            user_id_val,
            token_val,
            refresh_token_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL expires_hours HOUR,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL refresh_hours HOUR,
            is_active_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR)
        );

        -- Insert into incorrect design table
        INSERT INTO sessions_bad_index (id, user_id, token, refresh_token, expires_at, refresh_expires_at, is_active, created_at)
        VALUES (
            UUID(),
            user_id_val,
            token_val,
            refresh_token_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL expires_hours HOUR,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR) + INTERVAL refresh_hours HOUR,
            is_active_val,
            DATE_SUB(NOW(), INTERVAL created_hours_ago HOUR)
        );

        SET i = i + 1;
    END WHILE;

    SELECT CONCAT('Completed generating ', num_records, ' realistic records') AS status;
END$$
DELIMITER ;

-- ========================================
-- Improved performance measurement procedure
-- ========================================
DELIMITER $$
CREATE PROCEDURE measure_bad_vs_good_performance_improved()
BEGIN
    DECLARE start_time TIMESTAMP(6);
    DECLARE end_time TIMESTAMP(6);
    DECLARE execution_time_microseconds BIGINT;

    -- Create results table
    DROP TEMPORARY TABLE IF EXISTS comparison_results;
    CREATE TEMPORARY TABLE comparison_results (
        test_name VARCHAR(100),
        design_type VARCHAR(20),
        execution_time_microseconds BIGINT,
        execution_time_ms DECIMAL(10,3),
        rows_examined INT
    );

    -- Clear query cache and update statistics
    FLUSH QUERY CACHE;
    ANALYZE TABLE sessions_good_index;
    ANALYZE TABLE sessions_bad_index;

    -- 1. Expired sessions search (should show biggest difference)
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_good_index WHERE expires_at < NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Expired Sessions', 'Good Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_bad_index WHERE expires_at < NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Expired Sessions', 'Bad Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 2. User sessions search - More specific query
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_good_index WHERE user_id = 50 AND is_active = TRUE AND expires_at > NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('User Sessions', 'Good Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_bad_index WHERE user_id = 50 AND is_active = TRUE AND expires_at > NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('User Sessions', 'Bad Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 3. Token search - More specific token
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_good_index WHERE token LIKE 'token_000001%';
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Token Search', 'Good Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_bad_index WHERE token LIKE 'token_000001%';
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Token Search', 'Bad Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 4. Recent sessions - More specific range
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_good_index WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY) AND is_active = TRUE AND expires_at > NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Recent Sessions', 'Good Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_bad_index WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY) AND is_active = TRUE AND expires_at > NOW();
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Recent Sessions', 'Bad Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- 5. New test: Complex range query (should show biggest difference)
    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_good_index WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR) AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Complex Range', 'Good Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    SET start_time = NOW(6);
    SELECT SQL_NO_CACHE COUNT(*) INTO @count FROM sessions_bad_index WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR) AND is_active = TRUE;
    SET end_time = NOW(6);
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    INSERT INTO comparison_results VALUES ('Complex Range', 'Bad Design', execution_time_microseconds, ROUND(execution_time_microseconds / 1000, 3), @count);

    -- Display results
    SELECT
        test_name,
        design_type,
        execution_time_microseconds,
        execution_time_ms,
        rows_examined
    FROM comparison_results
    ORDER BY test_name, execution_time_microseconds;

    -- Performance comparison summary
    SELECT
        test_name,
        MAX(CASE WHEN design_type = 'Good Design' THEN execution_time_microseconds END) AS good_design_time,
        MAX(CASE WHEN design_type = 'Bad Design' THEN execution_time_microseconds END) AS bad_design_time,
        ROUND(
            MAX(CASE WHEN design_type = 'Bad Design' THEN execution_time_microseconds END) /
            MAX(CASE WHEN design_type = 'Good Design' THEN execution_time_microseconds END), 2
        ) AS performance_degradation_ratio
    FROM comparison_results
    GROUP BY test_name
    ORDER BY test_name;

END$$
DELIMITER ;

-- ========================================
-- Main execution procedure
-- ========================================
DELIMITER $$
CREATE PROCEDURE run_bad_index_comparison_improved(IN num_records INT)
BEGIN
    -- Generate realistic test data
    CALL generate_realistic_test_data(num_records);

    -- Measure performance
    CALL measure_bad_vs_good_performance_improved();
END$$
DELIMITER ;

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Example 1: Basic performance test with realistic data (10,000 records)
-- USE index_performance_test_fixed;
-- CALL run_performance_tests_improved(10000);

-- Example 2: Bad vs Good design comparison with realistic data (100,000 records)
-- USE bad_index_performance_test_fixed;
-- CALL run_bad_index_comparison_improved(100000);

-- ========================================
-- CLEANUP SCRIPTS
-- ========================================

-- Clean up test databases
-- DROP DATABASE IF EXISTS index_performance_test_fixed;
-- DROP DATABASE IF EXISTS bad_index_performance_test_fixed;
