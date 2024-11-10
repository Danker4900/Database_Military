-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Час створення: Лис 08 2024 р., 10:40
-- Версія сервера: 10.4.32-MariaDB-log
-- Версія PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База даних: `military`
--

DELIMITER $$
--
-- Процедури
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `DestroyFirePosition` (IN `p_positionId` INT)   BEGIN
    DECLARE ammoCount INT;

    SELECT COUNT(*) INTO ammoCount
    FROM ammo
    WHERE position_id = p_positionId;

    IF ammoCount > 0 THEN
        UPDATE ammo
        SET is_destroyed = TRUE
        WHERE position_id = p_positionId;
    END IF;

    UPDATE fire_positions
    SET is_destroyed = TRUE
    WHERE id = p_positionId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FireShot` (IN `p_ammoType` VARCHAR(20), IN `p_targetId` INT, IN `p_ammoCount` INT, IN `p_furtherDistance` INT, IN `p_closerDistance` INT)   BEGIN
    DECLARE availableAmmo INT;

    SELECT ammo_count INTO availableAmmo
    FROM ammunitions
    WHERE code = p_ammoType;

    IF availableAmmo >= p_ammoCount THEN
        UPDATE ammunitions
        SET ammo_count = ammo_count - p_ammoCount
        WHERE code = p_ammoType;

        INSERT INTO shots (ammo_type, target_id, further, closer)
        VALUES (p_ammoType, p_targetId, p_furtherDistance, p_closerDistance);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough ammunition';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `MoveGunPosition` (IN `p_positionId` INT, IN `p_newX` FLOAT, IN `p_newY` FLOAT)   BEGIN
    DECLARE positionDestroyed BOOLEAN;

    SELECT is_destroyed INTO positionDestroyed
    FROM fire_positions
    WHERE id = p_positionId;

    IF positionDestroyed THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Position is destroyed, cannot move';
    ELSE
        UPDATE fire_positions
        SET x = p_newX, y = p_newY
        WHERE id = p_positionId;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблиці `ammo`
--

CREATE TABLE `ammo` (
  `id` int(11) NOT NULL,
  `ammo_type` varchar(20) NOT NULL,
  `mass` decimal(3,2) NOT NULL,
  `caliber` int(11) NOT NULL,
  `position_id` int(11) DEFAULT NULL,
  `is_destroyed` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Дублююча структура для представлення `ammo_inventory`
-- (Див. нижче для фактичного подання)
--
CREATE TABLE `ammo_inventory` (
`position_id` int(11)
,`x` float
,`y` float
,`ammo_type` varchar(20)
,`total_mass` decimal(25,2)
);

-- --------------------------------------------------------

--
-- Структура таблиці `corrections`
--

CREATE TABLE `corrections` (
  `id` int(11) NOT NULL,
  `commander` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `people` int(11) DEFAULT NULL,
  `age` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблиці `fire_positions`
--

CREATE TABLE `fire_positions` (
  `id` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `weapon_id` int(11) DEFAULT NULL,
  `is_destroyed` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблиці `fire_tasks`
--

CREATE TABLE `fire_tasks` (
  `id` int(11) NOT NULL,
  `position_id` int(11) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `ammo_type` varchar(20) DEFAULT NULL,
  `ammo_count` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблиці `shots`
--

CREATE TABLE `shots` (
  `id` int(11) NOT NULL,
  `ammo_type` varchar(20) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `position_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблиці `targets`
--

CREATE TABLE `targets` (
  `id` int(11) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблиці `units`
--

CREATE TABLE `units` (
  `id` int(11) NOT NULL,
  `commander` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `people` int(11) DEFAULT NULL,
  `age` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура таблиці `weapons`
--

CREATE TABLE `weapons` (
  `id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `caliber` int(11) DEFAULT NULL,
  `commander` varchar(50) DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `is_destroyed` tinyint(1) DEFAULT 0,
  `distance` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Структура для представлення `ammo_inventory`
--
DROP TABLE IF EXISTS `ammo_inventory`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ammo_inventory`  AS SELECT `f`.`id` AS `position_id`, `f`.`x` AS `x`, `f`.`y` AS `y`, `a`.`ammo_type` AS `ammo_type`, sum(`a`.`mass`) AS `total_mass` FROM (`fire_positions` `f` join `ammo` `a` on(`f`.`id` = `a`.`position_id`)) WHERE `f`.`is_destroyed` = 0 GROUP BY `f`.`id`, `a`.`ammo_type` ;

--
-- Індекси збережених таблиць
--

--
-- Індекси таблиці `ammo`
--
ALTER TABLE `ammo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `position_id` (`position_id`);

--
-- Індекси таблиці `corrections`
--
ALTER TABLE `corrections`
  ADD PRIMARY KEY (`id`);

--
-- Індекси таблиці `fire_positions`
--
ALTER TABLE `fire_positions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `unit_id` (`unit_id`),
  ADD KEY `weapon_id` (`weapon_id`);

--
-- Індекси таблиці `fire_tasks`
--
ALTER TABLE `fire_tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `position_id` (`position_id`),
  ADD KEY `target_id` (`target_id`);

--
-- Індекси таблиці `shots`
--
ALTER TABLE `shots`
  ADD PRIMARY KEY (`id`),
  ADD KEY `target_id` (`target_id`),
  ADD KEY `position_id` (`position_id`);

--
-- Індекси таблиці `targets`
--
ALTER TABLE `targets`
  ADD PRIMARY KEY (`id`);

--
-- Індекси таблиці `units`
--
ALTER TABLE `units`
  ADD PRIMARY KEY (`id`);

--
-- Індекси таблиці `weapons`
--
ALTER TABLE `weapons`
  ADD PRIMARY KEY (`id`),
  ADD KEY `unit_id` (`unit_id`);

--
-- AUTO_INCREMENT для збережених таблиць
--

--
-- AUTO_INCREMENT для таблиці `ammo`
--
ALTER TABLE `ammo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `corrections`
--
ALTER TABLE `corrections`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `fire_positions`
--
ALTER TABLE `fire_positions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `fire_tasks`
--
ALTER TABLE `fire_tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `shots`
--
ALTER TABLE `shots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `targets`
--
ALTER TABLE `targets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `units`
--
ALTER TABLE `units`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблиці `weapons`
--
ALTER TABLE `weapons`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Обмеження зовнішнього ключа збережених таблиць
--

--
-- Обмеження зовнішнього ключа таблиці `ammo`
--
ALTER TABLE `ammo`
  ADD CONSTRAINT `ammo_ibfk_1` FOREIGN KEY (`position_id`) REFERENCES `fire_positions` (`id`);

--
-- Обмеження зовнішнього ключа таблиці `fire_positions`
--
ALTER TABLE `fire_positions`
  ADD CONSTRAINT `fire_positions_ibfk_1` FOREIGN KEY (`unit_id`) REFERENCES `units` (`id`),
  ADD CONSTRAINT `fire_positions_ibfk_2` FOREIGN KEY (`weapon_id`) REFERENCES `weapons` (`id`);

--
-- Обмеження зовнішнього ключа таблиці `fire_tasks`
--
ALTER TABLE `fire_tasks`
  ADD CONSTRAINT `fire_tasks_ibfk_1` FOREIGN KEY (`position_id`) REFERENCES `fire_positions` (`id`),
  ADD CONSTRAINT `fire_tasks_ibfk_2` FOREIGN KEY (`target_id`) REFERENCES `targets` (`id`);

--
-- Обмеження зовнішнього ключа таблиці `shots`
--
ALTER TABLE `shots`
  ADD CONSTRAINT `shots_ibfk_1` FOREIGN KEY (`target_id`) REFERENCES `targets` (`id`),
  ADD CONSTRAINT `shots_ibfk_2` FOREIGN KEY (`position_id`) REFERENCES `fire_positions` (`id`);

--
-- Обмеження зовнішнього ключа таблиці `weapons`
--
ALTER TABLE `weapons`
  ADD CONSTRAINT `weapons_ibfk_1` FOREIGN KEY (`unit_id`) REFERENCES `units` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
