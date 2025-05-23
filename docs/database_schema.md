# PurseCraft Database Schema

## Entity-Relationship Diagram

```mermaid
erDiagram
    User ||--o{ UserToken : "has many"
    User ||--o{ BookUser : "has many"
    Book ||--o{ BookUser : "has many"
    Book ||--o{ Category : "has many"
    Category ||--o{ Envelope : "has many"
    
    User {
        integer id PK
        citext email UK "not null"
        string hashed_password
        datetime confirmed_at
        datetime inserted_at
        datetime updated_at
    }
    
    UserToken {
        integer id PK
        binary token
        string context
        string sent_to
        integer user_id FK
        datetime inserted_at
    }
    
    Book {
        integer id PK
        uuid external_id UK
        string name
        datetime inserted_at
        datetime updated_at
    }
    
    BookUser {
        integer id PK
        enum role ":owner, :editor, :commenter"
        integer book_id FK
        integer user_id FK
        datetime inserted_at
        datetime updated_at
    }
    
    Category {
        integer id PK
        string name "not null"
        uuid external_id UK
        integer book_id FK
        datetime inserted_at
        datetime updated_at
    }
    
    Envelope {
        integer id PK
        string name "not null"
        uuid external_id UK
        integer category_id FK
        datetime inserted_at
        datetime updated_at
    }
```

## Table Descriptions

### Identity Context

#### User

The central entity for authentication and user management. Stores essential user information including email and hashed password. The system uses a confirmation mechanism for email verification.

#### UserToken

Manages authentication tokens for various purposes like session management, login links, and email change confirmations. Each token has a specific context and validity period:
- Magic link tokens: 15 minutes
- Change email tokens: 7 days
- Session tokens: 60 days

### Budgeting Context

#### Book

Represents a user's budget - the top-level container in the budgeting system. A user can have multiple books, and books can be shared between users with different permission levels.

#### BookUser

Junction table that establishes a many-to-many relationship between users and books. Implements role-based access control with three levels:
- **owner**: Highest privilege level
- **editor**: Mid-level privileges
- **commenter**: Lowest privilege level

#### Category

Groups related envelopes together within a book. Categories help organize the budget structure and provide a logical separation of budget items.

#### Envelope

Represents a specific budget allocation within a category. Envelopes are the basic units of budget management in the envelope budgeting system.
