# Admin Dashboard: Backend API Endpoints

This document outlines the backend API endpoints required for the Admin Dashboard in Team Task Notes. These endpoints are designed to provide administrators with team-wide insights, data filtering capabilities, and export functionalities.

**Assumptions:**
*   The user making these requests is authenticated and has administrative privileges for the team(s) they are managing.
*   Authorization checks are performed by the backend to ensure the requesting admin has access to the requested team's data.
*   For simplicity, if an admin manages multiple teams, a `team_id` parameter might be required or inferred from their primary team. The examples below often assume a context of a single team being administered unless otherwise specified.

---

## 1. Team-wide Notes List (with Filtering)

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/admin/notes`
*   **Brief Description:** Retrieves a paginated list of notes across the entire team (or specific team if admin manages multiple and `team_id` is provided). Supports various filtering options.
*   **Key Query Parameters:**
    *   `team_id` (Optional): ID of the team to fetch notes for. If not provided, might default to admin's primary team or require explicit selection if admin manages multiple.
    *   `created_by_user_id` (Optional): Filter notes created by a specific user ID.
    *   `status_id` (Optional): Filter notes by a specific status ID.
    *   `tag_id` (Optional): Filter notes that have a specific tag ID. Can potentially accept multiple IDs (e.g., `tag_id=1,2,3`).
    *   `created_at_start` (Optional): Filter notes created on or after this date (ISO 8601 format, e.g., `YYYY-MM-DD`).
    *   `created_at_end` (Optional): Filter notes created on or before this date (ISO 8601 format).
    *   `due_date_start` (Optional): Filter notes due on or after this date.
    *   `due_date_end` (Optional): Filter notes due on or before this date.
    *   `page` (Optional): For pagination, the page number to retrieve (e.g., `1`, `2`). Defaults to `1`.
    *   `per_page` (Optional): For pagination, the number of items per page (e.g., `20`, `50`). Defaults to a system-defined value (e.g., `25`).
    *   `sort_by` (Optional): Field to sort by (e.g., `created_at`, `due_date`, `title`).
    *   `order` (Optional): Sort order (`asc` or `desc`). Defaults to `desc` for date fields.
*   **Example Response Body (200 OK):**
    ```json
    {
      "pagination": {
        "current_page": 1,
        "per_page": 25,
        "total_pages": 10,
        "total_items": 250
      },
      "data": [
        {
          "id": 101,
          "title": "Project Alpha Kickoff Document",
          "created_by": { // User object for creator
            "user_id": 5,
            "name": "Alice Wonderland",
            "email": "alice@example.com"
          },
          "team_id": 1,
          "status_id": 2, // Mapped to status name on frontend
          "status_name": "In Progress", // Example, could be joined or mapped
          "priority": 2, // Medium
          "due_date": "2024-10-15T23:59:59Z",
          "created_at": "2024-09-01T10:00:00Z",
          "updated_at": "2024-09-05T14:30:00Z",
          "tags": [
            {"id": 1, "name": "ProjectAlpha"},
            {"id": 7, "name": "Planning"}
          ],
          "is_public_to_team": true
        },
        // ... more note objects
      ]
    }
    ```

---

## 2. Team Participation Summaries

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/admin/stats/summary`
*   **Brief Description:** Provides aggregated statistics for team participation and note status.
*   **Key Query Parameters:**
    *   `team_id` (Optional): ID of the team for which to generate stats. Defaults or required as per admin context.
    *   `date_range_start` (Optional): Start date for filtering data used in summaries (e.g., `created_at` or `updated_at`).
    *   `date_range_end` (Optional): End date for filtering data.
*   **Example Response Body (200 OK):**
    ```json
    {
      "team_id": 1,
      "team_name": "Marketing Team",
      "summary_period": { // Reflects date_range_start/end if provided, else "all_time"
        "start": "2024-01-01T00:00:00Z",
        "end": "2024-12-31T23:59:59Z"
      },
      "overall_stats": {
        "total_notes_created": 1250,
        "total_notes_completed": 800, // Based on 'completed' status ID
        "total_notes_overdue": 50,    // Calculated: due_date < now AND status != 'completed'
        "active_users_count": 15      // Number of users who created/interacted in period
      },
      "status_breakdown": [ // Array of status objects with counts
        {"status_id": 1, "status_name": "Open", "count": 300},
        {"status_id": 2, "status_name": "In Progress", "count": 100},
        {"status_id": 3, "status_name": "Completed", "count": 800},
        {"status_id": 4, "status_name": "Archived", "count": 50}
      ],
      "user_participation": [
        {
          "user_id": 5,
          "name": "Alice Wonderland",
          "email": "alice@example.com",
          "notes_created": 150,
          "notes_completed": 100,
          "notes_overdue": 5 // Notes created by this user that are overdue
        },
        {
          "user_id": 8,
          "name": "Bob The Builder",
          "email": "bob@example.com",
          "notes_created": 120,
          "notes_completed": 90,
          "notes_overdue": 3
        }
        // ... more user summary objects
      ]
    }
    ```
    *(Note: `status_name` can be joined from the `Status` table. Overdue calculation is dynamic based on current time).*

---

## 3. CSV Export Trigger

*   **HTTP Method:** `GET` (or `POST` if parameters are complex and exceed URL length limits, though `GET` is common for idempotent exports)
*   **URL Path:** `/api/admin/notes/export/csv`
*   **Brief Description:** Triggers the generation and download of a CSV file containing notes data. The CSV can be filtered using the same parameters as the team-wide notes list.
*   **Key Query Parameters:**
    *   Same as `/api/admin/notes` (e.g., `team_id`, `created_by_user_id`, `status_id`, `tag_id`, date ranges). This allows exporting a filtered view.
*   **Response Type:**
    *   `Content-Type: text/csv`
    *   `Content-Disposition: attachment; filename="team_task_notes_export_[timestamp].csv"`
    *   The response body will be the raw CSV data.

*   **Example CSV Structure (Conceptual):**
    ```csv
    Note ID,Title,Created By User ID,Created By Name,Created At,Due Date,Status,Priority,Team ID,Team Name,Tags,Is Public to Team,Content Snippet
    101,"Project Alpha Kickoff",5,"Alice Wonderland","2024-09-01T10:00:00Z","2024-10-15T23:59:59Z","In Progress",2,1,"Marketing Team","ProjectAlpha;Planning",TRUE,"Initial draft of the project kickoff document..."
    102,"Q3 Marketing Plan",8,"Bob The Builder","2024-08-15T11:30:00Z","2024-09-30T23:59:59Z","Open",3,1,"Marketing Team","Strategy;Q3",FALSE,"Outline for Q3 marketing initiatives..."
    ```
    *(The exact columns and their order should be defined. Consider including a content snippet rather than full content for manageability, or offer options.)*

---

These endpoints provide a solid foundation for the data needs of the Admin Dashboard. Backend logic will need to efficiently query and aggregate data, especially for the summary statistics. For CSV export, generating the file on-the-fly might be suitable for smaller datasets, while for larger datasets, an asynchronous job that emails a download link or notifies the admin when ready might be a better approach (though this is more complex than a direct download). The current design assumes direct download.Okay, I have created the file `admin_dashboard_api.md` with the backend API endpoint designs for the Admin Dashboard.

The file includes three main sections:

1.  **Team-wide Notes List (with Filtering):**
    *   **Endpoint:** `GET /api/admin/notes`
    *   **Description:** Retrieves a paginated list of notes for a team, with extensive filtering options (by user, status, tags, date ranges for creation and due dates) and sorting.
    *   **Response:** JSON object with pagination info and an array of note objects, including creator details and tags.

2.  **Team Participation Summaries:**
    *   **Endpoint:** `GET /api/admin/stats/summary`
    *   **Description:** Provides aggregated statistics for a team, including overall note counts (created, completed, overdue), status breakdowns, and individual user participation summaries (notes created, completed, overdue by user). Supports optional date range filtering.
    *   **Response:** JSON object containing overall stats, status breakdown, and user participation arrays.

3.  **CSV Export Trigger:**
    *   **Endpoint:** `GET /api/admin/notes/export/csv` (or `POST` for complex filters)
    *   **Description:** Triggers the generation and download of a CSV file of notes, using the same filter parameters as the team-wide notes list endpoint.
    *   **Response Type:** `text/csv` with appropriate `Content-Disposition` header for download. Includes a conceptual CSV structure.

All endpoints assume the user is an authenticated and authorized admin.
