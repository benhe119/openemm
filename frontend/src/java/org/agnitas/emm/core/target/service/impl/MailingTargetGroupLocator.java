/*

    Copyright (C) 2019 AGNITAS AG (https://www.agnitas.org)

    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

*/

package org.agnitas.emm.core.target.service.impl;

import org.agnitas.emm.core.target.service.TargetGroupLocator;
import org.springframework.beans.factory.annotation.Required;

import com.agnitas.dao.ComMailingDao;

/**
 * Searches for target groups in mailings (Does not include graphic components, 
 * content block, etc.)
 * 
 * If a target group is only used in sent mailings, target group can be marked as deleted.
 * If the target group is used in no mailing, it can be deleted from DB completely
 */
public class MailingTargetGroupLocator implements TargetGroupLocator {

	private ComMailingDao mailingDao;

	@Override
	public TargetDeleteStatus isTargetGroupCanBeDeleted(int companyID, int targetGroupID) {
		if(!mailingDao.existMailingsDependsOnTargetGroup(companyID, targetGroupID)){
			return TargetDeleteStatus.CAN_BE_FULLY_DELETED_FROM_DB;
		}
		if(mailingDao.existsNotSentMailingsDependsOnTargetGroup(companyID, targetGroupID)){
			return TargetDeleteStatus.CANT_BE_DELETED;
		}
		return TargetDeleteStatus.CAN_BE_MARKED_AS_DELETED;
	}

	@Required
	public void setMailingDao(ComMailingDao mailingDao) {
		this.mailingDao = mailingDao;
	}

}
