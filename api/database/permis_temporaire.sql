-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 05, 2025 at 05:29 PM
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
-- Table structure for table `permis_temporaire`
--

CREATE TABLE `permis_temporaire` (
  `id` int(10) UNSIGNED NOT NULL,
  `cible_type` enum('particulier','conducteur','vehicule_plaque') NOT NULL DEFAULT 'particulier',
  `cible_id` bigint(20) UNSIGNED NOT NULL,
  `numero` varchar(50) NOT NULL,
  `motif` text DEFAULT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date NOT NULL,
  `statut` enum('actif','clos') NOT NULL DEFAULT 'actif',
  `pdf_path` varchar(255) DEFAULT NULL COMMENT 'Chemin relatif vers le fichier PDF généré',
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `permis_temporaire`
--
ALTER TABLE `permis_temporaire`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_permis_temporaire_numero` (`numero`),
  ADD KEY `idx_permis_temporaire_cible` (`cible_type`,`cible_id`),
  ADD KEY `idx_permis_temporaire_statut` (`statut`),
  ADD KEY `idx_permis_temporaire_pdf_path` (`pdf_path`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
