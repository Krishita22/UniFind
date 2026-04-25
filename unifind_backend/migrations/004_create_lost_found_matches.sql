-- Lost & Found Matches table
CREATE TABLE IF NOT EXISTS lost_found_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lost_item_id INT NOT NULL,
    matched_found_item_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'resolved') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lost_item_id) REFERENCES lost_found_items(id) ON DELETE CASCADE,
    FOREIGN KEY (matched_found_item_id) REFERENCES lost_found_items(id) ON DELETE CASCADE,
    INDEX (status),
    INDEX (lost_item_id),
    INDEX (matched_found_item_id)
);
