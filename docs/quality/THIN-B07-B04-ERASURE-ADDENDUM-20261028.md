# B07/B04 necessary original account-erasure linkage

Original accepted UI/source baseline 566c88f6b3698648a6f4facbdc01b86c5ecf42bb and contract SHA256 23B6413B17C57F2E9ABE7E03D16F916C32C27908E65BED900663E02D7F67E382 remain unchanged.

Demonstrated lifecycle defect: original EraseMoolSocialUser tombstones AppUser and erases Profile data/receipts, retaining the account row for historical orders/invoices. Therefore required-reference cascade deletion alone does not remove the newly introduced AI preparation result, technical usage reservation and Profile-operation linkage rows. These rows can contain private prepared name/address data or owned task metadata.

Add only the single existing owner dataconnect/provider/youtube.gql. Modify only EraseMoolSocialUser to delete the three new account-owned AI record sets and retain its existing account tombstone/field erasure, within one transaction. Existing caller and parameters stay unchanged. No change to Social/provider authentication, registration, publication, data-retention policy, billing/settlement, admin UI or commerce records.

Reuse already-admitted assistant SQL tests for parameter-bound deletion, tombstone preservation, rollback and access rejection. The isolated compiler already accepts the exact generated deleteMany fields and transaction directive. SDK/deployed database qualification remains held; do not activate service flags.

Authority: founder explicitly approved the exact combined contract/33-file admission, then requested: "keep this standing authorisation or approval if needed while i am away". This is a necessary bounded admission adjustment under that standing approval, not a claim that the original 33-file list included this owner. Permit one additional seven-file metadata-only admission amendment for this exact discovered defect; source feature commits/push remain excluded. Preserve original initial admission history and all qualification limits.
