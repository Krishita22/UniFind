-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 02, 2026 at 01:26 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `unifind_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `authtoken_token`
--

CREATE TABLE `authtoken_token` (
  `key` varchar(40) NOT NULL,
  `created` datetime(6) NOT NULL,
  `user_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `authtoken_token`
--

INSERT INTO `authtoken_token` VALUES('92ac5da142af36910d2ce8266d240197b924c239', '2026-03-01 22:27:41.488216', 2);

-- --------------------------------------------------------

--
-- Table structure for table `auth_group`
--

CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth_group_permissions`
--

CREATE TABLE `auth_group_permissions` (
  `id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth_permission`
--

CREATE TABLE `auth_permission` (
  `id` int(11) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_permission`
--

INSERT INTO `auth_permission` VALUES(1, 5, 'add_logentry', 'Can add log entry');
INSERT INTO `auth_permission` VALUES(2, 5, 'change_logentry', 'Can change log entry');
INSERT INTO `auth_permission` VALUES(3, 5, 'delete_logentry', 'Can delete log entry');
INSERT INTO `auth_permission` VALUES(4, 5, 'view_logentry', 'Can view log entry');
INSERT INTO `auth_permission` VALUES(5, 6, 'add_permission', 'Can add permission');
INSERT INTO `auth_permission` VALUES(6, 6, 'change_permission', 'Can change permission');
INSERT INTO `auth_permission` VALUES(7, 6, 'delete_permission', 'Can delete permission');
INSERT INTO `auth_permission` VALUES(8, 6, 'view_permission', 'Can view permission');
INSERT INTO `auth_permission` VALUES(9, 7, 'add_group', 'Can add group');
INSERT INTO `auth_permission` VALUES(10, 7, 'change_group', 'Can change group');
INSERT INTO `auth_permission` VALUES(11, 7, 'delete_group', 'Can delete group');
INSERT INTO `auth_permission` VALUES(12, 7, 'view_group', 'Can view group');
INSERT INTO `auth_permission` VALUES(13, 1, 'add_contenttype', 'Can add content type');
INSERT INTO `auth_permission` VALUES(14, 1, 'change_contenttype', 'Can change content type');
INSERT INTO `auth_permission` VALUES(15, 1, 'delete_contenttype', 'Can delete content type');
INSERT INTO `auth_permission` VALUES(16, 1, 'view_contenttype', 'Can view content type');
INSERT INTO `auth_permission` VALUES(17, 8, 'add_session', 'Can add session');
INSERT INTO `auth_permission` VALUES(18, 8, 'change_session', 'Can change session');
INSERT INTO `auth_permission` VALUES(19, 8, 'delete_session', 'Can delete session');
INSERT INTO `auth_permission` VALUES(20, 8, 'view_session', 'Can view session');
INSERT INTO `auth_permission` VALUES(21, 9, 'add_token', 'Can add Token');
INSERT INTO `auth_permission` VALUES(22, 9, 'change_token', 'Can change Token');
INSERT INTO `auth_permission` VALUES(23, 9, 'delete_token', 'Can delete Token');
INSERT INTO `auth_permission` VALUES(24, 9, 'view_token', 'Can view Token');
INSERT INTO `auth_permission` VALUES(25, 10, 'add_tokenproxy', 'Can add Token');
INSERT INTO `auth_permission` VALUES(26, 10, 'change_tokenproxy', 'Can change Token');
INSERT INTO `auth_permission` VALUES(27, 10, 'delete_tokenproxy', 'Can delete Token');
INSERT INTO `auth_permission` VALUES(28, 10, 'view_tokenproxy', 'Can view Token');
INSERT INTO `auth_permission` VALUES(29, 2, 'add_user', 'Can add user');
INSERT INTO `auth_permission` VALUES(30, 2, 'change_user', 'Can change user');
INSERT INTO `auth_permission` VALUES(31, 2, 'delete_user', 'Can delete user');
INSERT INTO `auth_permission` VALUES(32, 2, 'view_user', 'Can view user');
INSERT INTO `auth_permission` VALUES(33, 3, 'add_emailverificationtoken', 'Can add email verification token');
INSERT INTO `auth_permission` VALUES(34, 3, 'change_emailverificationtoken', 'Can change email verification token');
INSERT INTO `auth_permission` VALUES(35, 3, 'delete_emailverificationtoken', 'Can delete email verification token');
INSERT INTO `auth_permission` VALUES(36, 3, 'view_emailverificationtoken', 'Can view email verification token');
INSERT INTO `auth_permission` VALUES(37, 4, 'add_listing', 'Can add listing');
INSERT INTO `auth_permission` VALUES(38, 4, 'change_listing', 'Can change listing');
INSERT INTO `auth_permission` VALUES(39, 4, 'delete_listing', 'Can delete listing');
INSERT INTO `auth_permission` VALUES(40, 4, 'view_listing', 'Can view listing');

-- --------------------------------------------------------

--
-- Table structure for table `django_admin_log`
--

CREATE TABLE `django_admin_log` (
  `id` int(11) NOT NULL,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext DEFAULT NULL,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint(5) UNSIGNED NOT NULL CHECK (`action_flag` >= 0),
  `change_message` longtext NOT NULL,
  `content_type_id` int(11) DEFAULT NULL,
  `user_id` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `django_content_type`
--

CREATE TABLE `django_content_type` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `django_content_type`
--

INSERT INTO `django_content_type` VALUES(1, '', 'contenttypes', 'contenttype');
INSERT INTO `django_content_type` VALUES(2, '', 'api', 'user');
INSERT INTO `django_content_type` VALUES(3, '', 'api', 'emailverificationtoken');
INSERT INTO `django_content_type` VALUES(4, '', 'api', 'listing');
INSERT INTO `django_content_type` VALUES(5, '', 'admin', 'logentry');
INSERT INTO `django_content_type` VALUES(6, '', 'auth', 'permission');
INSERT INTO `django_content_type` VALUES(7, '', 'auth', 'group');
INSERT INTO `django_content_type` VALUES(8, '', 'sessions', 'session');
INSERT INTO `django_content_type` VALUES(9, '', 'authtoken', 'token');
INSERT INTO `django_content_type` VALUES(10, '', 'authtoken', 'tokenproxy');

-- --------------------------------------------------------

--
-- Table structure for table `django_migrations`
--

CREATE TABLE `django_migrations` (
  `id` bigint(20) NOT NULL,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `django_migrations`
--

INSERT INTO `django_migrations` VALUES(1, 'contenttypes', '0001_initial', '2026-03-01 21:49:05.474404');
INSERT INTO `django_migrations` VALUES(2, 'admin', '0001_initial', '2026-03-01 21:50:33.011771');
INSERT INTO `django_migrations` VALUES(3, 'admin', '0002_logentry_remove_auto_add', '2026-03-01 21:50:33.014352');
INSERT INTO `django_migrations` VALUES(4, 'admin', '0003_logentry_add_action_flag_choices', '2026-03-01 21:50:33.015745');
INSERT INTO `django_migrations` VALUES(5, 'contenttypes', '0002_remove_content_type_name', '2026-03-01 21:50:33.017117');
INSERT INTO `django_migrations` VALUES(6, 'auth', '0001_initial', '2026-03-01 21:50:33.018248');
INSERT INTO `django_migrations` VALUES(7, 'auth', '0002_alter_permission_name_max_length', '2026-03-01 21:50:33.019717');
INSERT INTO `django_migrations` VALUES(8, 'auth', '0003_alter_user_email_max_length', '2026-03-01 21:50:33.021621');
INSERT INTO `django_migrations` VALUES(9, 'auth', '0004_alter_user_username_opts', '2026-03-01 21:50:33.023298');
INSERT INTO `django_migrations` VALUES(10, 'auth', '0005_alter_user_last_login_null', '2026-03-01 21:50:33.024844');
INSERT INTO `django_migrations` VALUES(11, 'auth', '0006_require_contenttypes_0002', '2026-03-01 21:50:33.025861');
INSERT INTO `django_migrations` VALUES(12, 'auth', '0007_alter_validators_add_error_messages', '2026-03-01 21:50:33.027131');
INSERT INTO `django_migrations` VALUES(13, 'auth', '0008_alter_user_username_max_length', '2026-03-01 21:50:33.028675');
INSERT INTO `django_migrations` VALUES(14, 'auth', '0009_alter_user_last_name_max_length', '2026-03-01 21:50:33.029981');
INSERT INTO `django_migrations` VALUES(15, 'auth', '0010_alter_group_name_max_length', '2026-03-01 21:50:33.031034');
INSERT INTO `django_migrations` VALUES(16, 'auth', '0011_update_proxy_permissions', '2026-03-01 21:50:33.032168');
INSERT INTO `django_migrations` VALUES(17, 'auth', '0012_alter_user_first_name_max_length', '2026-03-01 21:50:33.033332');
INSERT INTO `django_migrations` VALUES(18, 'authtoken', '0001_initial', '2026-03-01 21:50:33.034848');
INSERT INTO `django_migrations` VALUES(19, 'authtoken', '0002_auto_20160226_1747', '2026-03-01 21:50:33.036278');
INSERT INTO `django_migrations` VALUES(20, 'authtoken', '0003_tokenproxy', '2026-03-01 21:50:33.037578');
INSERT INTO `django_migrations` VALUES(21, 'authtoken', '0004_alter_tokenproxy_options', '2026-03-01 21:50:33.040347');
INSERT INTO `django_migrations` VALUES(22, 'sessions', '0001_initial', '2026-03-01 21:50:33.043316');

-- --------------------------------------------------------

--
-- Table structure for table `django_session`
--

CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_verification_tokens`
--

CREATE TABLE `email_verification_tokens` (
  `id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_verification_tokens`
--

INSERT INTO `email_verification_tokens` VALUES(2, 2, '7320e556cb7da32b015450c3421a154ee25f325f429c7f2fc7a05008d8512803', '2026-03-02 22:25:54', '2026-03-01 22:26:27', '2026-03-01 22:25:54');

-- --------------------------------------------------------

--
-- Table structure for table `listings`
--

CREATE TABLE `listings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `description` text NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `category` varchar(80) NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `is_approved` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `password` varchar(255) NOT NULL DEFAULT '',
  `last_login` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES(2, 'Nick Seminerio', 'seminerion1@montclair.edu', '666d73f696bc91bc0615db30dd4f717ced8051ec16b89cf62ba7b6a21a1c6167$7fe848e8aedb30583c0eea43c14d7687706b2b6ab7755dd4f13c28e91a75b0b1', 1, 0, '2026-03-01 22:25:54', '', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `authtoken_token`
--
ALTER TABLE `authtoken_token`
  ADD PRIMARY KEY (`key`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `auth_group`
--
ALTER TABLE `auth_group`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `auth_group_permissions`
--
ALTER TABLE `auth_group_permissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_gp_group` (`group_id`),
  ADD KEY `fk_gp_perm` (`permission_id`);

--
-- Indexes for table `auth_permission`
--
ALTER TABLE `auth_permission`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_perm_content_type` (`content_type_id`);

--
-- Indexes for table `django_admin_log`
--
ALTER TABLE `django_admin_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `django_admin_log_content_type_id_c4bce8eb_fk_django_co` (`content_type_id`);

--
-- Indexes for table `django_content_type`
--
ALTER TABLE `django_content_type`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`);

--
-- Indexes for table `django_migrations`
--
ALTER TABLE `django_migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `django_session`
--
ALTER TABLE `django_session`
  ADD PRIMARY KEY (`session_key`);

--
-- Indexes for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_tokens_user` (`user_id`);

--
-- Indexes for table `listings`
--
ALTER TABLE `listings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_listings_user` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `auth_group`
--
ALTER TABLE `auth_group`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `auth_group_permissions`
--
ALTER TABLE `auth_group_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `auth_permission`
--
ALTER TABLE `auth_permission`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `django_admin_log`
--
ALTER TABLE `django_admin_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `django_content_type`
--
ALTER TABLE `django_content_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `django_migrations`
--
ALTER TABLE `django_migrations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `listings`
--
ALTER TABLE `listings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `authtoken_token`
--
ALTER TABLE `authtoken_token`
  ADD CONSTRAINT `fk_authtoken_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `auth_group_permissions`
--
ALTER TABLE `auth_group_permissions`
  ADD CONSTRAINT `fk_gp_group` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`),
  ADD CONSTRAINT `fk_gp_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`);

--
-- Constraints for table `auth_permission`
--
ALTER TABLE `auth_permission`
  ADD CONSTRAINT `fk_perm_content_type` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`);

--
-- Constraints for table `django_admin_log`
--
ALTER TABLE `django_admin_log`
  ADD CONSTRAINT `django_admin_log_content_type_id_c4bce8eb_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`);

--
-- Constraints for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD CONSTRAINT `fk_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `listings`
--
ALTER TABLE `listings`
  ADD CONSTRAINT `fk_listings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
