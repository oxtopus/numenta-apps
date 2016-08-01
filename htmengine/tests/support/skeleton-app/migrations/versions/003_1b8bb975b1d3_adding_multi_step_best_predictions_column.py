# ----------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
# Numenta, Inc. a separate commercial license for this software code, the
# following terms and conditions apply:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# http://numenta.org/licenses/
# ----------------------------------------------------------------------

"""adding multi_step_best_predictions column

Revision ID: 1b8bb975b1d3
Revises: 1d2eddc43366
Create Date: 2016-07-15 14:56:55.523912
"""

from alembic import op
import sqlalchemy as sa


# Revision identifiers, used by Alembic. Do not change.
revision = '1b8bb975b1d3'
down_revision = '872a895b8e8'



def upgrade():
  """ Adds column 'multi_step_best_predictions' to metric_data table """
  op.add_column('metric_data',
                sa.Column('multi_step_best_predictions', sa.TEXT(),
                          nullable=True))
  ### end Alembic commands ###


def downgrade():
  raise NotImplementedError("Rollback is not supported.")
