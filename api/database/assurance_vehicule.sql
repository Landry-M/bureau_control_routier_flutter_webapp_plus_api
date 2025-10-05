-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 05, 2025 at 05:01 AM
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
-- Table structure for table `assurance_vehicule`
--

CREATE TABLE `assurance_vehicule` (
  `id` bigint(20) NOT NULL,
  `vehicule_plaque_id` bigint(20) NOT NULL COMMENT 'ID du vÃ©hicule (rÃ©fÃ©rence Ã  vehicule_plaque)',
  `societe_assurance` varchar(255) DEFAULT NULL COMMENT 'Nom de la compagnie d''assurance',
  `nume_assurance` varchar(100) DEFAULT NULL COMMENT 'NumÃ©ro de police d''assurance',
  `date_valide_assurance` date DEFAULT NULL COMMENT 'Date de dÃ©but de validitÃ© de l''assurance',
  `date_expire_assurance` date DEFAULT NULL COMMENT 'Date d''expiration de l''assurance',
  `montant_prime` decimal(10,2) DEFAULT NULL COMMENT 'Montant de la prime d''assurance',
  `type_couverture` varchar(100) DEFAULT NULL COMMENT 'Type de couverture (tous risques, tiers, etc.)',
  `notes` text DEFAULT NULL COMMENT 'Notes additionnelles sur l''assurance',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Historique des assurances des vÃ©hicules avec suivi des renouvellements';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `assurance_vehicule`
--
ALTER TABLE `assurance_vehicule`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_vehicule_plaque_id` (`vehicule_plaque_id`),
  ADD KEY `idx_date_expire` (`date_expire_assurance`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `assurance_vehicule`
--
ALTER TABLE `assurance_vehicule`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
