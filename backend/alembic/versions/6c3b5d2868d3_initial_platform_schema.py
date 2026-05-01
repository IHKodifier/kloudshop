"""Initial platform schema

Revision ID: 6c3b5d2868d3
Revises: 
Create Date: 2026-04-21 06:53:39.635448

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '6c3b5d2868d3'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Create the tenants table in the platform schema
    op.create_table('tenants',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('gcp_project_id', sa.String(), nullable=True),
        sa.Column('gcp_bucket_name', sa.String(), nullable=True),
        sa.Column('config', sa.JSON(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        schema='kloudshop_platform'
    )

def downgrade() -> None:
    op.drop_table('tenants', schema='kloudshop_platform')
