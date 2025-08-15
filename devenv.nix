{ pkgs, ... }: {
  # Enable cachix for faster builds
  cachix.enable = true;

  # MariaDB service
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    settings.mysqld.port = 3306;
  };

  # Essential packages
  packages = with pkgs; [
    mariadb
  ];

  # Shell message with cleanup trap
  enterShell = ''
    echo 'MariaDB ready on port 3306'

    # Set up cleanup on shell exit
    cleanup_mysql() {
      echo "Stopping MariaDB processes..."
      # Find and kill MySQL/MariaDB processes by PID
      MYSQL_PIDS=$(pgrep -f "mysqld|mariadb" || true)
      if [ ! -z "$MYSQL_PIDS" ]; then
        echo "Found MySQL processes: $MYSQL_PIDS"
        kill -TERM $MYSQL_PIDS 2>/dev/null || true
        sleep 2
        # Force kill if still running
        kill -KILL $MYSQL_PIDS 2>/dev/null || true
      fi
      echo "MariaDB processes stopped"
    }
    trap cleanup_mysql EXIT
  '';
}
