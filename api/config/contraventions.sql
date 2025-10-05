-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 04, 2025 at 12:05 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.0.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `control_routier`
--

-- --------------------------------------------------------

--
-- Table structure for table `contraventions`
--

CREATE TABLE `contraventions` (
  `id` bigint(20) NOT NULL,
  `dossier_id` varchar(30) NOT NULL,
  `type_dossier` varchar(70) NOT NULL,
  `date_infraction` datetime NOT NULL,
  `lieu` longtext DEFAULT NULL,
  `type_infraction` longtext DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `reference_loi` longtext DEFAULT NULL,
  `amende` varchar(200) DEFAULT NULL,
  `payed` varchar(10) NOT NULL DEFAULT 'non',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `photos` text DEFAULT NULL COMMENT 'Chemins des photos séparés par des virgules'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `contraventions`
--
ALTER TABLE `contraventions`
  ADD PRIMARY KEY (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
