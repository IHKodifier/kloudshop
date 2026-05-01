import asyncio
from logging.config import fileConfig
from sqlalchemy import pool, text
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config
from alembic import context

import os
import sys

# Add backend to sys.path to allow imports
sys.path.append(os.getcwd())

from shared.db import Base, settings
from modules.auth.models import Invitation, StaffRoleAssignment, B2BInvitation, BuyerUser, ConsumerUser
from modules.platform.models import Tenant

# this is the Alembic Config object
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Set target metadata
target_metadata = Base.metadata

# Overwrite sqlalchemy.url with the one from settings if not already set or for consistency
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def include_object(object, name, type_, reflected, compare_to):
    if type_ == "table":
        # Get target schema from context
        target_schema = context.get_x_argument(as_dictionary=True).get("schema")
        
        # If it's a platform model, it has a schema defined in __table_args__
        object_schema = getattr(object, "schema", None)
        
        if target_schema:
            # If we are migrating a specific schema, only include tables without a hardcoded schema
            # (which means they belong to the current search_path)
            # OR tables that explicitly match the target schema
            return object_schema is None or object_schema == target_schema
        else:
            # Default behavior
            return True
    return True

def do_run_migrations(connection: Connection) -> None:
    # Get the target schema from context arguments (passed via -x schema=...)
    # Or from environment variable (used when called programmatically)
    schema = context.get_x_argument(as_dictionary=True).get("schema") or os.environ.get("ALEMBIC_SCHEMA")
    
    context.configure(
        connection=connection, 
        target_metadata=target_metadata,
        version_table_schema=schema, # Store version table in the tenant schema
        include_schemas=True if schema else False,
        include_object=include_object
    )

    if schema:
        # If a schema is provided, we only want to run migrations for that schema
        connection.execute(text(f'SET search_path TO "{schema}"'))
    
    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations() -> None:
    """In this scenario we need to create an Engine
    and associate a connection with the context.
    """
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    try:
        # Check if we are already in an event loop
        asyncio.get_running_loop()
        # If we are, we should probably be running this in a thread anyway, 
        # but if we get here, we can use a helper to run the async part.
        # However, the best way when calling programmatically is to run the whole
        # alembic command in a thread.
        # For simplicity in env.py, we'll just try to use a new loop if possible,
        # but asyncio.run is best for standalone.
        asyncio.run(run_async_migrations())
    except RuntimeError:
        asyncio.run(run_async_migrations())

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
