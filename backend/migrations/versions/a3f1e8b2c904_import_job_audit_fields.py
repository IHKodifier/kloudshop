"""import_job_audit_fields

Revision ID: a3f1e8b2c904
Revises: 0cc09dfa3754
Create Date: 2026-06-09 07:10:00.000000

Adds audit trail, file metadata, conflict strategy, per-strategy row counters,
and no_stock_log to the import_jobs table.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3f1e8b2c904'
down_revision: Union[str, None] = '0cc09dfa3754'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add audit trail columns
    op.add_column('import_jobs', sa.Column('initiated_by', sa.String(), nullable=True))
    op.add_column('import_jobs', sa.Column('processing_started_at', sa.DateTime(), nullable=True))
    op.add_column('import_jobs', sa.Column('processing_completed_at', sa.DateTime(), nullable=True))

    # Add file metadata columns
    op.add_column('import_jobs', sa.Column('source_filename', sa.String(length=512), nullable=True))
    op.add_column('import_jobs', sa.Column('source_filesize_bytes', sa.Integer(), nullable=True, server_default='0'))

    # Add conflict strategy column
    op.add_column('import_jobs', sa.Column('conflict_strategy', sa.String(length=16), nullable=True))

    # Add per-strategy row counters
    op.add_column('import_jobs', sa.Column('rows_skipped', sa.Integer(), nullable=True, server_default='0'))
    op.add_column('import_jobs', sa.Column('rows_overwritten', sa.Integer(), nullable=True, server_default='0'))
    op.add_column('import_jobs', sa.Column('rows_custom_sku', sa.Integer(), nullable=True, server_default='0'))

    # Add no_stock_log
    op.add_column('import_jobs', sa.Column('no_stock_log', sa.JSON(), nullable=True))


def downgrade() -> None:
    op.drop_column('import_jobs', 'no_stock_log')
    op.drop_column('import_jobs', 'rows_custom_sku')
    op.drop_column('import_jobs', 'rows_overwritten')
    op.drop_column('import_jobs', 'rows_skipped')
    op.drop_column('import_jobs', 'conflict_strategy')
    op.drop_column('import_jobs', 'source_filesize_bytes')
    op.drop_column('import_jobs', 'source_filename')
    op.drop_column('import_jobs', 'processing_completed_at')
    op.drop_column('import_jobs', 'processing_started_at')
    op.drop_column('import_jobs', 'initiated_by')
