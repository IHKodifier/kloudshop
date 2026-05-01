"""Initial tenant schema

Revision ID: 8af18657ab30
Revises: 6c3b5d2868d3
Create Date: 2026-04-21 06:56:55.068821

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '8af18657ab30'
down_revision: Union[str, None] = '6c3b5d2868d3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Create tenant-specific tables
    op.create_table('b2b_invitations',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('tenant_id', sa.String(), nullable=False),
        sa.Column('buyer_account_id', sa.String(), nullable=True),
        sa.Column('token', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('accepted_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_b2b_invitations_email'), 'b2b_invitations', ['email'], unique=False)
    op.create_index(op.f('ix_b2b_invitations_tenant_id'), 'b2b_invitations', ['tenant_id'], unique=False)
    op.create_index(op.f('ix_b2b_invitations_token'), 'b2b_invitations', ['token'], unique=True)

    op.create_table('buyer_users',
        sa.Column('uid', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('tenant_id', sa.String(), nullable=False),
        sa.Column('buyer_account_id', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('uid')
    )
    op.create_index(op.f('ix_buyer_users_email'), 'buyer_users', ['email'], unique=True)
    op.create_index(op.f('ix_buyer_users_tenant_id'), 'buyer_users', ['tenant_id'], unique=False)

    op.create_table('consumer_users',
        sa.Column('uid', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('tenant_id', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('uid')
    )
    op.create_index(op.f('ix_consumer_users_email'), 'consumer_users', ['email'], unique=True)
    op.create_index(op.f('ix_consumer_users_tenant_id'), 'consumer_users', ['tenant_id'], unique=False)

    op.create_table('invitations',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('tenant_id', sa.String(), nullable=False),
        sa.Column('roles', sa.JSON(), nullable=False),
        sa.Column('invited_by', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('accepted_at', sa.DateTime(), nullable=True),
        sa.Column('is_cancelled', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_invitations_email'), 'invitations', ['email'], unique=False)
    op.create_index(op.f('ix_invitations_tenant_id'), 'invitations', ['tenant_id'], unique=False)

    op.create_table('staff_role_assignments',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('staff_user_id', sa.String(), nullable=False),
        sa.Column('tenant_id', sa.String(), nullable=False),
        sa.Column('roles', sa.JSON(), nullable=False),
        sa.Column('is_owner', sa.Boolean(), nullable=True),
        sa.Column('invited_at', sa.DateTime(), nullable=True),
        sa.Column('accepted_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_staff_role_assignments_tenant_id'), 'staff_role_assignments', ['tenant_id'], unique=False)

    op.create_table('staff_users',
        sa.Column('uid', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('display_name', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('uid')
    )
    op.create_index(op.f('ix_staff_users_email'), 'staff_users', ['email'], unique=True)

def downgrade() -> None:
    op.drop_index(op.f('ix_staff_users_email'), table_name='staff_users')
    op.drop_table('staff_users')
    op.drop_index(op.f('ix_staff_role_assignments_tenant_id'), table_name='staff_role_assignments')
    op.drop_table('staff_role_assignments')
    op.drop_index(op.f('ix_invitations_tenant_id'), table_name='invitations')
    op.drop_index(op.f('ix_invitations_email'), table_name='invitations')
    # Use explicit schema for dropping if needed, but here they are in current search_path
    op.drop_table('invitations')
    op.drop_index(op.f('ix_consumer_users_tenant_id'), table_name='consumer_users')
    op.drop_index(op.f('ix_consumer_users_email'), table_name='consumer_users')
    op.drop_table('consumer_users')
    op.drop_index(op.f('ix_buyer_users_tenant_id'), table_name='buyer_users')
    op.drop_index(op.f('ix_buyer_users_email'), table_name='buyer_users')
    op.drop_table('buyer_users')
    op.drop_index(op.f('ix_b2b_invitations_token'), table_name='b2b_invitations')
    op.drop_index(op.f('ix_b2b_invitations_tenant_id'), table_name='b2b_invitations')
    op.drop_index(op.f('ix_b2b_invitations_email'), table_name='b2b_invitations')
    op.drop_table('b2b_invitations')
