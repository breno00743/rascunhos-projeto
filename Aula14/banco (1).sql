-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 12/11/2026 às 01:39
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `banco`
--
CREATE DATABASE IF NOT EXISTS `banco` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `banco`;

-- --------------------------------------------------------

--
-- Estrutura para tabela `amizades`
--

CREATE TABLE `amizades` (
  `id` int(11) NOT NULL,
  `usuario1_email` varchar(255) NOT NULL,
  `usuario2_email` varchar(255) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'aceita',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `amizades`
--

INSERT INTO `amizades` (`id`, `usuario1_email`, `usuario2_email`, `status`, `created_at`) VALUES
(1, 'brenonobre2005@gmail.com', 'caue123@gmail.com', 'aceita', '2026-11-12 00:34:06');

-- --------------------------------------------------------

--
-- Estrutura para tabela `comentarios`
--

CREATE TABLE `comentarios` (
  `id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `usuario_nome` varchar(255) NOT NULL,
  `usuario_email` varchar(255) DEFAULT NULL,
  `texto` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `comentarios`
--

INSERT INTO `comentarios` (`id`, `post_id`, `usuario_nome`, `usuario_email`, `texto`, `created_at`) VALUES
(1, 2, 'breno', 'brenonobre2005@gmail.com', 'boa', '2026-11-12 00:28:07'),
(2, 2, 'breno', 'brenonobre2005@gmail.com', 'boa', '2026-11-12 00:28:52');

-- --------------------------------------------------------

--
-- Estrutura para tabela `curtidas`
--

CREATE TABLE `curtidas` (
  `id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `usuario_email` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `curtidas`
--

INSERT INTO `curtidas` (`id`, `post_id`, `usuario_email`, `created_at`) VALUES
(1, 1, 'caue123@gmail.com', '2026-11-12 00:24:21'),
(2, 2, 'brenonobre2005@gmail.com', '2026-11-12 00:28:49');

-- --------------------------------------------------------

--
-- Estrutura para tabela `notificacoes`
--

CREATE TABLE `notificacoes` (
  `id` int(11) NOT NULL,
  `para_email` varchar(255) NOT NULL,
  `remetente_email` varchar(255) NOT NULL,
  `remetente_nome` varchar(255) NOT NULL,
  `mensagem` varchar(255) NOT NULL,
  `tipo` varchar(50) NOT NULL DEFAULT 'amizade',
  `lida` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `notificacoes`
--

INSERT INTO `notificacoes` (`id`, `para_email`, `remetente_email`, `remetente_nome`, `mensagem`, `tipo`, `lida`, `created_at`) VALUES
(2, 'brenonobre2005@gmail.com', 'caue123@gmail.com', 'caue', 'caue enviou um convite de amizade.', 'amizade', 0, '2026-11-12 00:34:18');

-- --------------------------------------------------------

--
-- Estrutura para tabela `posts`
--

CREATE TABLE `posts` (
  `id` int(11) NOT NULL,
  `usuario_nome` varchar(255) NOT NULL,
  `usuario_email` varchar(255) DEFAULT NULL,
  `texto` longtext DEFAULT NULL,
  `descricao` varchar(255) DEFAULT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `posts`
--

INSERT INTO `posts` (`id`, `usuario_nome`, `usuario_email`, `texto`, `descricao`, `foto`, `created_at`) VALUES
(1, 'breno', '', 'ola', 'ola', NULL, '2026-11-12 00:23:58'),
(2, 'caue', 'caue123@gmail.com', 'ola', 'ola', NULL, '2026-11-12 00:27:08'),
(3, 'breno', 'brenonobre2005@gmail.com', 'ola', 'ola', 'fotos/foto_6af508101bb126.18016510.jpg', '2026-11-12 00:28:00'),
(4, 'caue', 'caue123@gmail.com', 'bora jgoar cs', 'bora jgoar cs', 'fotos/foto_6af50a03566b06.59718305.jpg', '2026-11-12 00:36:19');

-- --------------------------------------------------------

--
-- Estrutura para tabela `solicitacoes_amizade`
--

CREATE TABLE `solicitacoes_amizade` (
  `id` int(11) NOT NULL,
  `de_nome` varchar(255) NOT NULL,
  `de_email` varchar(255) NOT NULL,
  `para_email` varchar(255) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pendente',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `solicitacoes_amizade`
--

INSERT INTO `solicitacoes_amizade` (`id`, `de_nome`, `de_email`, `para_email`, `status`, `created_at`) VALUES
(1, 'breno', 'brenonobre2005@gmail.com', 'caue123@gmail.com', 'aceita', '2026-11-12 00:33:50'),
(2, 'caue', 'caue123@gmail.com', 'brenonobre2005@gmail.com', 'pendente', '2026-11-12 00:34:18');

-- --------------------------------------------------------

--
-- Estrutura para tabela `textos`
--

CREATE TABLE `textos` (
  `id` int(11) NOT NULL,
  `texto` char(200) NOT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `descricao` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `textos`
--

INSERT INTO `textos` (`id`, `texto`, `foto`, `descricao`) VALUES
(1, 'ola rapaziada', 'fotos/foto_6af505247e77b1.32237268.jpg', 'ola rapaziada');

-- --------------------------------------------------------

--
-- Estrutura para tabela `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id`, `nome`, `email`, `senha`, `created_at`) VALUES
(1, 'breno', 'brenonobre2005@gmail.com', '$2y$10$rPM5iPMlvzz9Td4TGexUEOCZOm/m1O9qgw4quQd11C30IFcnI3Wc6', '2026-11-11 22:54:49'),
(2, 'caue', 'caue123@gmail.com', '$2y$10$tLEzXPc/QKZkDLfnYhwv5eR9SNLAcdbDjBF3j.Bl5jeEZSR4CQR.e', '2026-11-11 23:18:10'),
(3, 'breno', 'breno123@gmail.com', '$2y$10$y6zlEDfGlmH9s8PkFgP2zuf5TWapoEFP.OjeeSyTWKn/lZFXKsn.G', '2026-11-11 23:19:22');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `amizades`
--
ALTER TABLE `amizades`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_amizade` (`usuario1_email`,`usuario2_email`);

--
-- Índices de tabela `comentarios`
--
ALTER TABLE `comentarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_post_id` (`post_id`);

--
-- Índices de tabela `curtidas`
--
ALTER TABLE `curtidas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_curtida` (`post_id`,`usuario_email`),
  ADD KEY `idx_curtiu_post` (`post_id`);

--
-- Índices de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_para_email` (`para_email`);

--
-- Índices de tabela `posts`
--
ALTER TABLE `posts`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `solicitacoes_amizade`
--
ALTER TABLE `solicitacoes_amizade`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_solicitacao` (`de_email`,`para_email`);

--
-- Índices de tabela `textos`
--
ALTER TABLE `textos`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `amizades`
--
ALTER TABLE `amizades`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `comentarios`
--
ALTER TABLE `comentarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `curtidas`
--
ALTER TABLE `curtidas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `notificacoes`
--
ALTER TABLE `notificacoes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `posts`
--
ALTER TABLE `posts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `solicitacoes_amizade`
--
ALTER TABLE `solicitacoes_amizade`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `textos`
--
ALTER TABLE `textos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de tabela `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `comentarios`
--
ALTER TABLE `comentarios`
  ADD CONSTRAINT `fk_comentarios_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `curtidas`
--
ALTER TABLE `curtidas`
  ADD CONSTRAINT `fk_curtidas_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
