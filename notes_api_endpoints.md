# Notes API Endpoints (CRUD)

This document defines the basic REST API endpoints for Create, Read, Update, and Delete (CRUD) operations on "Notes".

---

**Assumptions:**
*   User authentication is handled, and a `user_id` is available to associate with note creation.
*   `status_id` refers to an ID from a `Status` table (e.g., 1 for 'open', 2 for 'in progress').
*   Timestamps (`created_at`, `updated_at`) are managed by the backend.

---

## 1. Create a new Note

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/notes`
*   **Brief Description:** Creates a new note. The `created_by` field is automatically populated based on the authenticated user. `status_id` would typically default to an 'open' status or be provided.
*   **Example Request Body:**
    ```json
    {
      "title": "Grocery List",
      "content": "Milk, Eggs, Bread, Cheese",
      "team_id": 1,
      "due_date": "2024-12-31T23:59:59Z",
      "status_id": 1
    }
    ```
*   **Example Response Body (201 Created):**
    ```json
    {
      "id": 123,
      "title": "Grocery List",
      "content": "Milk, Eggs, Bread, Cheese",
      "created_by": 45,
      "team_id": 1,
      "due_date": "2024-12-31T23:59:59Z",
      "status_id": 1,
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
    ```

---

## 2. Get all Notes

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/notes`
*   **Brief Description:** Retrieves a list of notes accessible to the authenticated user. Query parameters can be used for filtering (e.g., `?team_id=1`, `?status_id=2`, `?user_id=45`).
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    [
      {
        "id": 123,
        "title": "Grocery List",
        "created_by": 45,
        "team_id": 1,
        "due_date": "2024-12-31T23:59:59Z",
        "status_id": 1,
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z"
      },
      {
        "id": 124,
        "title": "Meeting Agenda",
        "created_by": 45,
        "team_id": null,
        "due_date": null,
        "status_id": 2,
        "created_at": "2024-01-16T14:30:00Z",
        "updated_at": "2024-01-16T15:00:00Z"
      }
    ]
    ```
    *(Note: `content` field might be omitted or summarized in list views for brevity).*

---

## 3. Get a specific Note

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/notes/{note_id}`
*   **Brief Description:** Retrieves a single note by its unique ID.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    {
      "id": 123,
      "title": "Grocery List",
      "content": "Milk, Eggs, Bread, Cheese",
      "created_by": 45,
      "team_id": 1,
      "due_date": "2024-12-31T23:59:59Z",
      "status_id": 1,
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
    ```

---

## 4. Update a specific Note

*   **HTTP Method:** `PUT` (for full update) or `PATCH` (for partial update)
*   **URL Path:** `/api/notes/{note_id}`
*   **Brief Description:** Updates an existing note. `created_by` should not be updatable.
*   **Example Request Body (Using `PUT` for full update, all updatable fields should be provided):**
    ```json
    {
      "title": "Updated Grocery List",
      "content": "Milk, Eggs, Bread, Cheese, Apples",
      "team_id": 1,
      "due_date": "2025-01-15T23:59:59Z",
      "status_id": 2
    }
    ```
*   **Example Response Body (200 OK):**
    ```json
    {
      "id": 123,
      "title": "Updated Grocery List",
      "content": "Milk, Eggs, Bread, Cheese, Apples",
      "created_by": 45, // Remains unchanged
      "team_id": 1,
      "due_date": "2025-01-15T23:59:59Z",
      "status_id": 2,
      "created_at": "2024-01-15T10:00:00Z", // Remains unchanged
      "updated_at": "2024-01-17T11:00:00Z"  // Timestamp updated
    }
    ```

---

## 5. Delete a specific Note

*   **HTTP Method:** `DELETE`
*   **URL Path:** `/api/notes/{note_id}`
*   **Brief Description:** Deletes a note by its unique ID.
*   **Example Request Body:** N/A
*   **Example Response Body (Typically 204 No Content, or 200 OK with a message):**
    ```json
    // Example for 200 OK
    {
      "message": "Note with ID 123 deleted successfully."
    }
    ```
    *(For 204 No Content, there is no response body).*
