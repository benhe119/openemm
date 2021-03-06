/*

    Copyright (C) 2019 AGNITAS AG (https://www.agnitas.org)

    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

*/

package com.agnitas.emm.core.dashboard.service;

import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.agnitas.beans.impl.PaginatedListImpl;
import org.agnitas.emm.core.velocity.VelocityCheck;

import net.sf.json.JSONObject;

public interface DashboardService {

    PaginatedListImpl<Map<String, Object>> getMailings(int companyId, String sort, String direction, int rownums);

    List<Map<String, Object>> getLastSentWorldMailings(@VelocityCheck int companyID, int rownums);

    JSONObject getStatisticsInfo(int mailingId, Locale locale, int companyId) throws Exception;
}
