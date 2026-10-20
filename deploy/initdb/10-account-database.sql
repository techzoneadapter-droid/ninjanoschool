-- MariaDB initialization: the image creates nsohuyda_data and user 'nso' first.
-- This script runs ONCE, only on a fresh Docker data volume.
CREATE DATABASE IF NOT EXISTS `nsohuyda_account`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON `nsohuyda_account`.* TO 'nso'@'%';
