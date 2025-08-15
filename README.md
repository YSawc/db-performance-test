# Database Performance Testing Repository

This repository is designed for database performance testing and analysis using MariaDB. It provides a reproducible development environment using devenv.

## Prerequisites

Before starting, ensure you have the following installed:

- **Nix**: A package manager that provides reproducible development environments
- **devenv**: A development environment tool built on top of Nix

### Installing Nix

#### macOS
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

#### Linux
```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### Installing devenv

After installing Nix, install devenv:

```bash
nix profile install --accept-flake-config github:cachix/devenv/v1.0.1
```

## Getting Started

### 1. Start the Development Environment

Navigate to the project directory and start the development environment:

```bash
cd /path/to/db-performance-test
devenv up
```

This command will:
- Start a MariaDB server on port 3306
- Set up the necessary packages and dependencies
- Provide a shell with all required tools

### 2. Access MariaDB

Once the environment is running, you can connect to MariaDB using:

```bash
mysql -u root -p
```

By default, there is no password set for the root user in the development environment.

### 3. Stop the Development Environment

To stop the development environment and clean up:

```bash
devenv down
```

Or simply exit the shell (Ctrl+D), and the environment will automatically clean up MariaDB processes.

## Environment Features

- **MariaDB Server**: Running on port 3306
- **Automatic Cleanup**: MariaDB processes are automatically stopped when exiting the shell
- **Reproducible Environment**: All dependencies are managed through Nix for consistent results

## Database Performance Testing

This environment is specifically configured for database performance testing with proven results:

### Key Performance Improvements Demonstrated

- **User Sessions**: 221x faster with composite indexes
- **Expires Range**: 51x faster with optimized range queries  
- **Complex Range**: 18.6x performance difference (Good vs Bad Design)
- **Token Search**: 2.2x faster with proper indexing

### What You Can Test

1. Create test databases and tables
2. Run performance benchmarks
3. Analyze query performance
4. Test different indexing strategies
5. Compare Good Design vs Bad Design
6. Measure real-world performance improvements

## Troubleshooting

### Port Already in Use
If port 3306 is already in use, the environment will handle this automatically. If you encounter issues:

```bash
# Check for existing MySQL/MariaDB processes
ps aux | grep mysql

# Kill existing processes if necessary
sudo pkill -f mysql
```

### Permission Issues
If you encounter permission issues with Nix or devenv:

```bash
# Restart your shell
exec zsh

# Or restart the Nix daemon (macOS)
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
```

## Project Structure

```
db-performance-test/
├── devenv.yaml          # Devenv configuration
├── devenv.nix           # Nix development environment setup
├── devenv.lock          # Locked dependencies
├── sql_scripts_collection.sql  # Complete SQL scripts for performance testing
├── index_performance_article.md # Database index performance article (Part 1)
├── index_performance_article_part2.md # Database index performance article (Part 2)
└── README.md            # This file
```

## SQL Scripts Execution

This repository includes comprehensive SQL scripts for database performance testing. The `sql_scripts_collection.sql` file contains all the scripts needed for index performance analysis.

### Quick Start with SQL Scripts

#### 1. Load the SQL Scripts

Once connected to MariaDB, load the complete SQL scripts:

```sql
-- Load the SQL scripts from the current directory
SOURCE sql_scripts_collection.sql;

-- Or specify the full path if needed
SOURCE /path/to/db-performance-test/sql_scripts_collection.sql;
```

**Note**: The `SOURCE` command loads and executes all SQL statements in the file. Make sure you're in the correct directory or specify the full path to the SQL file.

#### 2. Basic Performance Testing

Run basic index performance tests with different data sizes:

```sql
-- Switch to the basic performance test database
USE index_performance_test;

-- Small scale test (1,000 records)
CALL run_performance_tests(1000);

-- Medium scale test (10,000 records)
CALL run_performance_tests(10000);

-- Large scale test (100,000 records)
CALL run_performance_tests(100000);
```

#### 3. Good Design vs Bad Design Comparison

Compare optimized vs problematic index designs:

```sql
-- Switch to the comparison database
USE bad_index_performance_test;

-- Run comparison tests with different data sizes
CALL run_bad_index_comparison(10000);
CALL run_bad_index_comparison(100000);
```

#### 4. Advanced Performance Testing (Improved Scripts)

For more accurate measurements with realistic data distribution:

```sql
-- Load the improved scripts
SOURCE sql_scripts_collection_fixed.sql;

-- Basic performance test with realistic data
USE index_performance_test_fixed;
CALL run_performance_tests_improved(100000);

-- Good vs Bad design comparison
USE bad_index_performance_test_fixed;
CALL run_bad_index_comparison_improved(100000);
```

### Expected Results

#### Basic Performance Test Results (100,000 records)

| Test Case | No Index | Basic Index | Composite Index | Max Improvement |
|-----------|----------|-------------|-----------------|-----------------|
| User Sessions | 6.858ms | 1.286ms | 0.031ms | **221x** |
| Expires Range | 24.918ms | 0.528ms | 0.489ms | **51x** |
| Token Search | 0.042ms | 0.020ms | 0.019ms | **2.2x** |
| Expired Sessions | 41.927ms | 17.252ms | 18.330ms | **2.4x** |

#### Good vs Bad Design Comparison (100,000 records)

| Test Case | Good Design | Bad Design | Performance Difference |
|-----------|-------------|------------|----------------------|
| Complex Range | 3.596ms | 67.010ms | **18.6x slower** |
| Recent Sessions | 46.708ms | 85.025ms | **1.8x slower** |
| Expired Sessions | 16.676ms | 19.397ms | **1.2x slower** |

### Database Structure

The scripts create two separate databases:

1. **`index_performance_test`** (or `index_performance_test_fixed`):
   - `sessions_no_index`: Table without indexes
   - `sessions_with_index`: Table with basic indexes
   - `sessions_composite_index`: Table with optimized composite indexes

2. **`bad_index_performance_test`** (or `bad_index_performance_test_fixed`):
   - `sessions_good_index`: Table with correct index design
   - `sessions_bad_index`: Table with problematic index design

### Available Test Scenarios

#### Basic Performance Tests
- **Token Search**: Exact token matching performance
- **User Sessions**: User-specific session queries
- **Expired Sessions**: Time-based expiration queries
- **Recent Sessions**: Date range queries

#### Advanced Comparison Tests
- **Complex Range**: Multi-condition range queries
- **User Sessions**: User + active status queries
- **Token Search**: Pattern matching queries
- **Recent Sessions**: Time + status queries

### Performance Measurement Features

- **Microsecond Precision**: Uses `TIMESTAMP(6)` for high-precision timing
- **Cache Clearing**: Automatically clears query cache before measurements
- **Statistics Update**: Runs `ANALYZE TABLE` for accurate execution plans
- **Realistic Data**: Generates data with realistic distribution patterns

### Troubleshooting SQL Scripts

#### Common Issues and Solutions

##### 1. SOURCE Command Issues

If you encounter issues with the `SOURCE` command:

```sql
-- Check current directory
SYSTEM pwd;

-- List files in current directory
SYSTEM ls -la *.sql;

-- Use absolute path if needed
SOURCE /full/path/to/sql_scripts_collection.sql;
```

##### 2. Database Context Issues

Make sure you're using the correct database:

```sql
-- Check current database
SELECT DATABASE();

-- Switch to the correct database
USE index_performance_test;
-- or
USE bad_index_performance_test;
```

##### 3. Procedure Not Found Errors

If you get "PROCEDURE does not exist" errors:

```sql
-- Reload the scripts to recreate procedures
SOURCE sql_scripts_collection.sql;

-- Or for improved scripts
SOURCE sql_scripts_collection_fixed.sql;
```

##### 4. Zero Execution Times

If you see execution times of 0 microseconds:

```sql
-- Clear query cache manually
FLUSH QUERY CACHE;

-- Update table statistics
ANALYZE TABLE sessions_no_index;
ANALYZE TABLE sessions_with_index;
ANALYZE TABLE sessions_composite_index;

-- Re-run the test
CALL run_performance_tests(1000);
```

##### 5. Duplicate Entry Errors

If you encounter duplicate entry errors during data generation:

```sql
-- Drop and recreate the database
DROP DATABASE IF EXISTS index_performance_test;
SOURCE sql_scripts_collection.sql;
```

##### 6. Memory Issues

For large datasets, you might encounter memory issues:

```sql
-- Use smaller data sizes
CALL run_performance_tests(1000);
CALL run_performance_tests(10000);

-- Or increase memory limits (if you have admin access)
SET GLOBAL max_heap_table_size = 1073741824; -- 1GB
SET GLOBAL tmp_table_size = 1073741824; -- 1GB
```

### Advanced Usage

#### Custom Test Scenarios

You can create custom test scenarios by modifying the SQL scripts:

```sql
-- Example: Custom performance test
DELIMITER $$
CREATE PROCEDURE custom_performance_test()
BEGIN
    DECLARE start_time TIMESTAMP(6);
    DECLARE end_time TIMESTAMP(6);
    DECLARE execution_time_microseconds BIGINT;

    SET start_time = NOW(6);
    -- Your custom query here
    SELECT SQL_NO_CACHE COUNT(*) FROM sessions_composite_index WHERE user_id = 100;
    SET end_time = NOW(6);
    
    SET execution_time_microseconds = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
    SELECT CONCAT('Execution time: ', execution_time_microseconds, ' microseconds') AS result;
END$$
DELIMITER ;

-- Run custom test
CALL custom_performance_test();
```

#### Execution Plan Analysis

Analyze query execution plans to understand index usage:

```sql
-- Analyze execution plan for a specific query
EXPLAIN SELECT SQL_NO_CACHE COUNT(*) 
FROM sessions_composite_index 
WHERE user_id = 50 AND is_active = TRUE;

-- Compare execution plans between designs
EXPLAIN SELECT SQL_NO_CACHE COUNT(*) 
FROM sessions_good_index 
WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR) 
AND is_active = TRUE;

EXPLAIN SELECT SQL_NO_CACHE COUNT(*) 
FROM sessions_bad_index 
WHERE expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR) 
AND is_active = TRUE;
```

#### Performance Monitoring

Monitor performance during tests:

```sql
-- Check current connections
SHOW PROCESSLIST;

-- Monitor table sizes
SELECT 
    table_name,
    ROUND(data_length / 1024 / 1024, 2) AS data_size_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_size_mb
FROM information_schema.tables 
WHERE table_schema = 'index_performance_test';

-- Check index usage statistics
SHOW INDEX FROM sessions_composite_index;
```

### Cleanup

After running your tests, you can clean up the test databases:

```sql
-- Clean up test databases
DROP DATABASE IF EXISTS index_performance_test;
DROP DATABASE IF EXISTS bad_index_performance_test;
DROP DATABASE IF EXISTS index_performance_test_fixed;
DROP DATABASE IF EXISTS bad_index_performance_test_fixed;
```

### Best Practices

#### 1. Test Data Sizes
- Start with small datasets (1,000 records) to verify setup
- Use medium datasets (10,000 records) for initial performance analysis
- Use large datasets (100,000 records) for final validation

#### 2. Measurement Accuracy
- Always clear query cache before measurements
- Run tests multiple times and take averages
- Use microsecond precision for accurate timing
- Update table statistics before testing

#### 3. Environment Consistency
- Use the same environment for all tests
- Document your test conditions
- Compare results within the same session
- Avoid running other heavy queries during testing

#### 4. Analysis Approach
- Start with basic performance tests
- Move to design comparison tests
- Use execution plans to understand index usage
- Monitor system resources during testing

### Performance Tips

#### 1. Optimizing Test Execution
```sql
-- Set session variables for better performance
SET SESSION sql_mode = '';
SET SESSION innodb_flush_log_at_trx_commit = 2;
SET SESSION sync_binlog = 0;
```

#### 2. Monitoring System Resources
```bash
# Monitor CPU and memory usage during tests
top -p $(pgrep -f mysqld)

# Monitor disk I/O
iostat -x 1
```

#### 3. Interpreting Results
- Focus on relative performance differences rather than absolute times
- Consider the impact of data distribution on results
- Look for patterns across different test scenarios
- Validate results with execution plan analysis
| Test Type | Good Design | Bad Design | Performance Degradation |
|-----------|-------------|------------|------------------------|
| Expired Sessions | 0.053ms | 22.148ms | **418x slower** |
| Composite Search | 0.081ms | 0.071ms | 0.88x (unexpected) |
| Token Search | 0.044ms | 0.042ms | 0.95x (unexpected) |

### Advanced Usage

#### Individual Test Execution

```sql
-- Basic performance test database
USE index_performance_test;

-- Generate test data only
CALL generate_test_data(1000);

-- Run performance measurement only
CALL measure_performance();

-- Bad vs good design comparison database
USE bad_index_performance_test;

-- Run bad vs good comparison only
CALL measure_bad_vs_good_performance();

-- Run complex query performance tests
CALL measure_complex_performance();

-- Run complex bad vs good comparison
CALL measure_complex_bad_vs_good_performance();
```

#### Analysis Queries

```sql
-- Check index usage statistics (basic performance test)
SELECT
    table_name,
    index_name,
    cardinality,
    sub_part
FROM information_schema.statistics
WHERE table_schema = 'index_performance_test'
ORDER BY table_name, index_name;

-- Check index usage statistics (bad vs good comparison)
SELECT
    table_name,
    index_name,
    cardinality,
    sub_part
FROM information_schema.statistics
WHERE table_schema = 'bad_index_performance_test'
ORDER BY table_name, index_name;

-- Analyze storage usage (basic performance test)
SELECT
    table_name,
    ROUND(data_length / 1024 / 1024, 2) AS data_size_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_size_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_size_mb
FROM information_schema.tables
WHERE table_schema = 'index_performance_test'
ORDER BY table_name;

-- Analyze storage usage (bad vs good comparison)
SELECT
    table_name,
    ROUND(data_length / 1024 / 1024, 2) AS data_size_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_size_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_size_mb
FROM information_schema.tables
WHERE table_schema = 'bad_index_performance_test'
ORDER BY table_name;

-- View query execution plans (basic performance test)
USE index_performance_test;
EXPLAIN SELECT SQL_NO_CACHE COUNT(*) FROM sessions_with_index WHERE user_id = 500 AND is_active = TRUE;

-- View query execution plans (bad vs good comparison)
USE bad_index_performance_test;
EXPLAIN SELECT SQL_NO_CACHE COUNT(*) FROM sessions_good_index WHERE user_id = 500 AND is_active = TRUE;
EXPLAIN SELECT SQL_NO_CACHE COUNT(*) FROM sessions_bad_index WHERE user_id = 500 AND is_active = TRUE;
```

#### Cleanup

```sql
-- Clean up test databases when finished
DROP DATABASE IF EXISTS index_performance_test;
DROP DATABASE IF EXISTS bad_index_performance_test;
```

### Troubleshooting SQL Scripts

#### Common Issues

1. **SOURCE Command Issues**
   ```sql
   -- Check current directory
   SYSTEM pwd;
   
   -- List files in current directory
   SYSTEM ls -la;
   
   -- If file not found, use absolute path
   SOURCE /absolute/path/to/sql_scripts_collection.sql;
   ```

2. **Memory Issues**
   ```sql
   -- Reduce data size for testing
   CALL run_performance_tests(1000);
   ```

3. **Timeout Issues**
   ```sql
   -- Increase timeout settings
   SET SESSION wait_timeout = 3600;
   ```

4. **Permission Issues**
   ```sql
   -- Check and grant necessary permissions
   SHOW GRANTS;
   GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
   ```

#### Performance Tips

- Use `SQL_NO_CACHE` to ensure accurate measurements
- Run tests multiple times and take averages
- Monitor system resources during large tests
- Use `ANALYZE TABLE` to update statistics before testing
- **Important**: If you see execution times of 0, the cache is affecting results. The improved scripts now include cache clearing.

#### Troubleshooting Zero Execution Times

If you see execution times of 0 microseconds, it means the query cache is affecting measurements. The improved scripts include:

```sql
-- Cache clearing commands (automatically included in improved scripts)
FLUSH QUERY CACHE;
ANALYZE TABLE table_name;

-- Manual cache clearing if needed
RESET QUERY CACHE;
```

#### SOURCE Command Tips

- The `SOURCE` command executes all SQL statements in the file sequentially
- Make sure the SQL file is accessible from your current working directory
- Use `SYSTEM pwd` to check your current directory in MySQL/MariaDB
- Use `SYSTEM ls -la` to list files in the current directory
- If you get "File not found" errors, use the absolute path to the SQL file

#### Database Structure

The SQL scripts create two separate databases:

1. **`index_performance_test`**: Basic performance testing
   - Tables: `sessions_no_index`, `sessions_with_index`, `sessions_composite_index`
   - Procedures: `run_performance_tests()`, `generate_test_data()`, `measure_performance()`

2. **`bad_index_performance_test`**: Bad vs Good design comparison
   - Tables: `sessions_good_index`, `sessions_bad_index`
   - Procedures: `run_bad_index_comparison()`, `generate_test_data()`, `measure_bad_vs_good_performance()`, `measure_high_precision_performance_fixed()`

**Important**: Make sure to use the correct database for each test type!

## Contributing

When contributing to this repository:

1. Ensure your changes work with the devenv environment
2. Test database performance scenarios
3. Update documentation as needed

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Contributing Guidelines

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**:
   - Ensure your changes work with the devenv environment
   - Test database performance scenarios
   - Update documentation as needed
4. **Commit your changes**: `git commit -m 'Add some amazing feature'`
5. **Push to the branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request**

### Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/db-performance-test.git
   cd db-performance-test
   ```

2. **Start the development environment**:
   ```bash
   devenv up
   ```

3. **Test your changes**:
   ```sql
   -- Connect to MariaDB
   mysql -u root
   
   -- Test the SQL scripts
   SOURCE sql_scripts_collection_fixed.sql;
   USE index_performance_test_fixed;
   CALL run_performance_tests_improved(1000);
   ```

### Code of Conduct

This project is open source and available under the [MIT License](LICENSE). We welcome contributions from the community and expect all contributors to follow our code of conduct.
