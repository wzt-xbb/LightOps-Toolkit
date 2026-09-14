-- =============================================
-- LightOps Demo Database Initialization
-- =============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS lightops_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- 切换到数据库
USE lightops_demo;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入测试数据
INSERT INTO users (username, email) VALUES
('admin', 'admin@example.com'),
('user1', 'user1@example.com'),
('user2', 'user2@example.com'),
('user3', 'user3@example.com')
ON DUPLICATE KEY UPDATE
    username=VALUES(username),
    email=VALUES(email);

-- 插入更多测试数据
INSERT INTO users (username, email) VALUES
('testuser', 'testuser@example.com')
ON DUPLICATE KEY UPDATE username=VALUES(username), email=VALUES(email);
