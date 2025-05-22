# Notes API Enhancements: Full-Text Search and Filtering

This document details backend requirements for implementing "Fast, full-text search" and enhancing existing filtering capabilities for the Team Task Notes application, specifically focusing on the `GET /api/notes` endpoint.

---

## 1. Full-Text Search (FTS) Backend Strategy

Implementing fast and relevant full-text search is crucial for users to quickly find notes.

### 1.1. Potential Backend Strategies

*   **A. Database Built-in Full-Text Search:**
    *   **Description:** Most modern relational databases (e.g., PostgreSQL, MySQL, SQL Server) offer built-in FTS capabilities. For example, PostgreSQL uses `tsvector` (to store preprocessed text) and `tsquery` (to execute search queries), along with GIN or GiST indexes for performance.
    *   **Pros:**
        *   Simpler to implement and maintain initially, as it leverages existing database infrastructure.
        *   No separate service to manage.
        *   Data consistency is inherent (search index is updated transactionally with data changes).
    *   **Cons:**
        *   Can become less performant or more resource-intensive on the database server with very large datasets or extremely high query loads.
        *   Advanced search features (e.g., complex ranking, faceting, suggestions, typo tolerance) might be more limited or harder to implement compared to dedicated engines.

*   **B. Dedicated Search Engine:**
    *   **Description:** Integrating a specialized search engine like Elasticsearch, OpenSearch, Apache Solr, or Meilisearch. Data from the `Notes` table would be indexed into this engine.
    *   **Pros:**
        *   Highly scalable and optimized for search performance.
        *   Offers advanced search features, better relevance tuning, and often more sophisticated query languages.
        *   Offloads search workload from the primary database.
    *   **Cons:**
        *   Adds operational complexity (requires deploying, managing, and securing a separate service).
        *   Data synchronization between the primary database and the search engine needs to be managed (can introduce slight delays or potential inconsistencies).

### 1.2. Chosen Strategy (for this document)

For the purpose of this design document and to align with typical project evolution (starting simpler), we will assume **Database Built-in Full-Text Search (e.g., PostgreSQL's FTS)**. This allows for rapid initial development while providing good capabilities. Migration to a dedicated search engine can be considered later if performance or feature requirements outgrow the database's FTS.

### 1.3. Fields to Index for FTS

The following fields in the `Notes` table (from `database_schema.sql`) will be indexed for full-text search:
*   `title`: The title of the note.
*   `content`: The main body/content of the note.

A composite FTS index would typically be created on these two fields.

---

## 2. Augmenting `GET /api/notes` for Full-Text Search

The existing `GET /api/notes` endpoint will be augmented to support full-text search queries.

*   **New Query Parameter:** `q`
    *   **Description:** This parameter will accept a string of search terms.
    *   **Example:** `GET /api/notes?q=meeting+agenda` or `GET /api/notes?q="project kickoff"`

*   **Backend Query Conceptualization (PostgreSQL Example):**
    When the `q` parameter is provided, the backend query would incorporate a `WHERE` clause using FTS functions.
    ```sql
    -- Conceptual SQL, specific syntax depends on DB and FTS setup
    SELECT 
        id, title, content, created_by, team_id, due_date, status_id, priority, 
        created_at, updated_at, is_public_to_team
        -- Optionally, include a relevance score if supported and desired for sorting
        -- , ts_rank_cd(fts_document_vector, to_tsquery('english', :search_query)) as relevance
    FROM 
        Notes
    WHERE 
        -- Assuming 'fts_document_vector' is a precomputed tsvector column on 'title' and 'content'
        fts_document_vector @@ to_tsquery('english', :search_query) 
        -- AND other existing filter conditions (user_id, status_id, etc.)
    ORDER BY 
        -- relevance DESC, -- If ranking by relevance
        created_at DESC; -- Or other specified sort order
    ```
    *   `:search_query` would be the user-provided string from the `q` parameter, potentially processed to handle multiple terms (e.g., converting spaces to `&` or `|` operators for `to_tsquery`).
    *   The search should be case-insensitive and handle stemming (e.g., "running" matches "run").

---

## 3. Refined `GET /api/notes` Endpoint Definition

This section provides an updated and complete definition for the `GET /api/notes` endpoint, incorporating the FTS parameter and ensuring all previously discussed and UI-specified filters are included.

*   **HTTP Method:** `GET`
*   **URL Path:** `/api/notes`
*   **Brief Description:** Retrieves a list of notes accessible to the authenticated user, supporting pagination, sorting, full-text search, and various filter criteria.
*   **Key Query Parameters:**
    *   **Filtering & Search:**
        *   `q` (Optional, String): Full-text search query string. Searches across note `title` and `content`.
        *   `created_by_user_id` (Optional, Integer): Filter notes created by a specific user ID. (Matches `user_id` from UI design).
        *   `team_id` (Optional, Integer): Filter notes belonging to a specific team ID.
        *   `status_id` (Optional, Integer): Filter notes by a specific status ID.
        *   `priority_id` (Optional, Integer): Filter notes by a specific priority ID (e.g., 1 for Low, 2 for Medium, 3 for High, as per `Notes.priority` field).
        *   `tag_id` (Optional, Integer or Comma-separated Integers): Filter notes that have a specific tag ID or any of the specified tag IDs.
            *   Example: `?tag_id=5` (for one tag) or `?tag_id=5,10,15` (for multiple tags - backend logic would typically use an `IN` clause or join multiple times).
        *   `due_date_start` (Optional, String - ISO 8601 `YYYY-MM-DD`): Filter notes due on or after this date.
        *   `due_date_end` (Optional, String - ISO 8601 `YYYY-MM-DD`): Filter notes due on or before this date.
        *   `created_at_start` (Optional, String - ISO 8601 `YYYY-MM-DD`): Filter notes created on or after this date.
        *   `created_at_end` (Optional, String - ISO 8601 `YYYY-MM-DD`): Filter notes created on or before this date.
    *   **Pagination:**
        *   `page` (Optional, Integer): Page number for pagination (e.g., `1`, `2`). Defaults to `1`.
        *   `per_page` (Optional, Integer): Number of items per page (e.g., `20`, `50`). Defaults to a system value (e.g., `25`).
    *   **Sorting:**
        *   `sort_by` (Optional, String): Field to sort by (e.g., `created_at`, `due_date`, `priority`, `title`, `relevance` if FTS `q` is used). Defaults to `created_at`.
        *   `order` (Optional, String): Sort order (`asc` or `desc`). Defaults to `desc` for date fields and `relevance`, `asc` for others.

*   **Example Usage:**
    *   `GET /api/notes?q=urgent+report&status_id=1&priority_id=3&sort_by=due_date&order=asc`
    *   `GET /api/notes?tag_id=5,10&page=2&per_page=30`

*   **Example Response Body (200 OK):**
    The response structure remains consistent with the previously defined pagination and data format.
    ```json
    {
      "pagination": {
        "current_page": 1,
        "per_page": 25,
        "total_pages": 5,
        "total_items": 120
      },
      "data": [
        {
          "id": 123,
          "title": "Urgent: Q4 Financial Report Draft",
          "content_snippet": "This draft covers the preliminary financial figures for Q4...", // Full content in GET /api/notes/{id}
          "created_by": 45, // User ID of the creator
          "team_id": 1,
          "due_date": "2024-12-15T23:59:59Z",
          "status_id": 1,
          "priority": 3, // High priority
          "created_at": "2024-12-01T10:00:00Z",
          "updated_at": "2024-12-02T11:00:00Z",
          "tags": [ // Array of tag objects associated with the note
            {"id": 5, "name": "finance"},
            {"id":12, "name": "report"}
          ],
          "relevance_score": 0.85 // Optional, if FTS is used and relevance is returned
        }
        // ... more note objects
      ]
    }
    ```
    *(Note: `content_snippet` is suggested for list views to reduce payload size; full content is available via `GET /api/notes/{note_id}`. The `relevance_score` is optional and depends on FTS implementation.)*

This refined API definition for `GET /api/notes` provides a comprehensive way to search and filter notes, accommodating the features outlined in the PRD and UI designs.
---
