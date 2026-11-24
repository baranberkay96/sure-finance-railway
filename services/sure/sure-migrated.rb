# Exit 0 when the database schema is current, 1 otherwise (or when the
# database is not reachable yet). Used by the worker before Sidekiq starts.
pool = ActiveRecord::Base.connection_pool
context = pool.respond_to?(:migration_context) ? pool.migration_context : ActiveRecord::Base.connection.migration_context
exit(context.needs_migration? ? 1 : 0)
