# Saved Custom Filters: Backend API Endpoints and Schema

This document outlines the backend API endpoints and a database schema proposal for managing "Saved Custom Filters" for users in the Team Task Notes application.

---

## 1. Database Schema for Saved Filters

A new table is required to store the saved filter configurations for each user.

**Table Name:** `UserSavedFilters`

**Columns:**

*   `id`:
    *   Type: `INT` or `SERIAL` (PostgreSQL) / `BIGINT AUTO_INCREMENT` (MySQL)
    *   Constraints: `PRIMARY KEY`
    *   Description: Unique identifier for the saved filter.
*   `user_id`:
    *   Type: `INT` or `BIGINT`
    *   Constraints: `NOT NULL`, `FOREIGN KEY` referencing `Users(id)` (with `ON DELETE CASCADE`).
    *   Description: The ID of the user who owns this saved filter.
*   `name`:
    *   Type: `VARCHAR(255)`
    *   Constraints: `NOT NULL`
    *   Description: A user-defined name for the saved filter (e.g., "My Urgent Project X Tasks").
*   `filter_parameters`:
    *   Type: `JSON` (preferred if database supports it, e.g., PostgreSQL, MySQL 5.7+) or `TEXT`.
    *   Constraints: `NOT NULL`
    *   Description: A JSON object storing the key-value pairs of all filter criteria.
        *   Example: `{"q": "report", "status_id": 1, "priority_id": 3, "tag_ids": [5, 10], "sort_by": "due_date", "order": "asc"}`
*   `created_at`:
    *   Type: `TIMESTAMP`
    *   Constraints: `DEFAULT CURRENT_TIMESTAMP`
    *   Description: Timestamp of when the saved filter was created.
*   `updated_at`:
    *   Type: `TIMESTAMP`
    *   Constraints: `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
    *   Description: Timestamp of when the saved filter was last updated.

**Example SQL (PostgreSQL):**
```sql
CREATE TABLE UserSavedFilters (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    filter_parameters JSONB NOT NULL, -- Using JSONB for better indexing and performance in PostgreSQL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user
        FOREIGN KEY(user_id) 
        REFERENCES Users(id)
        ON DELETE CASCADE
);

-- Index for faster lookup of filters per user
CREATE INDEX idx_user_saved_filters_user_id ON UserSavedFilters(user_id);
```

---

## 2. API Endpoints for Saved Filters Management

All endpoints are assumed to be authenticated, operating on behalf of the logged-in user.

### 2.1. Create (Save) a New Filter

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/users/me/saved-filters`
*   **Brief Description:** Saves a new set of filter parameters as a named filter for the authenticated user.
*   **Example Request Body:**
    ```json
    {
      "name": "Urgent Project Reports",
      "parameters": {
        "q": "urgent report",
        "status_id": 1, // e.g., 'Open'
        "priority_id": 3, // e.g., 'High'
        "tag_ids": [10, 15], // Array of tag IDs
        "created_by_user_id": null, // Can be null or specific user ID
        "team_id": 5,
        "due_date_start": "2024-10-01",
        "due_date_end": null,
        "created_at_start": null,
        "created_at_end": null,
        "sort_by": "due_date",
        "order": "asc"
      }
    }
    ```
    *(Note: `null` values for parameters mean they are not part of this specific saved filter unless explicitly set.)*
*   **Example Response Body (201 Created):**
    ```json
    {
      "id": 1,
      "user_id": 123, // Authenticated user's ID
      "name": "Urgent Project Reports",
      "parameters": {
        "q": "urgent report",
        "status_id": 1,
        "priority_id": 3,
        "tag_ids": [10, 15],
        "team_id": 5,
        "due_date_start": "2024-10-01",
        "sort_by": "due_date",
        "order": "asc"
        // Null parameters from request might be omitted in response for brevity or included
      },
      "created_at": "2024-01-25T10:00:00Z",
      "updated_at": "2024-01-25T10:00:00Z"
    }
    ```

### 2.2. List Saved Filters

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/users/me/saved-filters`
*   **Brief Description:** Retrieves a list of all saved filters for the authenticated user.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    [
      {
        "id": 1,
        "user_id": 123,
        "name": "Urgent Project Reports",
        "parameters": {
          "q": "urgent report",
          "status_id": 1,
          "priority_id": 3,
          "tag_ids": [10, 15],
          "team_id": 5,
          "due_date_start": "2024-10-01",
          "sort_by": "due_date",
          "order": "asc"
        },
        "created_at": "2024-01-25T10:00:00Z",
        "updated_at": "2024-01-25T10:00:00Z"
      },
      {
        "id": 2,
        "user_id": 123,
        "name": "My Open Tasks - High Priority",
        "parameters": {
          "status_id": 1, // 'Open'
          "priority_id": 3, // 'High'
          "created_by_user_id": 123 // Filter by self
        },
        "created_at": "2024-01-24T15:30:00Z",
        "updated_at": "2024-01-24T15:30:00Z"
      }
    ]
    ```

### 2.3. Get a Specific Saved Filter (Optional)

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/users/me/saved-filters/{filter_id}`
*   **Brief Description:** Retrieves the details of a single saved filter by its ID. This could be useful if the UI needs to fetch details for one filter specifically, though listing all and selecting from the frontend state is often sufficient.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    {
      "id": 1,
      "user_id": 123,
      "name": "Urgent Project Reports",
      "parameters": {
        "q": "urgent report",
        "status_id": 1,
        "priority_id": 3,
        "tag_ids": [10, 15],
        "team_id": 5,
        "due_date_start": "2024-10-01",
        "sort_by": "due_date",
        "order": "asc"
      },
      "created_at": "2024-01-25T10:00:00Z",
      "updated_at": "2024-01-25T10:00:00Z"
    }
    ```
    *   **Response (404 Not Found):** If the `{filter_id}` does not exist or does not belong to the authenticated user.

### 2.4. Update a Saved Filter

*   **HTTP Method:** `PUT`
*   **URL Path:** `/api/users/me/saved-filters/{filter_id}`
*   **Brief Description:** Updates an existing saved filter. The user can change the `name` and/or the `parameters`.
*   **Example Request Body:**
    ```json
    {
      "name": "Critical Project Reports (Updated Name)", // Name can be updated
      "parameters": { // Parameters object can be completely replaced or partially updated
        "q": "critical report", // q changed
        "status_id": 1,
        "priority_id": 3,
        "tag_ids": [10, 15, 20], // tag_ids updated
        "team_id": 5,
        "due_date_start": "2024-11-01", // due_date_start changed
        "sort_by": "priority", // sort_by changed
        "order": "desc" // order changed
      }
    }
    ```
*   **Example Response Body (200 OK):**
    ```json
    {
      "id": 1, // Same filter_id
      "user_id": 123,
      "name": "Critical Project Reports (Updated Name)",
      "parameters": {
        "q": "critical report",
        "status_id": 1,
        "priority_id": 3,
        "tag_ids": [10, 15, 20],
        "team_id": 5,
        "due_date_start": "2024-11-01",
        "sort_by": "priority",
        "order": "desc"
      },
      "created_at": "2024-01-25T10:00:00Z", // Original creation date
      "updated_at": "2024-01-25T11:30:00Z"  // New update date
    }
    ```
    *   **Response (404 Not Found):** If the `{filter_id}` does not exist or does not belong to the authenticated user.

### 2.5. Delete a Saved Filter

*   **HTTP Method:** `DELETE`
*   **URL Path:** `/api/users/me/saved-filters/{filter_id}`
*   **Brief Description:** Deletes a specific saved filter for the authenticated user.
*   **Example Request Body:** N/A
*   **Example Response Body:**
    *   **204 No Content:** On successful deletion.
    *   **(Alternatively, 200 OK with a message):**
        ```json
        {
          "message": "Saved filter 'Urgent Project Reports' (ID: 1) deleted successfully."
        }
        ```
    *   **Response (404 Not Found):** If the `{filter_id}` does not exist or does not belong to the authenticated user.

---

This set of API endpoints provides comprehensive CRUD (Create, Read, Update, Delete) functionality for user-specific saved filters, enabling the UI features outlined in `search_filtering_ui.md`.
---
