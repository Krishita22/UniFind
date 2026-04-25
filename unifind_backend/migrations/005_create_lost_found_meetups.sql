-- Lost & Found Meetups table
CREATE TABLE IF NOT EXISTS lost_found_meetups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    meetup_date DATE NOT NULL,
    meetup_time TIME NOT NULL,
    meetup_location VARCHAR(255) NOT NULL,
    status ENUM('pending', 'approved', 'denied', 'resolved') DEFAULT 'pending',
    denial_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES lost_found_matches(id) ON DELETE CASCADE,
    INDEX (status),
    INDEX (match_id)
);
