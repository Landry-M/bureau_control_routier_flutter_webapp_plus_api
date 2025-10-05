-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 04, 2025 at 08:10 PM
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
-- Table structure for table `particuliers`
--

CREATE TABLE `particuliers` (
  `id` bigint(20) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `adresse` longtext DEFAULT NULL,
  `profession` varchar(40) DEFAULT NULL,
  `date_naissance` datetime DEFAULT NULL,
  `genre` varchar(10) DEFAULT NULL,
  `numero_national` varchar(50) DEFAULT NULL,
  `gsm` varchar(20) DEFAULT NULL,
  `email` varchar(90) DEFAULT NULL,
  `lieu_naissance` varchar(120) DEFAULT NULL,
  `nationalite` varchar(90) DEFAULT NULL,
  `etat_civil` varchar(50) DEFAULT NULL,
  `personne_contact` varchar(200) DEFAULT NULL,
  `personne_contact_telephone` varchar(20) DEFAULT NULL,
  `observations` longtext DEFAULT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `permis_recto` varchar(255) DEFAULT NULL COMMENT 'Chemin vers la photo recto du permis de conduire',
  `permis_verso` varchar(255) DEFAULT NULL COMMENT 'Chemin vers la photo verso du permis de conduire',
  `permis_date_emission` date DEFAULT NULL COMMENT 'Date d''émission du permis de conduire',
  `permis_date_expiration` date DEFAULT NULL COMMENT 'Date d''expiration du permis de conduire'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `particuliers`
--
ALTER TABLE `particuliers`
  ADD PRIMARY KEY (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
