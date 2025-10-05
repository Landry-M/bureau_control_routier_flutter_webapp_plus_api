-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 05, 2025 at 09:16 AM
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
-- Table structure for table `vehicule_plaque`
--

CREATE TABLE `vehicule_plaque` (
  `id` bigint(20) NOT NULL,
  `images` longtext DEFAULT NULL,
  `marque` varchar(80) NOT NULL,
  `annee` varchar(10) DEFAULT NULL,
  `couleur` varchar(50) DEFAULT NULL,
  `modele` varchar(100) DEFAULT NULL,
  `numero_chassis` varchar(250) DEFAULT NULL,
  `frontiere_entree` varchar(191) DEFAULT NULL,
  `date_importation` date DEFAULT NULL,
  `plaque` varchar(20) DEFAULT NULL,
  `plaque_valide_le` datetime DEFAULT NULL,
  `plaque_expire_le` datetime DEFAULT NULL,
  `en_circulation` tinyint(1) NOT NULL DEFAULT 1,
  `nume_assurance` varchar(90) DEFAULT NULL,
  `date_expire_assurance` datetime DEFAULT NULL,
  `date_valide_assurance` datetime DEFAULT NULL,
  `societe_assurance` varchar(90) DEFAULT NULL,
  `genre` varchar(100) DEFAULT NULL,
  `usage` varchar(150) DEFAULT NULL,
  `numero_declaration` varchar(150) DEFAULT NULL,
  `num_moteur` varchar(150) DEFAULT NULL,
  `origine` varchar(150) DEFAULT NULL,
  `source` varchar(150) DEFAULT NULL,
  `annee_fab` varchar(10) DEFAULT NULL,
  `annee_circ` varchar(10) DEFAULT NULL,
  `type_em` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `vehicule_plaque`
--

INSERT INTO `vehicule_plaque` (`id`, `images`, `marque`, `annee`, `couleur`, `modele`, `numero_chassis`, `frontiere_entree`, `date_importation`, `plaque`, `plaque_valide_le`, `plaque_expire_le`, `en_circulation`, `nume_assurance`, `date_expire_assurance`, `date_valide_assurance`, `societe_assurance`, `genre`, `usage`, `numero_declaration`, `num_moteur`, `origine`, `source`, `annee_fab`, `annee_circ`, `type_em`, `created_at`, `updated_at`) VALUES
(1, '[\"\\/api\\/uploads\\/vehicules\\/img_68e1e1fc22c792.47233675.png\"]', 'bmw', '2022', 'noire', 'arc5', NULL, 'kasumbalesa', '2025-10-30', '4455AA05', '2025-10-23 00:00:00', '2025-10-01 00:00:00', 1, NULL, NULL, NULL, NULL, NULL, 'transport', 'teste', NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-05 05:11:56', '2025-10-05 05:11:56'),
(2, '[\"\\/api\\/uploads\\/vehicules\\/img_68e1e376977f79.34032833.jpg\",\"\\/api\\/uploads\\/vehicules\\/img_68e1e37697bdb2.15573553.jpg\"]', 'toyoya', NULL, 'bleu', 'rav4', NULL, NULL, NULL, '0000AA05', '2025-10-01 00:00:00', '2025-10-04 00:00:00', 1, 'AAAAAA12', '2025-09-30 00:00:00', '2025-09-08 00:00:00', 'SONAS', 'automatique', 'transport', NULL, NULL, 'chine', NULL, NULL, NULL, NULL, '2025-10-05 05:18:14', '2025-10-05 05:18:14'),
(4, '[\"\\/api\\/uploads\\/vehicules\\/img_68e1e4856b7842.50205346.png\",\"\\/api\\/uploads\\/vehicules\\/img_68e1e4856ba782.14976951.png\"]', 'peugeot', '2020', 'oire', 'arizona', NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 'SONAS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-05 05:22:45', '2025-10-05 05:22:45'),
(5, '[]', 'tests', NULL, 'noire', 'sm98', NULL, NULL, NULL, '0000AA05', NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-05 06:28:27', '2025-10-05 06:28:27');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `vehicule_plaque`
--
ALTER TABLE `vehicule_plaque`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `vehicule_plaque`
--
ALTER TABLE `vehicule_plaque`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
