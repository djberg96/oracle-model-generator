-- SQL Server Database Initialization Script
-- Creates a test database and sample tables for the Database Model Generator

-- Create test database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'test_db')
BEGIN
    CREATE DATABASE test_db;
END
GO

USE test_db;
GO

-- Create users table with various column types
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
BEGIN
    CREATE TABLE users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(50) NOT NULL UNIQUE,
        email NVARCHAR(100) NOT NULL UNIQUE,
        first_name NVARCHAR(50) NOT NULL,
        last_name NVARCHAR(50) NOT NULL,
        age INT,
        salary DECIMAL(10,2),
        is_active BIT DEFAULT 1,
        status NVARCHAR(20) DEFAULT 'active',
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        bio NVARCHAR(MAX),
        profile_picture VARBINARY(MAX)
    );
END
GO

-- Create posts table with foreign key relationship
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='posts' AND xtype='U')
BEGIN
    CREATE TABLE posts (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        title NVARCHAR(200) NOT NULL,
        content NVARCHAR(MAX),
        status NVARCHAR(20) DEFAULT 'draft',
        published_at DATETIME2,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        view_count INT DEFAULT 0,
        is_featured BIT DEFAULT 0,

        CONSTRAINT FK_posts_user_id FOREIGN KEY (user_id) REFERENCES users(id)
    );
END
GO

-- Create categories table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='categories' AND xtype='U')
BEGIN
    CREATE TABLE categories (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL UNIQUE,
        description NVARCHAR(500),
        slug NVARCHAR(100) NOT NULL UNIQUE,
        parent_id INT,
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id)
    );
END
GO

-- Create post_categories junction table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='post_categories' AND xtype='U')
BEGIN
    CREATE TABLE post_categories (
        id INT IDENTITY(1,1) PRIMARY KEY,
        post_id INT NOT NULL,
        category_id INT NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_post_categories_post FOREIGN KEY (post_id) REFERENCES posts(id),
        CONSTRAINT FK_post_categories_category FOREIGN KEY (category_id) REFERENCES categories(id),
        CONSTRAINT UQ_post_categories UNIQUE (post_id, category_id)
    );
END
GO

-- Create comments table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='comments' AND xtype='U')
BEGIN
    CREATE TABLE comments (
        id INT IDENTITY(1,1) PRIMARY KEY,
        post_id INT NOT NULL,
        user_id INT NOT NULL,
        content NVARCHAR(MAX) NOT NULL,
        status NVARCHAR(20) DEFAULT 'pending',
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_comments_post FOREIGN KEY (post_id) REFERENCES posts(id),
        CONSTRAINT FK_comments_user FOREIGN KEY (user_id) REFERENCES users(id)
    );
END
GO

-- Insert sample data
INSERT INTO users (username, email, first_name, last_name, age, salary, status, bio)
VALUES
    ('jdoe', 'john.doe@example.com', 'John', 'Doe', 30, 75000.00, 'active', 'Software developer with 5 years experience'),
    ('asmith', 'alice.smith@example.com', 'Alice', 'Smith', 28, 82000.00, 'active', 'Frontend specialist and UI/UX designer'),
    ('bwilson', 'bob.wilson@example.com', 'Bob', 'Wilson', 35, 95000.00, 'active', 'Senior backend engineer'),
    ('cmiller', 'carol.miller@example.com', 'Carol', 'Miller', 32, 88000.00, 'inactive', 'Database administrator');
GO

INSERT INTO categories (name, description, slug)
VALUES
    ('Technology', 'Posts about technology and programming', 'technology'),
    ('Web Development', 'Frontend and backend web development', 'web-development'),
    ('Database', 'Database design and administration', 'database'),
    ('Career', 'Career advice and professional development', 'career');
GO

INSERT INTO posts (user_id, title, content, status, published_at, view_count, is_featured)
VALUES
    (1, 'Getting Started with SQL Server', 'This post covers the basics of SQL Server...', 'published', GETDATE(), 150, 1),
    (2, 'Modern CSS Techniques', 'Learn about the latest CSS features...', 'published', GETDATE(), 89, 0),
    (3, 'Microservices Architecture', 'Building scalable applications with microservices...', 'published', GETDATE(), 234, 1),
    (1, 'Draft Post', 'This is a draft post...', 'draft', NULL, 0, 0);
GO

INSERT INTO post_categories (post_id, category_id)
VALUES
    (1, 1), (1, 3),  -- Technology, Database
    (2, 1), (2, 2),  -- Technology, Web Development
    (3, 1), (3, 2),  -- Technology, Web Development
    (4, 4);          -- Career
GO

INSERT INTO comments (post_id, user_id, content, status)
VALUES
    (1, 2, 'Great introduction to SQL Server!', 'approved'),
    (1, 3, 'Very helpful, thanks for sharing.', 'approved'),
    (2, 1, 'Love these CSS tips!', 'approved'),
    (3, 4, 'Microservices can be complex but worth it.', 'pending');
GO

-- Create some additional indexes for testing index recommendations
CREATE INDEX IX_users_email ON users(email);
CREATE INDEX IX_users_status ON users(status);
CREATE INDEX IX_posts_user_id ON posts(user_id);
CREATE INDEX IX_posts_status ON posts(status);
CREATE INDEX IX_posts_created_at ON posts(created_at);
CREATE INDEX IX_comments_post_id ON comments(post_id);

PRINT 'Database initialization completed successfully!';
PRINT 'Created tables: users, posts, categories, post_categories, comments';
PRINT 'Inserted sample data for testing';
GO
