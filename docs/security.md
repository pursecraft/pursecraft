# Security

This document outlines security practices and considerations for contributors working on PurseCraft.

## Data Encryption

PurseCraft uses server-side encryption for personally identifiable information (PII) to protect sensitive user data at rest.

### Encrypted Fields

We use [Cloak](https://github.com/danielberkompas/cloak) for field-level encryption:

- **User emails**: Encrypted to protect user identity and enable secure authentication
- **User-defined names**: Workspace names, category names, and envelope names are encrypted as they may contain sensitive personal information

#### Current Encryption Status
- **User emails**: Fully implemented using dual-column encryption pattern
- **User tokens**: Implemented with encrypted sent_to field for magic link security
- **Category names**: Fully implemented using dual-column encryption pattern (high-risk PII)
- **Envelope names**: Fully implemented using dual-column encryption pattern (high-risk PII)
- **Workspace names**: Fully implemented using dual-column encryption pattern (medium-risk PII)
- **Financial amounts**: Future consideration with special handling required for calculations

### Implementation Pattern

For searchable encrypted fields, we use a dual-column approach:

```elixir
schema "users" do
  field :email, PurseCraft.Utilities.EncryptedBinary          # Encrypted storage
  field :email_hash, PurseCraft.Utilities.HashedHMAC         # Searchable hash
end
```

- **Encrypted column**: Stores the actual data securely using AES-GCM encryption
- **Hash column**: Enables database queries using HMAC-based deterministic hashing

### Key Management

- Environment variables store base64-encoded encryption keys
- Separate keys for encryption (`PURSECRAFT_CLOAK_KEY`) and hashing (`PURSECRAFT_HMAC_SECRET`)
- Keys should be generated using: `32 |> :crypto.strong_rand_bytes() |> Base.encode64()`

### Testing Encrypted Fields

When writing tests for features with encrypted fields:

- Business logic tests work transparently - Cloak handles encryption/decryption automatically
- No special test helpers needed for most cases
- Only test encryption functionality itself when adding new encrypted field types

### Security Considerations

- Encrypted data appears as random bytes in the database
- Hash fields enable querying but reveal when identical values exist (pattern analysis risk)
- Encrypted field comparisons must happen in application layer, not database layer
- Case-insensitive searches require normalization before hashing
- Financial calculations will require special handling when implemented

### Important Implementation Notes

- **Database Queries**: Encrypted binary fields cannot be compared directly in SQL queries due to PostgreSQL type constraints
- **Token Verification**: Magic link token verification now happens in application layer after query execution
- **Case Sensitivity**: Email searches are case-insensitive through lowercase normalization before hashing
- **Factory Testing**: Test factories must use changesets to properly populate encrypted hash fields

## Environment Variables

Required encryption environment variables:

- `PURSECRAFT_CLOAK_KEY`: AES encryption key (base64-encoded)
- `PURSECRAFT_HMAC_SECRET`: HMAC signing key (base64-encoded)

## Best Practices

- Never log decrypted sensitive data
- Use existing encryption utilities rather than implementing custom encryption
- Follow established patterns when adding new encrypted fields
- Ensure migrations handle encrypted data properly
