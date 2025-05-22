# API Endpoints and Schema Updates for Sharing and Permissions

This document details the necessary updates to `database_schema.sql` for enhanced sharing and permissions capabilities, and defines the API endpoints for managing these features.

---

## 1. Updates to `database_schema.sql` for Sharing & Permissions

### 1.1. `SharedWith` Table Update

The `SharedWith` table will be updated to formalize permission levels for sharing notes with specific users.

**Proposed Change to `database_schema.sql` for `SharedWith` Table:**
```sql
-- SharedWith Table (with formalized permission_level)
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
```

**Documentation of Changes:**
*   The `permission_level` column is now `VARCHAR(20)` and `NOT NULL`.
*   It has a `DEFAULT` value of `'view'`.
*   A `CHECK` constraint `check_permission_level` is added to ensure that `permission_level` can only be one of the predefined values: `'view'`, `'comment'`, or `'edit'`.

### 1.2. `Notes` Table Update

The `Notes` table will be updated to include a flag indicating whether a note is visible to the entire team of the note's creator.

**Proposed Change to `database_schema.sql` for `Notes` Table:**
(Assuming the `priority` field from a previous task has already been added. If not, the existing `Notes` table definition should be used as a base.)

```sql
-- Notes Table (with added is_public_to_team and priority fields)
CREATE TABLE Notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_by INT NOT NULL,
    team_id INT, -- The team this note is primarily associated with (can be null)
    due_date DATETIME,
    status_id INT NOT NULL,
    priority INT DEFAULT 2, 
    is_public_to_team BOOLEAN DEFAULT FALSE, -- Added: Indicates if note is visible to everyone in the creator's team
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES Teams(id) ON DELETE SET NULL,
    FOREIGN KEY (status_id) REFERENCES Status(id)
);
```

**Documentation of Changes:**
*   Added a new column `is_public_to_team` to the `Notes` table.
*   `is_public_to_team` is a `BOOLEAN` type.
*   It has a `DEFAULT` value of `FALSE`, meaning notes are private by default to the creator and explicitly shared users/teams.
*   If `team_id` is set on a note, and `is_public_to_team` is `TRUE`, then all members of that `team_id` can view/access the note (permission level might be implicitly 'view' or 'comment', TBD by application logic).

---

## 2. API Endpoints for Sharing and Permissions Management

These endpoints allow sharing notes with specific users and managing their permissions.

### 2.1. Share a Note with a User

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/notes/{note_id}/shares`
*   **Brief Description:** Shares the specified note with a user and sets their permission level. This creates an entry in the `SharedWith` table.
*   **Example Request Body:**
    ```json
    {
      "user_id": 2, // ID of the user to share with
      "permission_level": "edit" // e.g., 'view', 'comment', 'edit'
    }
    ```
*   **Example Response Body (201 Created):**
    ```json
    {
      "note_id": 123,
      "user_id": 2,
      "permission_level": "edit",
      "shared_at": "2024-01-23T10:00:00Z"
    }
    ```

### 2.2. Update a User's Permission for a Shared Note

*   **HTTP Method:** `PUT`
*   **URL Path:** `/api/notes/{note_id}/shares/{user_id}`
*   **Brief Description:** Updates the permission level for a user who already has access to the shared note.
*   **Example Request Body:**
    ```json
    {
      "permission_level": "view" // New permission level
    }
    ```
*   **Example Response Body (200 OK):**
    ```json
    {
      "note_id": 123,
      "user_id": 2,
      "permission_level": "view",
      "shared_at": "2024-01-23T10:00:00Z" // Original shared_at, updated_at for this record could be added
    }
    ```

### 2.3. Remove a User's Access to a Shared Note

*   **HTTP Method:** `DELETE`
*   **URL Path:** `/api/notes/{note_id}/shares/{user_id}`
*   **Brief Description:** Revokes a user's access to a shared note by deleting the corresponding entry in the `SharedWith` table.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK with a message or 204 No Content):**
    ```json
    // Example for 200 OK
    {
      "message": "Access for user ID 2 to note ID 123 has been revoked."
    }
    ```

### 2.4. List Users with Whom a Note is Shared

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/notes/{note_id}/shares`
*   **Brief Description:** Retrieves a list of users with whom the specified note is shared, including their permission levels.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    [
      {
        "user_id": 2,
        "name": "Jane Doe", // Fetched via a JOIN with the Users table
        "email": "jane.doe@example.com", // also from Users table
        "permission_level": "edit",
        "shared_at": "2024-01-23T10:00:00Z"
      },
      {
        "user_id": 3,
        "name": "Peter Pan",
        "email": "peter.pan@example.com",
        "permission_level": "view",
        "shared_at": "2024-01-23T10:05:00Z"
      }
    ]
    ```

---

## 3. Management of `is_public_to_team` Flag

The `is_public_to_team` boolean flag on a note determines its visibility to the entire team associated with the note (via the `Notes.team_id` field). This flag can be managed as part of the existing note update endpoint.

*   **Endpoint:** `PUT /api/notes/{note_id}` (or `PATCH /api/notes/{note_id}`)
*   **Brief Description:** Updates an existing note. This endpoint will now also handle updates to the note's `is_public_to_team` flag.
*   **Inclusion of `is_public_to_team` in Request Body:**
    When updating a note, the `is_public_to_team` field (boolean) should be included in the request body if its value needs to be changed.

    **Example Request Body for `PUT /api/notes/{note_id}` (including `is_public_to_team`):**
    ```json
    {
      "title": "Team Visible Note",
      "content": "This note is now visible to the whole team.",
      "team_id": 1, // Note must be associated with a team for this flag to be meaningful
      "due_date": "2025-02-01T12:00:00Z",
      "status_id": 1,
      "priority": 2,
      "is_public_to_team": true // Set to true to make it visible to all members of team_id 1
    }
    ```
*   **Backend Handling:**
    *   The backend logic for `PUT /api/notes/{note_id}` should be updated to read the `is_public_to_team` value from the request body and save it to the corresponding column in the `Notes` table.
    *   If `is_public_to_team` is set to `true`, the `team_id` on the note should ideally not be `NULL`. The application should enforce this logic (either at API or database level if possible, though database level is harder for conditional requirements like this).
*   **Response Body:** The response body for `PUT /api/notes/{note_id}` should include the updated `is_public_to_team` field.

    **Example Response Body (200 OK, reflecting updated `is_public_to_team`):**
    ```json
    {
      "id": 124,
      "title": "Team Visible Note",
      "content": "This note is now visible to the whole team.",
      "created_by": 45,
      "team_id": 1,
      "due_date": "2025-02-01T12:00:00Z",
      "status_id": 1,
      "priority": 2,
      "is_public_to_team": true, // Updated flag reflected
      "created_at": "2024-01-23T11:00:00Z",
      "updated_at": "2024-01-23T11:30:00Z"
    }
    ```

This comprehensive approach covers both direct user sharing with specific permissions and broader team-level visibility for notes.
---
