-- Users Table
CREATE TABLE Users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    team_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES Teams(id) ON DELETE SET NULL -- A user can exist without a team initially, or if a team is deleted
);

-- Teams Table
CREATE TABLE Teams (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Status Table (for Note status)
CREATE TABLE Status (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE -- e.g., 'open', 'in progress', 'completed', 'archived'
);

-- Notes Table
CREATE TABLE Notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_by INT NOT NULL,
    team_id INT,
    due_date DATETIME,
    status_id INT NOT NULL,
    priority INT DEFAULT 2, -- Added: e.g., 1=Low, 2=Medium, 3=High. Defaults to Medium.
    is_public_to_team BOOLEAN DEFAULT FALSE, -- Added: Indicates if note is visible to everyone in the creator's team
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(id) ON DELETE CASCADE, -- If user is deleted, their notes are deleted
    FOREIGN KEY (team_id) REFERENCES Teams(id) ON DELETE SET NULL, -- If team is deleted, note is unassigned from team but not deleted
    FOREIGN KEY (status_id) REFERENCES Status(id) -- Status of the note
);

-- Attachments Table
CREATE TABLE Attachments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    note_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1024) NOT NULL, -- Could also be a URL if stored in cloud storage
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (note_id) REFERENCES Notes(id) ON DELETE CASCADE -- If note is deleted, attachments are deleted
);

-- Tags Table
CREATE TABLE Tags (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- NoteTags Junction Table (for Many-to-Many relationship between Notes and Tags)
CREATE TABLE NoteTags (
    note_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (note_id, tag_id),
    FOREIGN KEY (note_id) REFERENCES Notes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE
);

-- SharedWith Table (for sharing notes with users)
CREATE TABLE SharedWith (
    note_id INT NOT NULL,
    user_id INT NOT NULL,
    permission_level VARCHAR(20) NOT NULL DEFAULT 'view', -- e.g., 'view', 'comment', 'edit'
    shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (note_id, user_id),
    FOREIGN KEY (note_id) REFERENCES Notes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    CONSTRAINT check_permission_level CHECK (permission_level IN ('view', 'comment', 'edit')) -- Ensures valid permission levels
);

-- Sample Statuses
INSERT INTO Status (name) VALUES ('open'), ('in progress'), ('completed'), ('archived');
