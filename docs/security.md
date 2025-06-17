# Security

This document outlines security practices and considerations for contributors working on PurseCraft.

## Data Encryption

PurseCraft uses server-side encryption for personally identifiable information (PII) to protect sensitive user data at rest.

### Encrypted Fields

We use [Cloak](https://github.com/danielberkompas/cloak) for field-level encryption:

- **User emails**: Encrypted to protect user identity
- **User-defined names**: Book names, category names, and envelope names are encrypted as they may contain sensitive personal information

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
- Hash fields enable querying but reveal when identical values exist
- Financial calculations will require special handling when implemented

## Environment Variables

Required encryption environment variables:

- `PURSECRAFT_CLOAK_KEY`: AES encryption key (base64-encoded)
- `PURSECRAFT_HMAC_SECRET`: HMAC signing key (base64-encoded)

## Best Practices

- Never log decrypted sensitive data
- Use existing encryption utilities rather than implementing custom encryption
- Follow established patterns when adding new encrypted fields
- Ensure migrations handle encrypted data properly