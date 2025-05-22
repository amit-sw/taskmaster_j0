# Attachments API Endpoints

This document defines the REST API endpoints for managing file attachments associated with notes, based on the `database_schema.sql` and PRD requirements.

---

**Assumptions:**
*   User authentication and authorization are handled (e.g., a user can only manage attachments for notes they have access to).
*   The backend is responsible for file storage (e.g., on a local filesystem or cloud storage) and managing the `file_path` accordingly.
*   `{note_id}` refers to the ID of the note, and `{attachment_id}` refers to the ID of the attachment.

---

## 1. Upload an Attachment to a Note

*   **HTTP Method:** `POST`
*   **URL Path:** `/api/notes/{note_id}/attachments`
*   **Brief Description:** Uploads a file and associates it as an attachment to the specified note. This request must use `multipart/form-data`. The backend handles saving the file and creating a corresponding record in the `Attachments` table.
*   **Example Request Body/Form-Data:**
    *   Request Content-Type: `multipart/form-data`
    *   **Part 1: `file`**
        *   `Content-Disposition: form-data; name="file"; filename="datasheet.pdf"`
        *   `Content-Type: application/pdf` (or appropriate MIME type)
        *   `(file binary data)`
    *   **(Optional) Part 2: `file_name` (Text)**
        *   `Content-Disposition: form-data; name="file_name"`
        *   `user_defined_filename.pdf` (Client can suggest a filename; backend can choose to use it or the original filename from the `file` part).
*   **Example Response Body (201 Created):**
    ```json
    {
      "id": 1,
      "note_id": 123,
      "file_name": "datasheet.pdf",
      "file_path": "/uploads/notes/123/datasheet.pdf",
      "upload_date": "2024-01-20T14:30:00Z"
    }
    ```
    *(The `file_path` is illustrative; actual path depends on server-side storage strategy.)*

---

## 2. List Attachments for a Note

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/notes/{note_id}/attachments`
*   **Brief Description:** Retrieves a list of all attachments associated with the specified `note_id`.
*   **Example Request Body:** N/A
*   **Example Response Body (200 OK):**
    ```json
    [
      {
        "id": 1,
        "note_id": 123,
        "file_name": "datasheet.pdf",
        "file_path": "/uploads/notes/123/datasheet.pdf",
        "upload_date": "2024-01-20T14:30:00Z"
      },
      {
        "id": 2,
        "note_id": 123,
        "file_name": "project_image.png",
        "file_path": "/uploads/notes/123/project_image.png",
        "upload_date": "2024-01-21T10:15:00Z"
      }
    ]
    ```

---

## 3. Delete an Attachment

*   **HTTP Method:** `DELETE`
*   **URL Path:** `/api/attachments/{attachment_id}`
*   **Brief Description:** Deletes a specific attachment identified by its unique `attachment_id`. The backend is responsible for deleting the physical file from storage and removing its record from the `Attachments` table.
*   **Example Request Body:** N/A
*   **Example Response Body (Typically 204 No Content, or 200 OK with a message):**
    ```json
    // Example for 200 OK
    {
      "message": "Attachment with ID 1 successfully deleted."
    }
    ```
    *(A 204 No Content response is also common and appropriate, in which case no response body is sent.)*

---

This set of endpoints provides the necessary functionality for managing file attachments related to notes.
