- To add a new migration create a new swift file at location. 
  `OstWalletSdk>Database>Migrations>DBMigration`
- Following is the naming convention for migration files.
  `OstMigration_<migration_version>.swift`
- The  `migration_version` must be incremental.
- The largest `migration_version` must be updated in file `OstMigrationManager` for `verisonInt` variable.
