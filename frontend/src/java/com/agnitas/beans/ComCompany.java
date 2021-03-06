/*

    Copyright (C) 2019 AGNITAS AG (https://www.agnitas.org)

    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

*/

package com.agnitas.beans;

import java.util.Date;

import org.agnitas.beans.Company;

public interface ComCompany extends Company {

	int getExpireStat();
	
	void setExpireStat(int expireStat);
	
	int getExpireOnePixel();
	
	void setExpireOnePixel(int expireOnePixel);
	
	int getExpireUpload();
	
	void setExpireUpload(int expireUpload);
	
	int getStatAdmin();
	
	void setStatAdmin(int statAdmin);
	
	int getExpireCookie();
	
	void setExpireCookie(int expireCookie);
	
	String getSecretKey();
	
	void setSecretKey(String secretKey);
	
	Date getCreationDate();
	
	void setCreationDate(Date creationDate);
	
	boolean isAutoMailingReportSendActivated();
	
	void setAutoMailingReportSendActivated(boolean autoMailingReportSendActivated);

	int getBusiness();

	void setBusiness(int business);

    int getSector();

	void setSector(int sector);
	
	void setExpireRecipient(int expireRecipient);
	
	int getExpireRecipient();
	
	void setSalutationExtended(int salutationExtended);
	
	int getSalutationExtended();

	void setEnabledUIDVersion( int enabledUIDVersion);
	
	int getEnabledUIDVersion();
	
	int getMaxAdminMails();

	void setMaxAdminMails(int maxAdminMails);
	
	void setExportNotifyAdmin(int exportNotifyAdmin);
	
	int getExportNotifyAdmin();
	
	int getParentCompanyId();
	
	void setParentCompanyId(int companyId);

	int getExpireSuccess();

	void setExpireSuccess(int maximumAgeInDays);

	int getExpireBounce();

	void setExpireBounce(int expireBounce);
	
	int getMaxFields();

	void setMaxFields(int maxFields);
	
	String getLocaleTimezone();

	void setLocaleTimezone(String localeTimezone);
	
	String getLocaleLanguage();

	void setLocaleLanguage(String localeLanguage);

	boolean isForceSending();

	void setForceSending(boolean forceSending);
	
	String getContactTech();

	void setContactTech(String contactTech);
}
