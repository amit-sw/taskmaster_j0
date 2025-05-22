# API Endpoints for Tags and Priority Management

This document details the necessary updates for managing `priority` in notes and defines the API endpoints for tag management.

---

## 1. Update to `Notes` Table Schema for Priority

The `Notes` table in `database_schema.sql` needs a field to store the priority of a note.

**Proposed Change to `database_schema.sql`:**

Modify the `Notes` table definition to include a `priority` field. We'll use an integer representation for priority levels.

```sql
-- Notes Table (with added priority field)
CREATE TABLE Notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_by INT NOT NULL,
    team_id INT,
    due_date DATETIME,
    status_id INT NOT NULL,
    priority INT DEFAULT 2, -- Added: e.g., 1=Low, 2=Medium, 3=High. Defaults to Medium.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES Teams(id) ON DELETE SET NULL,
    FOREIGN KEY (status_id) REFERENCES Status(id)
);
```

**Documentation of Change:**
*   Added a new column `priority` to the `Notes` table.
*   `priority` is an `INT` type.
*   It has a `DEFAULT` value of `2` (Medium priority).
*   **Suggested Enum/Mapping:**
    *   `1`: Low
    *   `2`: Medium
    *   `3`: High
    *(This mapping should be maintained consistently by the application frontend and backend).*

---

## 2. API Endpoints for Tag Management

These endpoints facilitate the creation of tags and their association with notes.

### 2.1. Create a new Tag

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/tags`
*   **Brief Description:** Creates a new global tag that can then be applied to notes.
*   **Example Request Body:**
    ```json
    {
      "name": "Urgent"
    }
    ```
*   **Example Response Body (201 Created):**
    ```json
    {
      "id": 1,
      "name": "Urgent",
      "created_at": "2024-01-22T10:00:00Z"
    }
    ```
    *(This response assumes the `Tags` table schema from `database_schema.sql` which includes `id`, `name`, and `created_at`.)*

### 2.2. List all existing Tags

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/tags`
*   **Brief Description:** Retrieves a list of all globally available tags.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    [
      {
        "id": 1,
        "name": "Urgent",
        "created_at": "2024-01-22T10:00:00Z"
      },
      {
        "id": 2,
        "name": "ProjectX",
        "created_at": "2024-01-22T10:05:00Z"
      },
      {
        "id": 3,
        "name": "Follow-up",
        "created_at": "2024-01-22T10:10:00Z"
      }
    ]
    ```

### 2.3. Add a Tag to a Note

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/notes/{note_id}/tags`
*   **Brief Description:** Associates an existing tag with a specific note. This action creates an entry in the `NoteTags` junction table.
*   **Example Request Body:**
    ```json
    {
      "tag_id": 1 // ID of the existing tag to add
    }
    ```
*   **Example Response Body (201 Created or 200 OK):**
    ```json
    {
      "message": "Tag with ID 1 added to note with ID 123 successfully.",
      "note_id": 123,
      "tag_id": 1
    }
    ```
    *(Alternatively, could return the updated list of tags for the note, or the created `NoteTags` entry).*

### 2.4. Remove a Tag from a Note

*   **HTTP Method:** `DELETE`
*   **URL Path:** `/api/notes/{note_id}/tags/{tag_id}`
*   **Brief Description:** Removes the association of a tag from a specific note. This action deletes an entry from the `NoteTags` junction table.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK with a message or 204 No Content):**
    ```json
    // Example for 200 OK
    {
      "message": "Tag with ID 1 removed from note with ID 123 successfully."
    }
    ```
    *(A 204 No Content response is also common and appropriate.)*

---

## 3. Clarification on Priority in Note Update API

The `priority` of a note, now added to the `Notes` table schema, should be updatable via the existing note update endpoint.

*   **Endpoint:** `PUT /api/notes/{note_id}` (or `PATCH /api/notes/{note_id}`)
*   **Brief Description:** Updates an existing note. This endpoint will now also handle updates to the note's `priority`.
*   **Inclusion of `priority` in Request Body:**
    When updating a note, the `priority` field (integer value representing Low/Medium/High) should be included in the request body if it needs to be changed.

    **Example Request Body for `PUT /api/notes/{note_id}` (including priority):**
    ```json
    {
      "title": "Updated Grocery List with Priority",
      "content": "Milk, Eggs, Bread, Cheese, Apples",
      "team_id": 1,
      "due_date": "2025-01-15T23:59:59Z",
      "status_id": 2,
      "priority": 3 // e.g., High priority
    }
    ```
*   **Backend Handling:** The backend logic for `PUT /api/notes/{note_id}` should be updated to read the `priority` value from the request body and save it to the `priority` column in the `Notes` table for the specified `note_id`.
*   **Response Body:** The response body for `PUT /api/notes/{note_id}` should ideally include the updated `priority` field as well, reflecting the current state of the note.

    **Example Response Body (200 OK, reflecting updated priority):**
    ```json
    {
      "id": 123,
      "title": "Updated Grocery List with Priority",
      "content": "Milk, Eggs, Bread, Cheese, Apples",
      "created_by": 45,
      "team_id": 1,
      "due_date": "2025-01-15T23:59:59Z",
      "status_id": 2,
      "priority": 3, // Updated priority reflected
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-22T11:30:00Z"
    }
    ```

This approach integrates priority management smoothly into the existing note CRUD operations.
---
