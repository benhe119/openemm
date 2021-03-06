/*

    Copyright (C) 2019 AGNITAS AG (https://www.agnitas.org)

    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

*/

-- MySQL 5.6, 5.7
-- MariaDB 10.1, 10.2, 10.3
--
-- Database: emm
--
-- MySQL 5.7: Use following option in your my.cnf in the [mysqld] section:
--   explicit_defaults_for_timestamp = 1

CREATE TABLE agn_dbversioninfo_tbl (
	version_number             VARCHAR(15) COMMENT '(EMM-) version of update - script',
	updating_user              VARCHAR(64) COMMENT 'executing (DB-) user',
	update_timestamp           DATE COMMENT 'execution timestamp',
	PRIMARY KEY (version_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores already executed (SQL-) updates to auto-check consistence of data structure';

CREATE TABLE auto_optimization_tbl (
	company_id                 INT(11) DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	campaign_id                INT(11) DEFAULT 0 COMMENT 'ID of the mailing-archive',
	description                VARCHAR(1000) DEFAULT '' COMMENT 'description on auto-optimization',
	shortname                  VARCHAR(100) DEFAULT '' COMMENT 'auto-optimization name',
	eval_type                  INT(11) DEFAULT 0 COMMENT 'threshold - evaluation type: 1 = open rate, 2 = clicks, 3 = sales volume',
	group1_id                  INT(11) DEFAULT 0 COMMENT '1st basic-mailing-ID',
	group2_id                  INT(11) DEFAULT 0 COMMENT '2nd basic-mailing-ID',
	group3_id                  INT(11) DEFAULT 0 COMMENT '3rd basic-mailing-ID',
	group4_id                  INT(11) DEFAULT 0 COMMENT '4th basic-mailing-ID',
	group5_id                  INT(11) DEFAULT 0 COMMENT '5th basic-mailing-ID',
	mailinglist_id             INT(11) DEFAULT 0 COMMENT 'ID of related mailinglist',
	optimization_id            INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use AUTO_OPTIMIZATION_TBL_SEQ',
	result_mailing_id          INT(11) DEFAULT 0 COMMENT 'winner-mailing ID (from GROUP1_ID ... GROUP5_ID)',
	result_senddate            TIMESTAMP NULL COMMENT 'winner- mailing send date',
	send_delay                 INT(11) DEFAULT 0 COMMENT 'legacy EMM-4955',
	split_type                 VARCHAR(100) NOT NULL DEFAULT '' COMMENT 'defines split-parts for basic / final mailings',
	status                     INT(11) DEFAULT 0 COMMENT 'auto-optimization state: 0=not started yet, 1=test-sending, 2= evaluation in progress, 3 = done, 4 = scheduled',
	target_id                  INT(11) DEFAULT 0 COMMENT 'legacy',
	creation_date              TIMESTAMP NULL COMMENT 'auto-optimization creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'auto-optimization last change date',
	threshold                  INT(11) COMMENT 'threshold - value, reaching threshold value before end of evaluation periode triggers sending',
	double_check               INT(11) COMMENT 'use double-check: 0 = no, 1 = yes',
	target_expression          VARCHAR(300) COMMENT 'combination of related targetIDs',
	target_mode                INT(11) DEFAULT 1 COMMENT 'combination_tye of target_groups: 0 = OR, 1 = AND',
	final_mailing_id           INT(11) COMMENT 'final-mailing_id (auto-generated copy of the winner-mailing)',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT 'deleted? 0 = no, 1 = yes',
	test_senddate              TIMESTAMP NULL COMMENT 'test scheduled date',
	test_run                   INT DEFAULT 0 NOT NULL COMMENT 'test-run - mode: 0 = no, 1 = yes',
	workflow_id                INT(11) DEFAULT 0 NOT NULL COMMENT 'references workflow',
	PRIMARY KEY (optimization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'processing table for auto-optimization';

CREATE TABLE workflow_def_mailing_tbl (
	id                         INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use workflow_def_mailing_tbl_seq',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	reaction_id                INT(11) NOT NULL COMMENT 'reaction - ID (workflow_reaction_tbl)',
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'customer who has to receive deferred mailing - ID (customer_<cid>_tbl)',
	mailing_id                 INT(11) NOT NULL COMMENT 'mailing - ID (mailing_tbl)',
	send_date                  TIMESTAMP NOT NULL COMMENT 'calculated date when deferred mailing should be sent',
	sent                       INT(1) NOT NULL COMMENT 'whether or not deferred mailing is already sent, 1 = yes, 0 = no',
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores deferred mailings to be triggered by action-based workflow when specified date is reached, deprecated and must be removed from java code first';

CREATE TABLE workflow_dependency_tbl (
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	workflow_id                INT(11) NOT NULL COMMENT 'workflow - ID (workflow_tbl)',
	type                       INT(11) NOT NULL COMMENT 'type of entity that a workflow depends on',
	entity_id                  INT(11) NOT NULL COMMENT 'identifier of an entity that a workflow depends on',
	entity_name                VARCHAR(200) COMMENT 'name of an entity that a workflow depends on'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'lists the entities (mailings, archives, profile fields, etc) that a workflow depends on';

CREATE TABLE workflow_reaction_cust_tbl (
	customer_id                INTEGER UNSIGNED,
	PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'a temporary storage for filtering customers of action-based workflow, deprecated and must be removed from java code first';

CREATE TABLE workflow_reaction_decl_tbl (
	step_id                    INT(11) NOT NULL COMMENT 'identifies a step of campaign execution plan, unique within each campaign/reaction',
	previous_step_id           INT(11) NOT NULL COMMENT 'references previous step (workflow_reaction_decl_tbl), 0 = initial step (start icon event triggered)',
	reaction_id                INT(11) NOT NULL COMMENT 'references a reaction (workflow_reaction_tbl)',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	deadline_relative          INT(11) NOT NULL COMMENT 'relative deadline (milliseconds) for this step',
	deadline_hours             INT(11) NOT NULL COMMENT 'exact time of day (hours in admin timezone) for a deadline, is only applicable if deadline_relative exceeds single day, ignored if invalid',
	deadline_minutes           INT(11) NOT NULL COMMENT 'exact time of day (minutes in admin timezone) for a deadline, is only applicable if deadline_relative exceeds single day, ignored if invalid',
	target_id                  INT(11) NOT NULL COMMENT 'target group - ID (dyn_target_tbl) to be applied to recipients taken from previous step, 0 = ignored',
	is_target_positive         INT(1) DEFAULT 1 NOT NULL COMMENT 'whether or not a target group (target_id) should be inverted, 0 = inverted, 1 = direct',
	mailing_id                 INT(11) NOT NULL COMMENT 'mailing - ID (mailing_tbl), mailing to be sent at this step, 0 = ignored',
	UNIQUE (step_id, reaction_id, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT 'contains generic (declaration) action-based campaign execution plan (represents decisions and mailings)';

CREATE TABLE workflow_reaction_log_tbl (
	reaction_id                INT(10) COMMENT 'reaction - ID (workflow_reaction_tbl)',
	company_id                 INT(10) COMMENT 'tenant - ID (company_tbl)',
	customer_id                INTEGER UNSIGNED COMMENT 'customer whose reaction has been registered and handled - ID (customer_<cid>_tbl)',
	reaction_date              DATETIME COMMENT 'date when reaction has been handled'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores handled events watched by action-based workflow, deprecated and must be removed from java code first';

CREATE TABLE workflow_reaction_mailing_tbl (
	company_id                 INTEGER NOT NULL COMMENT 'tenant - ID (company_tbl)',
	reaction_id                INTEGER NOT NULL COMMENT 'reaction - ID (workflow_reaction_tbl)',
	send_mailing_id            INTEGER NOT NULL COMMENT 'mailing - ID (mailing_tbl)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores list of scheduled mailings to be triggered by action-based workflow, deprecated and must be removed from java code first';

CREATE TABLE workflow_reaction_out_tbl (
	case_id                    INT(11) NOT NULL COMMENT 'references (along with step_id) a step (workflow_reaction_step_tbl)',
	step_id                    INT(11) NOT NULL COMMENT 'references (along with case_id) a step (workflow_reaction_step_tbl), 0 = initial step (start icon event triggered)',
	reaction_id                INT(11) NOT NULL COMMENT 'references a reaction (workflow_reaction_tbl)',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'customer - ID (customer_<cid>_tbl)',
	step_date                  TIMESTAMP NOT NULL COMMENT 'date when a step has been processed and recipients have been logged',
	UNIQUE (case_id, step_id, reaction_id, company_id, customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT 'contains recipients produced (filtered) by a particular action-based campaign execution step (mailing sending, decision calculation)';
create index wfrot$datecustrea$idx on workflow_reaction_out_tbl (customer_id, reaction_id, step_date);


CREATE TABLE workflow_reaction_step_tbl (
	case_id                    INT(11) NOT NULL COMMENT 'an identifier used to isolate prepared execution plans (and recipients) generated on different initial trigger events',
	step_id                    INT(11) NOT NULL COMMENT 'identifies a step of campaign execution plan (workflow_reaction_step_tbl and workflow_reaction_decl_tbl)',
	previous_step_id           INT(11) NOT NULL COMMENT 'references previous step to be done first',
	reaction_id                INT(11) NOT NULL COMMENT 'references a reaction (workflow_reaction_tbl)',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	step_date                  TIMESTAMP NOT NULL COMMENT 'date when a step should be processed and marked as done',
	done                       INT(1) DEFAULT 0 NOT NULL COMMENT 'whether or not a step is done (mailing is sent or recipients are prepared for the next step), 0 = pending, 1 = done',
	UNIQUE (case_id, step_id, reaction_id, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT 'contains prepared action-based campaign execution plan generated for a particular trigger event';

CREATE TABLE workflow_reaction_tbl (
	reaction_id                INT(10) AUTO_INCREMENT COMMENT 'unique ID, use workflow_reaction_tbl_seq',
	company_id                 INT(10) COMMENT 'tenant - ID (company_tbl)',
	workflow_id                INT(10) COMMENT 'workflow - ID (workflow_tbl)',
	trigger_mailing_id         INT(10) COMMENT 'mailing to watch user reaction - ID (mailing_tbl)',
	active                     INT(1) DEFAULT 0 COMMENT 'whether or not reaction is being watched, 1 = yes, 0 = no',
	once                       INT(1) DEFAULT 0 COMMENT 'whether or not a second+ event triggered for the same recipient must be ignored, 1 = ignored, 0 = handled',
	start_date                 DATETIME COMMENT 'a date when watching starts, all the earlier changes are ignored',
	reaction_type              INT(10) COMMENT 'type of reactions to be watched',
	profile_column             VARCHAR(100) COMMENT 'recipient profile field to be watched; ignored unless reaction_type = 8',
	rules_sql                  VARCHAR(2000) COMMENT 'an SQL representation of user-defined condition that causes a reaction to be triggered; ignored unless reaction_type = 8',
	trigger_link_id            INTEGER DEFAULT 0 COMMENT 'link in mailing - ID (rdir_url_tbl)',
	is_legacy_mode             INT(1) DEFAULT 1 NOT NULL COMMENT 'whether to use legacy action-based campaign processing (compatible mode for campaigns activated before GWUA-3603), 1 = legacy, 0 = new',
	admin_timezone             VARCHAR(50) DEFAULT 'Europe/Berlin' NOT NULL COMMENT 'timezone to be used for deadline calculation (deadline_hours and deadline_minutes columns of workflow_reaction_decl_tbl)',
	mailinglist_id             INT(11) NOT NULL DEFAULT 0 COMMENT 'mailinglist that the reaction watching should be limited to - ID (mailinglist_tbl)',
	PRIMARY KEY (reaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores customer reactions to be watched (core mechanism of action-based workflow)';
CREATE INDEX workfl_react_l$cuid_rid$idx ON workflow_reaction_log_tbl (customer_id, reaction_id);

CREATE TABLE workflow_reminder_tbl (
	reminder_id                INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	workflow_id                INT(11) NOT NULL COMMENT 'workflow - ID (workflow_tbl)',
	sender_admin_id            INT(11) NOT NULL COMMENT 'admin to be used as message sender - ID (admin_tbl)',
	type                       INT(11) NOT NULL COMMENT 'a reminder type, 0 = workflow start, 1 = workflow stop',
	message                    VARCHAR(2000) COMMENT 'reminder message to be used, may be generated automatically if omitted',
	send_date                  TIMESTAMP NOT NULL COMMENT 'a date when a reminder should be delivered',
	PRIMARY KEY (reminder_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores scheduled workflow reminders';

CREATE TABLE workflow_reminder_recp_tbl (
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	reminder_id                INT(11) NOT NULL COMMENT 'reminder - ID (workflow_reminder_tbl)',
	email                      VARCHAR(200) COMMENT 'an email address to send reminder to',
	admin_id                   INT(11) DEFAULT 0 NOT NULL COMMENT 'admin to send reminder to - ID (admin_tbl), optional',
	notified                   INT DEFAULT 0 NOT NULL COMMENT 'whether or not reminder is delivered to this recipient, 0 = no, 1 = yes',
	CONSTRAINT workflow$rem$recp$remid$fk FOREIGN KEY (reminder_id) REFERENCES workflow_reminder_tbl (reminder_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores recipients for scheduled workflow reminders';

CREATE TABLE workflow_report_schedule_tbl (
	company_id                 INT(10) COMMENT 'tenant - ID (company_tbl)',
	report_id                  INT(10) COMMENT 'report to be generated and sent - ID (birtreport_tbl)',
	send_date                  TIMESTAMP COMMENT 'calculated date when report should be generated and sent',
	sent                       INT(1) DEFAULT 0 COMMENT 'whether or not scheduled report is sent, 1 = yes, 0 = no'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores scheduled reports managed by workflow';

CREATE TABLE workflow_tbl (
	workflow_id                INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use workflow_tbl_seq',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	shortname                  VARCHAR(100) NOT NULL COMMENT 'shortname of a workflow',
	description                VARCHAR(1000) NOT NULL COMMENT 'description of a workflow',
	editor_position_left       INT(11) DEFAULT 0 COMMENT 'scroll offset of the workflow editor viewport, X-axis; pixels',
	editor_position_top        INT(11) DEFAULT 0 COMMENT 'scroll offset of the workflow editor viewport, Y-axis; pixels',
	is_inner                   INT(1) DEFAULT 0 COMMENT 'deprecated, must be removed from java code first',
	status                     INT(1) DEFAULT 1 NOT NULL COMMENT 'current state of a workflow, 1 = open, 2 = active, 3 = deactivated, 4 = complete, 5 = testing, 6 = tested',
	general_start_date         TIMESTAMP COMMENT 'the earliest date configured by start icon(s)',
	general_end_date           TIMESTAMP COMMENT 'the latest date configured by stop icon(s), set if a workflow is configured to end at specific date',
	general_start_reaction     INT(1) DEFAULT 0 COMMENT 'reaction (if any) configured by the earliest start icon (or null)',
	general_start_event        INT(1) DEFAULT 0 COMMENT 'event (if any) configured by the earliest start icon (or null)',
	created                    TIMESTAMP NULL NOT NULL COMMENT 'entry creation date',
	end_type                   INT(1) DEFAULT 0 COMMENT 'type of condition to end active workflow, 1 = automatic, 2 = at specific date',
	workflow_schema            TEXT COMMENT 'JSON representation of workflow icons, their properties and connections between them',
	PRIMARY KEY (workflow_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores workflow entities and some metadata';

CREATE TABLE access_data_tbl (
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	user_agent                 VARCHAR(2000) COMMENT 'EMail-client identification string',
	xuid                       VARCHAR(200) DEFAULT NULL COMMENT 'xuid for opener / clicker',
	ip                         VARCHAR(40) COMMENT 'IP of opener / clicker',
	referer                    VARCHAR(2000) COMMENT 'referer',
	access_type                VARCHAR(40) COMMENT 'ONEPIXEL = opening, REDIRECT = click',
	mailing_id                 INT(11) COMMENT 'references Mailing (mailing_tbl)',
	customer_id                INTEGER UNSIGNED COMMENT 'references recipient (customer_xxx_tbl)',
	link_id                    INT(11) COMMENT 'references Link (click only) (rdir_url_tbl)',
	device_id                  INT(11) COMMENT 'references device (device_tbl)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'limited Data Buffer for all clicks and openings, would be reworked (to lastopen / lastclick in recipient proilfe) and cleared up daily';

CREATE TABLE active_subscriber_tbl (
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	active_subscribers         INT(11) COMMENT 'number of active subscriber for this company at timestamp',
	timestamp                  TIMESTAMP NOT NULL COMMENT 'timestamp of evaluated the current number of active subscriber'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'used by backend - billing scripts for monthly recipient analysis';

CREATE TABLE admin_group_tbl (
	admin_group_id             INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique group ID, use admin_group_tbl_seq',
	company_id                 INT(11) DEFAULT 0 COMMENT 'tenant - use company_ID 1 for generic groups',
	shortname                  VARCHAR(100) DEFAULT '' COMMENT 'name of the admin groups',
	description                VARCHAR(1000) DEFAULT '' COMMENT 'description of the admin groups',
	PRIMARY KEY (admin_group_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores groups for users to handle permissions easier';

CREATE TABLE admin_group_permission_tbl (
	admin_group_id             INT(11) COMMENT 'references to admin_group_tbl (FK, on delete cascade)',
	security_token             VARCHAR(50) DEFAULT '' COMMENT 'permissions of the user',
	UNIQUE KEY unique_admin_group_idx (admin_group_id, security_token),
	KEY admin_group_idx (admin_group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'assign permissions to admin_groups';
ALTER TABLE admin_group_permission_tbl ADD UNIQUE INDEX admin_grp_tbl$id_sectkn$uq (admin_group_id, security_token);
ALTER TABLE admin_group_permission_tbl ADD CONSTRAINT admingrpperm$admingrpid$fk FOREIGN KEY (admin_group_id) REFERENCES admin_group_tbl (admin_group_id) ON DELETE CASCADE;

CREATE TABLE admin_tbl (
	admin_id                   INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID (PK), use admin_tbl_seq',
	username                   VARCHAR(100) NOT NULL DEFAULT '' COMMENT '[private_data] EMM-Login',
	company_id                 INT(11) UNSIGNED DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	fullname                   VARCHAR(100) DEFAULT '' COMMENT '[private_data] Name of the EMM-User, shown in GUI',
	admin_country              VARCHAR(10) DEFAULT 'de' COMMENT 'home country of the administrator according to domain notation',
	admin_lang                 VARCHAR(10) DEFAULT 'DE' COMMENT 'language of the admin',
	admin_lang_variant         VARCHAR(10) DEFAULT '' COMMENT 'additional information on the language setting',
	admin_timezone             VARCHAR(50) DEFAULT 'Europe/Berlin' COMMENT 'timezone, used for any date / timebased actions to bring in line with users local time',
	pwdchange_date             TIMESTAMP NULL COMMENT 'last password - change to check for expired passwords',
	admin_group_id             INT(11) DEFAULT 0 COMMENT 'assigned Admin_group',
	default_import_profile_id  INT(11) DEFAULT 0 COMMENT 'Preference setting which import profile to be used by default',
	creation_date              TIMESTAMP NULL COMMENT 'user created',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'user last changed',
	stat_email                 VARCHAR(200) COMMENT '[private_data] used for reports like ADV - Report, deledt mails report',
	layout_base_id             INT(11) DEFAULT 0 COMMENT 'Used for layout configuration in whitelabel applications',
	company_name               VARCHAR(100) COMMENT '[private_data] EMM-tenant name, shown in GUI',
	email                      VARCHAR(200) COMMENT 'Email of this admin',
	secure_password_hash       VARCHAR(200) COMMENT 'Secured hash of admins password',
	lastPopUp                  TIMESTAMP NULL COMMENT 'When was the last popup shown to this admin',
	lastmessageoftheday        TIMESTAMP NULL COMMENT 'Date of the last shown message of the day',
	firstname                  VARCHAR(100) DEFAULT '' COMMENT 'Admins firstname',
	gender                     INT DEFAULT 2 COMMENT 'Admins gender (0=male, 1=female, 0=unknown)',
	title                      VARCHAR(300) COMMENT 'Admins optional title',
	news_date                  TIMESTAMP NULL COMMENT 'Date of last news entry shown to admin',
	message_date               TIMESTAMP NULL COMMENT 'Date of last message entry shown to admin',
	is_one_time_pass           INT(1) NULL DEFAULT 0 COMMENT 'Flag that indicates about a temporary password set',
	phone_number               VARCHAR(100) COMMENT 'Phone number of admin in case for any queries',
	PRIMARY KEY (admin_id),
	UNIQUE KEY username (username),
	UNIQUE KEY admin_tbl$username$uq (username),
	KEY company_id (company_id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[private_data] stores EMM-Users';


CREATE TABLE admin_permission_tbl (
	admin_id                   INT(11) DEFAULT 0 COMMENT 'references to admin_tbl (FK, on delete cascade)',
	security_token             VARCHAR(40) COMMENT 'name of the security token',
	KEY admin_idx (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'assign permissions to users';
ALTER TABLE admin_permission_tbl ADD UNIQUE INDEX admin_tbl$id_sectkn$uq (admin_id, security_token);
ALTER TABLE admin_permission_tbl ADD CONSTRAINT adminperm$adminid$fk FOREIGN KEY (admin_id) REFERENCES admin_tbl (admin_id) ON DELETE CASCADE;

CREATE TABLE company_permission_tbl (
	company_id                 INTEGER,
	security_token             VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE company_permission_tbl ADD CONSTRAINT comppermtbl$id_sectkn$pk PRIMARY KEY (company_id, security_token);

CREATE TABLE auto_import_mlist_bind_tbl (
	auto_import_id             INT(11) NOT NULL COMMENT 'references auto_import_tbl.auto_import_id',
	mailinglist_id             INT(10) UNSIGNED NOT NULL COMMENT 'references mailinglist_tbl. mailinglist_id',
	company_id                 INT(11) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	PRIMARY KEY (auto_import_id, mailinglist_id),
	KEY company_id (company_id),
	KEY mailinglist_id (mailinglist_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'allowes n:m relation between imports and mailinglists';

CREATE TABLE auto_import_tbl (
	auto_import_id             INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use auto_import_tbl_seq',
	import_profile_id          INT(10) UNSIGNED NOT NULL COMMENT 'references import_profile (import_profile_tbl.id)',
	shortname                  VARCHAR(100) NOT NULL COMMENT 'import - name',
	description                VARCHAR(1000) COMMENT 'comment on entry',
	file_path                  VARCHAR(400) NOT NULL COMMENT 'file to recive import file(s)',
	one_time                   INT(1) NOT NULL COMMENT '1=run only once, 0= do not run',
	auto_resume                INT(1) NOT NULL COMMENT 'Start this import next planed time, even if there have been errors',
	executed                   INT(1) NOT NULL COMMENT '1= yes, 0= no',
	company_id                 INT(11) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	admin_id                   INT(11) NOT NULL COMMENT 'references EMM-User (admin_tbl)',
	active                     INT(1) DEFAULT 0 NOT NULL COMMENT '0 = deactivated / done, 1 = active',
	auto_activation_date       TIMESTAMP NULL COMMENT 'import will be activated at this time',
	deactivate_by_campaign     INT(1) DEFAULT 0 NOT NULL COMMENT 'If autoimport is used by a campaign, this campaign may be deactivated and then deactivates this autoimport also',
	type                       VARCHAR(64) COMMENT 'e.g. Recipient or ReferenceTable',
	csvdescription_id          INT COMMENT 'references csv_imexport_description_tbl.id',
	referencetable_id          INT COMMENT 'references reference_tbl.id',
	allow_unknown_hostkeys     INTEGER COMMENT '1=allowed, 0= disallowed',
	file_server_encrypted      VARCHAR(400) COMMENT 'encryped path to file server',
	private_key                VARCHAR(2048) COMMENT 'for sftp connection',
	created                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	changed                    TIMESTAMP NULL COMMENT 'entry last change',
	laststart                  TIMESTAMP NULL COMMENT 'last run timestamp',
	running                    INT(1) DEFAULT 0 COMMENT '1=actually executing, 0= not executing',
	lastresult                 VARCHAR(512) NULL COMMENT 'last run result (ok or error message)',
	intervalpattern            TEXT NULL COMMENT 'defines execution times',
	nextStart                  TIMESTAMP NULL COMMENT 'next run timestamp',
	lasthostname               VARCHAR(64) NULL COMMENT 'last host on wich the job was executed',
	emailOnError               VARCHAR(64) NULL COMMENT '[private_data] email - recipient for any error-reports',
	alwaysimportfile           INTEGER COMMENT 'Always import found same files (by date and size), even if they have been imported before',
	importmultiplefiles        INTEGER COMMENT 'allows to import more than one file, identified by name pattern',
	retrycount                 INTEGER DEFAULT 0 COMMENT 'Current retry of errorneous import',
	maximum_retries            INTEGER DEFAULT 0 COMMENT 'Maximum number of retries of errorneous import',
	interval_as_json           TEXT COMMENT 'JSON format of interval pattern',
	timezone                   VARCHAR(48) COMMENT 'Timezone to be used for calculation of next start by interval pattern',
	PRIMARY KEY (auto_import_id),
	KEY company_id (company_id),
	KEY admin_id (admin_id),
	KEY import_profile_id (import_profile_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'contains information about sheduled imports';

CREATE TABLE auto_import_used_files_tbl (
	auto_import_used_file_id   INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use auto_import_used_files_tbl_seq',
	auto_import_id             INT(11) NOT NULL COMMENT 'references auto_import_tbl.auto_import_id',
	file_size                  INT(15) NOT NULL COMMENT 'size in B',
	file_date                  DATETIME NOT NULL COMMENT 'file date ( != import date)',
	company_id                 INT(11) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	local_file_name            VARCHAR(1024) COMMENT 'file is (temporarly) archived with this name',
	remote_file_name           VARCHAR(1024) COMMENT 'file name (incl path) as given',
	csvlines                   INTEGER COMMENT 'Number of lines imported',
	duration                   INTEGER COMMENT 'Duration of this import',
	import_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Date of this import',
	download_duration_millis   INTEGER DEFAULT -1 COMMENT 'Duration of the import file download',
	PRIMARY KEY (auto_import_used_file_id),
	KEY company_id (company_id),
	KEY auto_import_id (auto_import_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'history / log for done imports: related files';

CREATE TABLE auto_import_result_tbl (
	auto_import_id             INT(4) NOT NULL COMMENT 'references auto_import_tbl.auto_import_id',
	time                       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'import starting timestamp',
	result                     VARCHAR(4000) NOT NULL COMMENT 'success / error message',
	duration                   INT(8) DEFAULT 0 COMMENT 'in sec',
	hostname                   VARCHAR(64) NOT NULL COMMENT 'executing host',
	datasourceid               INTEGER COMMENT 'Referenced id of datasource_description_tbl for new entries',
	fieldcount                 INTEGER COMMENT 'Number of used csv file fields',
	insertcount                INTEGER COMMENT 'Number of new lines inserted in db',
	updatecount                INTEGER COMMENT 'Number of new lines updated in db',
	filesize                   INTEGER COMMENT 'Size of the imported file in bytes'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'history / log for done imports: result and duration for monitoring / tracing issues and import report';
ALTER TABLE auto_import_result_tbl ADD CONSTRAINT aimpresult$id$fk FOREIGN KEY (auto_import_id) REFERENCES auto_import_tbl (auto_import_id);

CREATE TABLE bounce_collect_tbl (
	customer_id                INTEGER UNSIGNED COMMENT 'customer_xx_tbl.customer_id for whom this bounce has been registrated',
	mailing_id                 INT(10) COMMENT 'mailing_tbl.mailing_id for which mail the bounce had been created',
	company_id                 INT(10) COMMENT 'company_tbl.company_id owner of the mailing',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'timestamp of processing',
	KEY bnccoll$cust$idx (customer_id),
	KEY bnccoll$coid$idx (company_id),
	KEY bnccoll$cust_coid$idx (customer_id, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'internal used temp. table during softbounce processing';

CREATE TABLE bounce_tbl (
	dsn                        INT(10) COMMENT 'Code reported by mailsystem',
	bounce_id                  INT(10) NOT NULL AUTO_INCREMENT COMMENT 'legacy',
	company_id                 INT(10) COMMENT 'tenant - ID (company_tbl)',
	customer_id                INTEGER UNSIGNED COMMENT 'ID of the recipient',
	detail                     INT(10) COMMENT 'detail-code for bounce-reason',
	mailing_id                 INT(10) COMMENT 'ID of the Mailing',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'bounce-timestamp',
	PRIMARY KEY (bounce_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'processing / handling bounces for all EMM-tenants';

CREATE TABLE bounce_translate_tbl (
	company_id                 INT(11) NOT NULL COMMENT '0=global setting, >0 only used for this company_tbl.company_id',
	dsn                        INT(11) NOT NULL COMMENT 'the Delivery Status Notification as determinated from mail delivery',
	detail                     INT(11) NOT NULL COMMENT 'qualified bounce code',
	pattern                    VARCHAR(150) COMMENT '(optional) regular expression to only apply the translation if this pattern matches the status text from the MTA'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'translates Delivery Status Notification (DSN) codes to qualified bounce codes';

CREATE TABLE calendar_comment_tbl (
	comment_id                 INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use calendar_comment_tbl_seq',
	company_id                 INT(11) DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	admin_id                   INT(11) COMMENT 'EMM - User, references admin_tbl.admin_ID',
	comment_content            VARCHAR(1000) COMMENT 'note content',
	comment_date               TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Date (in calendar for this entry)',
	deadline                   INT(1) DEFAULT 0 COMMENT 'Does this date have a final deadline 1= comment should be sent - to...?',
	planned_send_date          TIMESTAMP NOT NULL COMMENT 'Remind user at this time',
	PRIMARY KEY (comment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'in EMM - calendar comments to a specified date could be set, this data are stored here';

CREATE TABLE click_stat_colors_tbl (
	id                         INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use click_stat_colors_tbl_seq',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	range_start                INT(10) NOT NULL COMMENT 'threshold - lower value',
	range_end                  INT(10) NOT NULL COMMENT 'threshold - upper value',
	color                      VARCHAR(6) NOT NULL COMMENT 'RGB-color value',
	PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores color information to show heatmap';

CREATE TABLE company_info_tbl (
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID, use 0 for global settings',
	cname                      VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'specify parameter to set e.g. ahv:is-enabled',
	cvalue                     VARCHAR(4000) DEFAULT '' COMMENT 'Configuration value',
	description                VARCHAR(250) DEFAULT '' COMMENT 'Description for a configuration entry',
	creation_date              TIMESTAMP NULL COMMENT 'Creation date of this configuration entry',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Change date of this configuration entry',
	PRIMARY KEY (company_id, cname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'tenant settings / global settings, e.g. MIA or success-log';

CREATE TABLE company_tbl (
	rdir_domain                VARCHAR(100) COMMENT 'default rdir-domain',
	company_id                 INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID (PK), use company_tbl_seq',
	shortname                  VARCHAR(30) DEFAULT '' COMMENT '[private_data] tenant name',
	description                VARCHAR(300) DEFAULT '' COMMENT '[private_data] comment on entry',
	status                     VARCHAR(20) COMMENT'pls use active / deleted / todelete or inactive for temp. deactivation',
	mailtracking               INT(11) DEFAULT 0 COMMENT '1 = mailtrack_<company_id>_tbl will be filled, 0 if not',
	creator_company_id         INT(11) DEFAULT 1 COMMENT 'ID of master - company, needed for administration sub-companies via EMM',
	mailerset                  INT(11) DEFAULT 0 COMMENT 'default mailerset - id, references serverset_tbl, 0 = not specified',
	customer_type              VARCHAR(50) NOT NULL DEFAULT 'UNKNOWN' COMMENT 'legacy, PROJ-711',
	pricing_id                 INT(11) COMMENT 'legacy, PROJ-711',
	xor_key                    INT(11) COMMENT 'legacy (for generating first version agnUIDs)',
	send_immediately           INT(11) DEFAULT 0 COMMENT 'if set to a value != 0 then sending out of mailings starts immediately during generating and not when the mail generation is finished',
	offpeak                    INT(11) DEFAULT 0 COMMENT 'legacy, PROJ-711',
	notification_email         VARCHAR(100) COMMENT '[private_data] mailadress set to get system-notifications from EMM',
	mailloop_domain            VARCHAR(200)COMMENT 'This is the default domain used to build dynamic filter (mailloop) addresses; it is also used for display these addresses in the GUI',
	expire_stat                INT(11) COMMENT '(sent) (world-) mailings would be deleted after this period (in days)',
	max_fields                 INT(11) COMMENT 'allowed number of customer-profil-fields in customer_<company_id>_tbl',
	stat_admin                 INT(11) COMMENT 'ID of executive admin for company',
	expire_bounce              INT(11) COMMENT 'bounces of this companyID will be deleted after this period (in days)',
	expire_onepixel            INT(11) COMMENT 'onepixellog-entries would be deleted after this period (in days)',
	expire_cookie              INT(11) COMMENT 'cookies for shoptracking would be invalid after this period (in days)',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'entry last change',
	max_login_fails            INT(3) NOT NULL DEFAULT 3 COMMENT 'tenant would be locked after this number of login fails (default: 3)',
	login_block_time           INT(5) NOT NULL DEFAULT 300 COMMENT 'tenant would be locked after login fails for x sec (default: 300)',
	sector                     INT(11) COMMENT 'benchmark - statistics: 0, NONE, 1, AGENCIES, 2, COMMUNITIES, 3, TOURISM, 4, FINANCE, 5, IT, 6, RETAIL, 7, MANUFACTURING_INDUSTRY, 8, CONSUMER_GOODS, 9, PUBLISHER, 10, NON_PROFIT, 11, EDUCATION',
	business_field             INT(11) COMMENT 'benchmark - statistics: 0, NONE, 1, B2B, 2, B2C',
	secret_key                 VARCHAR(32) COMMENT 'the secret key for generating agnUIDs',
	mails_per_day              VARCHAR(500) COMMENT 'If not NULL, this is an expression to describe the limit of how many mails one recipient of this company may receive per day',
	uid_version                INT(2) COMMENT 'defines what UID - version at least has to be used: 0=old UID, 1=XUID (actual one)',
	expire_recipient           INT(11) DEFAULT 30 COMMENT 'recipients having not commited opt-in would be deleted after this period (in days, default 30)',
	max_recipients             INT(11) DEFAULT 0 COMMENT '?, DEFAULT 0',
	salutation_extended        INT(11) DEFAULT 0 COMMENT 'enables gender 3-6 in title_gender_tbl, DEFAULT 0',
	enabled_uid_version        INT(11) NOT NULL COMMENT 'currently active agnUID version for this company',
	expire_upload              INT(11) DEFAULT 14 COMMENT 'uploaded files would be deleted after this period (days, default: 14)',
	maxadminmails              INT(11) DEFAULT 100 COMMENT 'defines maximum number of admin mailings for one admin mailing',
	parent_company_id          INT(11) COMMENT 'Parent companyid for master/sub client constructs',
	export_notify              INT(11) DEFAULT 0 COMMENT 'defines if the stat_admin get a notification about exports, 0 = false, 1 = true, DEFAULT 0',
	auto_mailing_report_active INT(11) DEFAULT 0 COMMENT 'Automatically send a report-mail for sent mailings after 24h, 48h and 1 week, DEFAULT 0',
	auto_deeptracking          INT(1) DEFAULT 0 COMMENT 'defines if all links should be extended for deeptracking automatically, 0 = false, 1 = true, DEFAULT 0',
	default_datasource_id      INT(7) COMMENT 'default datasource, would be set, if no explizit datasource_ID is given. references datasource_description_tbl',
	expire_success             INT(11) DEFAULT 0 COMMENT 'success_<company_id>_tbl-entries would be deleted after this period (in days), filling activated by setting log-success param in company_info_tbl',
	priority_count             INTEGER COMMENT 'max number of mails a recipient may receive per day for mailings with priority',
	contact_tech               VARCHAR(400) COMMENT 'Emails list separated by [,; ] for technical contact',
	PRIMARY KEY (company_id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[private_data] stores tenant data and partly tenant settings';
CREATE UNIQUE INDEX comp$name$idx ON company_tbl (shortname);

CREATE TABLE component_tbl (
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	mailtemplate_id            INT(10) UNSIGNED DEFAULT 0 COMMENT 'references related template',
	mailing_id                 INT(10) UNSIGNED DEFAULT 0 COMMENT 'references related mailing',
	component_id               INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID (PK), use COMPONENT_TBL_SEQ',
	mtype                      VARCHAR(200) COMMENT 'Mimetype of the component, 0 = Mobile HTML (Deprecated)',
	required                   INT(10) UNSIGNED DEFAULT 0 COMMENT '0 = no, 1 = yes',
	comptype                   INT(10) UNSIGNED DEFAULT 0 COMMENT 'Type of the component: 0: TEMPLATE 1: External image (referenced via URL) 2: Deprecated 3: Attachment 4: Personalized attachment 5: Embedded image 6: Font (for personalized attachment) 7: Parsable attachment 8: THUMBNAIL_IMAGE',
	comppresent                INT(10) UNSIGNED DEFAULT 0 COMMENT 'If this is 0, this component is no more in use',
	compname                   VARCHAR(150) NOT NULL COMMENT 'component name',
	emmblock                   LONGTEXT COMMENT 'The content of the component',
	binblock                   LONGBLOB COMMENT 'Additional binary information used e.g. for crossmedia',
	target_id                  INT(10) UNSIGNED DEFAULT 0 COMMENT 'references component - specific targetGroup',
	url_id                     INT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'auto-generated link for any pictures / graphics',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'last change on component',
	description                VARCHAR(200) COMMENT 'component description',
	validity_start_date        TIMESTAMP NULL COMMENT 'for compoments, that should be used for a terminated period only',
	validity_end_date          TIMESTAMP NULL COMMENT 'for compoments, that should be used for a terminated period only',
	cdn_id                     VARCHAR(32),
	PRIMARY KEY (component_id),
	KEY component$coid_mid$idx (company_id, mailing_id),
	KEY component$compname$idx (compname),
	KEY component$mtype$idx (mtype)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores mailing-components';
CREATE INDEX component$midtypbin$idx ON component_tbl (mailing_id, comptype, binblock(32));
CREATE INDEX component$coid$idx ON component_tbl (company_id);
CREATE INDEX component$mid$coid$idx ON component_tbl (mailing_id, company_id);
CREATE INDEX component$mid$idx ON component_tbl (mailing_id);
CREATE INDEX component$ctype$idx ON component_tbl (comptype);
CREATE INDEX component$cidctype$idx ON component_tbl (company_id, comptype);
CREATE UNIQUE INDEX component$cdn_id$uq ON component_tbl (cdn_id);

CREATE TABLE config_tbl (
	class                      VARCHAR(32),
	name                       VARCHAR(64),
	value                      TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cust1_ban_tbl (
	email                      VARCHAR(100) COMMENT '[secret_data] blacklisted address or (while using wildcards) domain / pattern',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'blacklisting timestamp',
	PRIMARY KEY (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[secret_data] stores tenant - blacklist';

CREATE TABLE customer_1_tbl (
	customer_id                INTEGER UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID (PK), use customer_1_tbl_seq',
	email                      VARCHAR(100) NOT NULL COMMENT 'recipients email',
	firstname                  VARCHAR(100) COMMENT 'recipients first name',
	lastname                   VARCHAR(100) COMMENT 'recipients last name',
	gender                     INT(11) NOT NULL DEFAULT 2 COMMENT '0-male, 1-female, 2-unknown, 3=female2, 4=praxis, 5-company',
	mailtype                   INT(11) NOT NULL DEFAULT 0 COMMENT '0-text, 1-html, 2-offline-html',
	title                      VARCHAR(100) COMMENT 'title of the receiver',
	bounceload                 INT(11) NOT NULL DEFAULT 0 COMMENT 'Special value. See AGNEMM-1817, AGNEMM-1924 and AGNEMM-1925',
	datasource_id              INT(11) DEFAULT 0 COMMENT 'references datasource_description_tbl.datasource_id - marks the origin of any reciepient, should be filled always!',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change, default: sysdate',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date, default: sysdate',
	facebook_status            INT(1) COMMENT 'Legacy facebook status',
	foursquare_status          INT(1) COMMENT 'Legacy foursquare status',
	google_status              INT(1) COMMENT 'Legacy Google+ status',
	twitter_status             INT(1) COMMENT 'Legacy twitter status',
	xing_status                INT(1) COMMENT 'Legacy Xing status',
	lastopen_date              TIMESTAMP NULL COMMENT 'last registered opening of this recipient, daily filled / updated by job-queue-based job',
	lastclick_date             TIMESTAMP NULL COMMENT 'last registered click of this recipient, daily filled / updated by job-queue-based job',
	latest_datasource_id       INT(11) COMMENT 'latest souce of changes on recipient data, should be filled always!',
	lastsend_date              TIMESTAMP NULL COMMENT 'latest mailing sent to this recipient, filled / updated during mail-sending',
	sys_tracking_veto          INTEGER(1) COMMENT 'DSGVO tracking veto',
	cleaned_date               TIMESTAMP NULL COMMENT 'latest date, when field content of recipients (without active binding) were emptied ',
	PRIMARY KEY (customer_id),
	KEY email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[private_data] stores recipient data, only default columns documented more might be created by EMM-users';
CREATE INDEX cust1$email$idx ON customer_1_tbl (email);

CREATE TABLE customer_1_binding_tbl (
	customer_id                INTEGER UNSIGNED NOT NULL DEFAULT 0 COMMENT 'reciepientID - references customer_1_tbl',
	mailinglist_id             INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'mailinglistID - references mailinglist_tbl',
	user_type                  CHAR(1) COLLATE utf8mb4_bin COMMENT 'reciepient type: W = world-rec. A = Admin-rec, T = Test-rec., w = VIP(!) - world-rec, t = VIP(!) tester-rec, E = deprecated/do not use',
	user_status                INT(10) NOT NULL COMMENT 'current state: 1 = active, 2 = bounced, 3 = opt out by admin, 4 = opt out by user, 5 = DOI waiting for confirm, 6 = blacklisted, 7 / 0 = Suspend - customer specific  cases only',
	user_remark                VARCHAR(150) COMMENT 'comment on last state - change',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'timestamp of last state - change',
	exit_mailing_id            INT(10) UNSIGNED COMMENT 'mailingID causing state-change to bounce or opt-out',
	creation_date              TIMESTAMP NULL COMMENT 'binding creation date',
	mediatype                  INT(10) UNSIGNED DEFAULT 0 COMMENT 'mediatype: 0 = Email, 1 = Fax, 2 = Print, 3 = MMS, 4 = SMS',
	referrer                   VARCHAR(4000) COMMENT 'Http referrer header value if set in subscription request',
	UNIQUE KEY cust_1_bind_un (customer_id, mailinglist_id, mediatype)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'n:m releation between reciepients and mailinglists';
CREATE INDEX cust1b$cuid_ustat_mlid$idx ON customer_1_binding_tbl (customer_id, user_status, mailinglist_id);

CREATE TABLE hst_customer_1_binding_tbl (
	customer_id                INTEGER UNSIGNED COMMENT 'reciepientID - references customer_1_tbl',
	mailinglist_id             INT COMMENT 'mailinglistID - references mailinglist_tbl',
	user_type                  CHAR(1) COMMENT 'reciepient type: W = world-rec. A = Admin-rec, T = Test-rec., w = VIP(!) - world-rec, a = VIP (!) admin-rec',
	user_status                INT COMMENT 'current state: 1 = active, 2 = bounced, 3 = opt out by admin, 4 = opt out by user, 5 = DOI waiting for confirm, 6 = blacklisted, 7 / 0 = Suspend - customer specific  cases only',
	user_remark                VARCHAR(150) COMMENT 'comment on last state - change',
	timestamp                  TIMESTAMP NULL COMMENT 'timestamp of last state - change',
	creation_date              TIMESTAMP NULL COMMENT 'binding creation date',
	exit_mailing_id            INT COMMENT 'mailingID causing state-change to bounce or opt-out',
	mediatype                  INT COMMENT 'mediatype: 0 = Email, 1 = Fax, 2 = Print, 3 = MMS, 4 = SMS',
	change_type                INT COMMENT '0 = deleted, 1 = updated',
	timestamp_change           TIMESTAMP NULL COMMENT 'timestamp of update / delete that is overwriting deleting this dataset',
	client_info                VARCHAR(150) COMMENT 'client who made this changes, e.g. console (frontend)',
	email                      VARCHAR(100) COMMENT '[private_data] recipients email in order to trace deleted recipients',
	referrer                   VARCHAR(4000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[private_data] stores history for recipient - mailinglist - relation, any values are stored as a copy of values BEFORE latest change';
CREATE INDEX hstcb1$email$idx ON hst_customer_1_binding_tbl (email);
CREATE INDEX hstcb1$mlidcidl$idx ON hst_customer_1_binding_tbl (mailinglist_id, customer_id);
CREATE INDEX hstcb1$tsch$idx ON hst_customer_1_binding_tbl (timestamp_change);

INSERT INTO company_info_tbl (company_id, cname, cvalue, description, creation_date, timestamp)
	VALUES (1, 'recipient.binding_history.rebuild_trigger_on_startup', 'true', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

CREATE TABLE interval_track_1_tbl (
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'Customer reference',
	mailing_id                 INT NOT NULL COMMENT 'Mailing reference',
	send_date                  TIMESTAMP NOT NULL COMMENT 'Send date of this interval mailing to a specific customer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE INDEX intervtrack$1mid$idx ON interval_track_1_tbl (mailing_id) COMMENT 'stores mailtracking data for interval-mailings';

CREATE TABLE success_1_tbl (
	customer_id                INTEGER UNSIGNED COMMENT 'Customer reference',
	mailing_id                 INT(11) COMMENT 'Mailing reference',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Change date of this entry'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores successfully delivered mailings to any specified recipient, filled only if log-success param is set in company_info_tbl (per tenant or instance), storing period defined by company_tbl.EXPIRE_SUCCESS';
CREATE INDEX suc1$mid$idx ON success_1_tbl (mailing_id);
CREATE INDEX suc1$cid$idx ON success_1_tbl (customer_id);
CREATE INDEX suc1$tmst$idx ON success_1_tbl (timestamp);

CREATE TABLE rdir_traffic_amount_1_tbl (
	mailing_id                 INTEGER,
	content_name               VARCHAR(3000) COMMENT 'Name of demanded content',
	content_size               INTEGER COMMENT 'Size of demanded content',
	demand_date                TIMESTAMP NULL COMMENT 'Date of demand request'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores information on rdir trafic data amount';

CREATE TABLE rdir_traffic_agr_1_tbl (
	mailing_id                 INTEGER COMMENT 'Referenced mailing id',
	content_name               VARCHAR(3000) COMMENT 'Name of demanded content',
	content_size               INTEGER COMMENT 'Size of demanded content',
	demand_date                TIMESTAMP NULL COMMENT 'Day date of this summed up entry',
	amount                     INTEGER COMMENT 'Amount of times this content was requested'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores information on rdir trafic data amount with a daily aggregation of rdir_traffic_amount_1_tbl';

CREATE TABLE customer_field_tbl (
	admin_id                   INT(11) COMMENT 'referes to EMM-User (admin_tbl)',
	col_name                   VARCHAR(50) COMMENT 'Name of related DataBaseColumn, unique per tenant',
	shortname                  VARCHAR(200) COMMENT 'field name shown in EMM',
	description                VARCHAR(500) COMMENT 'description for this field',
	default_value              VARCHAR(200) COMMENT 'default value (might be set for views / subaccounts, too',
	mode_edit                  INT(11) COMMENT '1 = readonly, 2 = hidden, 0 = no restriction',
	mode_insert                INT(11) COMMENT 'legacy?',
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	field_group                INT(11) COMMENT 'for grouping fields in EMM layout (references customer_field_group_tbl)',
	field_sort                 INT(11) NOT NULL DEFAULT 0 COMMENT 'sorting order in EMM (if applicable: in group)',
	line                       INT(11) COMMENT '1=horizontal ruler after this field in EMM - Layout',
	isinterest                 INT(11) DEFAULT 0 COMMENT 'defines interest to order blocks in mailing - dyn_name_tbl.INTEREST_GROUP',
	creation_date              TIMESTAMP NULL COMMENT 'setting creation',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'setting last change',
	historize                  INTEGER(1) COMMENT '1 = history of any changes in this field would be logged (in hst_customer_xxx_tbl) if profile-field-history is active)',
	allowed_values             TEXT COMMENT 'Optional restricting set of values allowed for this field',
	PRIMARY KEY (company_id, col_name),
	KEY custfield$coid$colname (company_id, col_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'configure individual layout for recipient profile fields per EMM - user';

CREATE TABLE customer_field_permission_tbl (
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	column_name                VARCHAR(32) NOT NULL DEFAULT '' COMMENT '(EMM-) fieldname',
	admin_id                   INT(11) NOT NULL DEFAULT 0 COMMENT 'references EMM-User (admin_tbl)',
	mode_edit                  INT(11) NOT NULL DEFAULT 0 COMMENT '0 = no restrictions, 1 = read only, 2 = hidden',
	PRIMARY KEY (company_id, column_name, admin_id),
	KEY custfieldperm$coid$colname (company_id, column_name, admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'allows to add permissions for EMM-users to update (or not) per profile-field';
ALTER TABLE customer_field_permission_tbl ADD CONSTRAINT customer_field_permission_tbl_ibfk_1 FOREIGN KEY (company_id, column_name) REFERENCES customer_field_tbl (company_id, col_name);

CREATE TABLE datasource_description_tbl (
	datasource_id              INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use datasource_description_tbl_seq',
	description                VARCHAR(1000) NOT NULL DEFAULT '' COMMENT 'data source description',
	company_id                 INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl), use 0 for global sources',
	sourcegroup_id             INT(11) UNSIGNED DEFAULT 0 COMMENT 'source-group (references source_group_tbl)',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'source creation / registration date',
	url                        VARCHAR(500) DEFAULT '' COMMENT 'URL e.g. for subscribe forms',
	desc2                      VARCHAR(500) DEFAULT '' COMMENT 'secondary description',
	PRIMARY KEY (datasource_id),
	KEY company_id (company_id),
	KEY sourcegroup_id (sourcegroup_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'defines a source for new recipients / recipient updates, FK to company_tbl dropped in order to allow global settings';

CREATE TABLE date_tbl (
	type                       INT(11) NOT NULL COMMENT 'unique ID - no sequence set',
	format                     VARCHAR(100) COMMENT 'Date format (as java SimpleDateFormat)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'information to expand agnDATE - Tag';

CREATE TABLE user_agent_tbl (
	user_agent_id              INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use user_agent_tbl_seq',
	user_agent                 VARCHAR(2000) NOT NULL COMMENT 'user-agent-string as given by client',
	req_counter                INT(11) COMMENT 'counts all registrations of this string',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change (esp. last count)',
	PRIMARY KEY (user_agent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores all client - information about clients used to open / click a mailing, evaluated regulary to keep RegEx for devices and device - classes up to date';

CREATE TABLE user_agent_for_client_tbl (
	user_agent_id              INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique UserAgent entry id for references (not used by now)',
	user_agent                 VARCHAR(2000) NOT NULL COMMENT 'UserAgent string',
	req_counter                INT(11) COMMENT 'Number of occurences of this UserAgent since measurement started',
	creation_date              TIMESTAMP NULL COMMENT 'First occurence of this UserAgent',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Latest occurence of this UserAgent',
	PRIMARY KEY (user_agent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Interim storage for email-client and browser UserAgent strings for later manually detection of new clients';

CREATE TABLE device_blacklist_tbl (
	device_id                  INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Reference key',
	device_order               INT(11) COMMENT 'Order to check reg exp',
	description                VARCHAR(200) COMMENT 'Description',
	regex                      VARCHAR(200) COMMENT 'Reg Exp for Useragent',
	service                    INT(1) COMMENT 'Activation sign',
	PRIMARY KEY (device_id)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Devices (Useragents) to not log like facebook crawlers';

CREATE TABLE client_tbl (
	client_id                  INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique client id for reference in onepixellog and rdirlog tables',
	client_order               INT(11) COMMENT 'Order of evaluation to allow generic clientd-patterns to be used after specific ones',
	description                VARCHAR(200) COMMENT 'Description text for client',
	regex                      VARCHAR(200) COMMENT 'Regular expression used for detection on UserAgent strings',
	PRIMARY KEY (client_id)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Detection data for email-clients and browsers used for link-clicks';

CREATE TABLE doc_mapping_tbl (
	filename                   VARCHAR(200) COMMENT 'filename',
	pagekey                    VARCHAR(50) COMMENT 'pagekey',
	UNIQUE KEY doc_mapping_idx (pagekey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Maps pagekeys of JSPs to certain files in the online user manual for context sensitive online help .';

CREATE TABLE dyn_content_tbl (
	dyn_content_id             INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use dyn_content_tbl_seq',
	dyn_name_id                INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'references dyn_name_tbl',
	target_id                  INT(10) UNSIGNED COMMENT 'references dyn_target_tbl, allows to generate content for special target groups only',
	dyn_order                  INT(10) UNSIGNED COMMENT 'orders content within a text-block',
	dyn_content                LONGTEXT COMMENT 'the content itself',
	mailing_id                 INT(10) UNSIGNED DEFAULT 0 COMMENT 'related mailing, references mailing_tbl',
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	PRIMARY KEY (dyn_content_id),
	KEY dyn_content$dyn_name_id$idx (dyn_name_id),
	KEY dyn_content_tbl$mlidciod$idx (mailing_id, company_id),
	KEY dyn_content_tbl$targetid$idx (target_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores different text contents for text - blocks';

CREATE TABLE dyn_name_tbl (
	dyn_name_id                INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use dyn_name_tbl_seq',
	dyn_name                   VARCHAR(100) COMMENT 'name like found in agnDYN name=XXX tag',
	mailing_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'related mailing, references mailing_tbl',
	company_id                INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	dyn_group                  INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'group of this tag. Groups are a feature of dynamic content, which allows the contents to be grouped together when displaying them in the content list',
	interest_group             VARCHAR(50) COMMENT 'to order blocks by interest, see customer_field_tbl.isinterest',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entrylast change',
	deleted                    INT(11) NOT NULL DEFAULT 0 COMMENT '1=yes',
	deletion_date              TIMESTAMP NULL COMMENT 'deletion date',
	no_link_extension          INTEGER(1) COMMENT 'Flag to disable extending links (SAAS-1250)',
	PRIMARY KEY (dyn_name_id),
	UNIQUE KEY dyn_name_tbl$dyn_name_id$idx (dyn_name_id),
	KEY mailing_id (mailing_id),
	KEY dyn_name_tbl$mailingid$idx (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores names of text - blocks, contents in DYN_CONTENT_TBL';

CREATE TABLE dyn_target_tbl (
	target_id                  INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use dyn_target_tbl_seq',
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	mailinglist_id             INT(10) UNSIGNED DEFAULT 0 COMMENT 'related mailinglist, references mailinglist_tbl',
	target_shortname           VARCHAR(100) NOT NULL DEFAULT '' COMMENT 'targetgroup name',
	target_sql                 TEXT COMMENT 'sql - representation of targetgroup definition',
	target_description         TEXT COMMENT 'comment on targetgroup',
	target_representation      LONGBLOB COMMENT 'EMM graphic- representation of targetgroup definition',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1 = targetgroup is deleted',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'targetgroup last change',
	creation_date              TIMESTAMP NULL COMMENT 'targetgroup creation date',
	admin_test_delivery        INT(11) NOT NULL DEFAULT 0 COMMENT '1 = targetgroup is used for test and / or admin delivery',
	locked                     INT(1) DEFAULT 0 COMMENT '1 = any changes only via DB possible',
	component_hide             INT(1) DEFAULT 0 COMMENT '1 = target group cant be used for components',
	eql                        LONGTEXT COMMENT 'eql - representation of targetgroup definition',
	invalid                    INTEGER COMMENT '1=invalid target_group (might e.g. happen while switching between definition modes in EMM in older versions)',
	hidden                     INTEGER COMMENT '1 for hidden target groups like listsplit-definitions',
	PRIMARY KEY (target_id),
	KEY dyn_target_tbl$coid$idx (company_id),
	KEY dyn_target_tbl$targetid$idx (target_id)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores target group information';

CREATE TABLE emm_db_errorlog_tbl (
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	errortext                  VARCHAR(4000) COMMENT 'catched SQL - Error',
	module_name                VARCHAR(200) COMMENT 'Name of e.g. the trigger who caused an error',
	client_info                VARCHAR(500) COMMENT 'OS user and client causing the error',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'backend monitoring and error-handling espc. for triggers, catches errors during trigger execution, monitored by backend-script on AGN-Instances';

CREATE TABLE emm_layout_base_tbl (
	layout_base_id             INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use emm_layout_base_tbl_seq',
	base_url                   VARCHAR(200) DEFAULT 'assets/core' COMMENT 'URL where the layout definition is located',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'entry last change',
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl), use 0 for all',
	shortname                  VARCHAR(200) COMMENT 'layout name',
	menu_position              INT(11) DEFAULT 0 COMMENT 'defines position of sidemenu (left or top), default is left',
	livepreview_position       INT(11) DEFAULT 0 COMMENT 'defines the position of live preview (0 = right, 1= bottom, 2 = deactivated)',
	layoutdirectory            VARCHAR(32),
	domain                     VARCHAR(32),
	PRIMARY KEY (layout_base_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'used for whitelabel settings in EMM';

CREATE TABLE export_predef_tbl (
	export_predef_id           INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use export_predef_tbl_seq',
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	charset                    VARCHAR(200) DEFAULT '' COMMENT 'charset used in export-file',
	columns                    TEXT COMMENT 'list of export-columns',
	mailinglists               TEXT COMMENT 'list of mailinglists to export',
	delimiter_char             CHAR(1) DEFAULT '0' COMMENT '(field)delimiter used in export-file',
	separator_char             CHAR(1) DEFAULT '0'COMMENT 'separator used in export-file',
	target_id                  INT(11) DEFAULT 0 COMMENT 'target-ID to filter recipients to export',
	user_status                INT(11) DEFAULT 0 COMMENT 'user-status to filter recipients to export',
	user_type                  CHAR(1) DEFAULT '0' COMMENT 'user-status to filter recipients to export',
	shortname                  TEXT COMMENT 'entrys name',
	description                TEXT COMMENT 'comment on entry',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1 = YES',
	mailinglist_id             INT(11) DEFAULT 0 COMMENT 'legacy?',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	timestamp_start            TIMESTAMP NULL COMMENT 'if set: filter recipients to export by last profile-change: FROM',
	timestamp_end              TIMESTAMP NULL COMMENT 'if set: filter recipients to export by last profile-change: TO',
	creation_date_start        TIMESTAMP NULL COMMENT 'if set: filter recipients to export by profile-creation-date: FROM',
	creation_date_end          TIMESTAMP NULL COMMENT 'if set: filter recipients to export by profile-creation-date: TO',
	mailinglist_bind_start     TIMESTAMP NULL COMMENT 'if set: filter recipients to export by last binding-change: FROM',
	mailinglist_bind_end       TIMESTAMP NULL COMMENT 'if set: filter recipients to export by last binding-change: TO',
	timestamp_lastdays         INTEGER COMMENT 'if set: filter recipients to export by last profile-change: PERIOD (in days)',
	creation_date_lastdays     INTEGER COMMENT 'if set: filter recipients to export by profile-creationdate: PERIOD (in days)',
	mailinglist_bind_lastdays  INTEGER COMMENT 'if set: filter recipients to export by last binding-change: PERIOD (in days)',
	always_quote               INTEGER DEFAULT 0 COMMENT 'Always use delimiter_char for quotation of strings in csv outout',
	PRIMARY KEY (export_predef_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores Templates for recipient-export';

CREATE TABLE followup_stat_result_tbl (
	result_id                  INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Reference key',
	company_id                 INT(11) COMMENT 'Referenced client',
	basemail_id                INT(11) COMMENT 'Base mailing of this follow up mailing',
	followup_id                INT(11) COMMENT 'Referenced followup mailing',
	creation_date              TIMESTAMP NOT NULL COMMENT 'Creation date of statistics entry',
	duration_time              INT(11) COMMENT 'Duration of statistics select',
	session_id                 VARCHAR(50) COMMENT 'Session id that startet the select',
	statement                  VARCHAR(4000) COMMENT 'Select sql',
	result_value               INT(11) COMMENT 'Resulting statistics value',
	PRIMARY KEY (result_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Asynchronous calculation of follow up mailing statistics';

CREATE TABLE import_column_mapping_tbl (
	id                         INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use import_column_mapping_tbl_seq',
	profile_id                 INT(10) UNSIGNED NOT NULL COMMENT 'references import_profile_tbl',
	file_column                VARCHAR(255) NULL COMMENT 'matching column in file',
	db_column                  VARCHAR(255) NOT NULL COMMENT 'matching column in databae, use "do-not-import-column" to ignore a column in file for this import',
	mandatory                  TINYINT(1) NOT NULL COMMENT '1 = NULL is not allowed for this column and this import',
	default_value              VARCHAR(255) DEFAULT '' COMMENT 'default (for this column and this import',
	creation_date              TIMESTAMP NULL COMMENT 'mapping creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'mapping last change',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1 = yes',
	encrypted                  INT(10) UNSIGNED DEFAULT 0 COMMENT '1 = yes',
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'settings saving a mapping on file columns to database-columns in an import-profile';

CREATE TABLE import_gender_mapping_tbl (
	id                         INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'mapping last change',
	profile_id                 INT(10) UNSIGNED NOT NULL COMMENT 'references import_profile_tbl',
	int_gender                 INT(10) UNSIGNED NOT NULL COMMENT 'gender like used in import file',
	string_gender              VARCHAR(100) NOT NULL COMMENT '0-male, 1-female, 2-unknown, 5-company',
	creation_date              TIMESTAMP NULL COMMENT 'mapping creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'mapping last change',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1 = yes',
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'settings saving a mapping on gender-values (like m/Mr. ...) to agn-code (0, 1, 2 ...) in an import-profile';

CREATE TABLE import_log_tbl (
	log_id                     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use import_log_tbl_seq',
	company_id                 INT(10) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	admin_id                   INT(10) UNSIGNED NOT NULL COMMENT 'references EMM-User (admin_tbl)',
	imported_lines             INT(10) UNSIGNED NOT NULL COMMENT 'number of handeled lines in file',
	datasource_id              INT(10) UNSIGNED NOT NULL COMMENT 'unique source-ID (datasource_description_tbl)',
	statistics                 TEXT NOT NULL COMMENT 'statistics itself',
	profile                    TEXT NOT NULL COMMENT 'used profile -settings',
	creation_date              TIMESTAMP NULL COMMENT 'log creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'log last change',
	PRIMARY KEY (log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'logs (profile-) import statistics';

CREATE TABLE import_profile_tbl (
	id                         INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use import_profile_tbl_seq',
	company_id                 INT(10) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	admin_id                   INT(10) UNSIGNED NOT NULL COMMENT 'references EMM-User (admin_tbl)',
	shortname                  VARCHAR(255) NOT NULL COMMENT 'profile name',
	column_separator           INT(10) UNSIGNED NOT NULL COMMENT 'seperator used in import-file',
	text_delimiter             INT(10) UNSIGNED NOT NULL COMMENT 'delimiter used in import-file',
	file_charset               INT(10) UNSIGNED NOT NULL COMMENT 'charset used in import-file',
	date_format                INT(10) UNSIGNED NOT NULL COMMENT 'date format used in import-file',
	import_mode                INT(10) UNSIGNED NOT NULL COMMENT '0=add, 1=add+update, 2=update only, 3=unsubscribe(profile only), 4=bounce(profile only), 5=blacklist(profile only), 6=bouncereactivate(profile only)',
	null_values_action         INT(10) UNSIGNED NOT NULL COMMENT '0 = dont_ignore_null_values, 1 = ignore_null_values',
	key_column                 VARCHAR(255) NOT NULL COMMENT 'import keycolumn',
	report_email               VARCHAR(255) COMMENT '[private_data] report recipient adress(es)',
	check_for_duplicates       INT(10) UNSIGNED NOT NULL COMMENT '0 = csv only, 1 = full, 2 = none',
	mail_type                  INT(10) UNSIGNED NOT NULL COMMENT 'updates customer_xxx_tbl.mailtype: 0-text, 1-html, 2-offline-html',
	creation_date              TIMESTAMP NULL COMMENT 'import-profile creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'import-profile last change',
	update_all_duplicates      DECIMAL(1, 0) DEFAULT 0 COMMENT '1=all matches in customer_xxx_tbl would be updated',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1 = yes',
	pre_import_action          INTEGER COMMENT 'Reference to import_action_tbl for sql scripts to execute before import of data',
	decimal_separator          VARCHAR(1) DEFAULT '.' COMMENT 'Separator "." or "," for decimals',
	action_for_new_recipients  INT(11) COMMENT 'DOI action for change of new customers after import',
	noheaders                  INT(1) DEFAULT 0 COMMENT 'No Header option for csv files',
	zip                        INT(1) DEFAULT 0 COMMENT 'Zip file option for import csv files in zip format',
	zip_password_encr          VARCHAR(100) COMMENT 'Optional password for csv import zip files',
	error_email                VARCHAR(400) COMMENT 'List of email addresses to inform on errorneous imports',
	automapping                INTEGER COMMENT 'Use all csv columns as db column, exactly name by name',
	PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'profile-import parameters';

CREATE TABLE import_temporary_tables (
	session_id                 VARCHAR(255) COMMENT 'creating session',
	temporary_table_name       VARCHAR(255) COMMENT 'name of created table',
	host                       VARCHAR(128) COMMENT 'running host (also used to clean up after hostswitch / restart)',
	import_table_name          VARCHAR(255),
	description                VARCHAR(255),
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores temporary_tables used in a certain session to run imports, also used to lock import in order to prevent rival accesses';

CREATE TABLE job_queue_parameter_tbl (
	job_id                     INT(11) NOT NULL AUTO_INCREMENT COMMENT 'references job (job_queue_tbl.id)',
	parameter_name             VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'parameter name, e.g. companyID or tmpFolder',
	parameter_value            VARCHAR(128) NOT NULL DEFAULT '' COMMENT 'matching parameter value',
	KEY job_id (job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores additional details for job';

CREATE TABLE job_queue_tbl (
	id                         INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique job ID',
	description                VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'comment on entry',
	created                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	lastStart                  TIMESTAMP NULL COMMENT 'timestamp when last run started',
	running                    INT(1) DEFAULT 0 COMMENT '0 = no, 1 = yes',
	lastresult                 VARCHAR(512) COMMENT 'last result: OK or Error details',
	startAfterError            INT(1) DEFAULT 0 COMMENT '1=yes, try again, 0=no, wait to correct',
	lastDuration               INT(10) DEFAULT 0 COMMENT 'time for last run in sec',
	`interval`                 VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'time (of the day) and / or day and / or intervall',
	nextstart                  TIMESTAMP NULL COMMENT 'next execution is sheduled for this time',
	hostname                   VARCHAR(64) COMMENT 'host to run this job on - wont be executed on other hosts with a running EMM - applikation',
	runClass                   VARCHAR(128) DEFAULT '' COMMENT 'java class to be executed',
	runOnlyOnHosts             VARCHAR(64) COMMENT 'restrictes allowed hosts for hostname',
	emailOnError               VARCHAR(64) COMMENT '[private_data] email - recipient for and error-reports',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1 = yes',
	job_comment                VARCHAR(500) COMMENT 'Comment for job worker',
	PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores details and running details for automated jobs - should be monitored external!';
CREATE UNIQUE INDEX jobqueue$description$unique ON job_queue_tbl (description);

CREATE TABLE login_track_tbl (
	login_track_id             INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use login_track_tbl_seq',
	ip_address                 VARCHAR(20) COMMENT '[secret_data] address where login-request came from',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'login-request timestamp',
	login_status               INT(11) COMMENT '10 = successfull, 20 = failed, 40 = successfull but while IP is locked',
	username                   VARCHAR(200) COMMENT '[secret_data] emm-user name used in request',
	PRIMARY KEY (login_track_id),
	KEY logtrck$ip_cdate_stat$idx (ip_address, creation_date, login_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[secret_data] any login-request, successfull or not, is stored here (for a certain time)';

CREATE TABLE login_whitelist_tbl (
	ip_address                 VARCHAR(20) NOT NULL COMMENT '[secret_data] IP to whitelist',
	description                VARCHAR(200) NOT NULL COMMENT 'reason to whitelist'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[secret_data] listed Adresses will never get Login locked';

CREATE TABLE maildrop_status_tbl (
	gendate                    TIMESTAMP NULL COMMENT 'timestamp to start generation',
	genstatus                  INT(1) COMMENT '0=to be done, not started yet, 1=ready to start (generation starts with this value only), 2=generation in progress, 3=done, 4=problem was solved manually (genstatus of T- and W-mailings will be set from 0 to 1 by backend code, if gendate < CURRENT_TIMESTAMP)',
	genchange                  TIMESTAMP NULL COMMENT 'last change-timestamp for genstatus (used for monitoring issues)',
	blocksize                  INT(11) COMMENT 'max recipients per generated block',
	status_id                  INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use maildrop_status_tbl_seq',
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	status_field               VARCHAR(10) NOT NULL DEFAULT '' COMMENT 'A=Admin, T=Test, W= World, E=Event (action), R=Rule (date) (C, X - deprecated), V=Verification',
	mailing_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'references mailing (mailing_tbl)',
	senddate                   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'timestamp to send out mailing',
	step                       INT(11) COMMENT 'timeintervall (in min) between sending 2 blocks',
	max_recipients             INT(11) COMMENT 'limit recipients to this value, if NOT NULL AND >0 during mail generation',
	admin_test_target_id       INT(11) COMMENT 'This is an optional reference to dyn_target_tbl.target_id for admin and test mailings to restrict the recipients',
	optimize_mail_generation   VARCHAR(32) COMMENT 'NULL=none, day=optimized for current day, 24h=optimized for next 24h',
	selected_test_recipients   INT(1) COMMENT 'If set to 1, then the recipients for a test mailing are selected from test_recipients_tbl',
	PRIMARY KEY (status_id),
	KEY mstat$mailing_id$idx (mailing_id),
	KEY mstat$senddate$idx (senddate),
	KEY mstat$status_field$idx (status_field)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE INDEX mstat$coid$idx ON maildrop_status_tbl (company_id) COMMENT 'process-tbl for handling sending and generation of mailings';

CREATE TABLE mailing_account_sum_tbl (
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	mailing_id                 INT(11) COMMENT 'references mailing (mailing_tbl.mailing_id)',
	status_field               VARCHAR(100) COMMENT 'A=Admin, T=Test, W= Wolrd, E=Event, R=rule-based, V=predelivery-test, D=onDemand (C, X - deprecated)',
	no_of_mailings             INT(11) COMMENT 'sum of sended mailings (yet)',
	no_of_bytes                BIGINT(11) COMMENT 'sum of sended bytes (yet)',
	mintime                    TIMESTAMP NULL COMMENT 'min sending timestamp',
	maxtime                    TIMESTAMP NULL COMMENT 'last sending timestamp',
	UNIQUE KEY maccsum$mid_sf$uq (mailing_id, status_field),
	KEY maccsum$coid$idx (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'summary of mailing sending informations, filled by trigger on mailing_account_tbl';

CREATE TABLE mailing_account_tbl (
	mailing_account_id         INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, mailing_account_tbl_seq',
	mailer                     VARCHAR(30) NOT NULL DEFAULT '' COMMENT 'name of (package-) processing mailer',
	mailing_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'references mailing (mailing_tbl)',
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	mailinglist_id             INT(11) NOT NULL DEFAULT 0 COMMENT 'references mailinglist (mailinglist_tbl)',
	mailtype                   INT(11) NOT NULL DEFAULT 0 COMMENT '0-text, 1-html, 2-offline-html (from recipient settings)',
	no_of_mailings             INT(11) NOT NULL DEFAULT 0 COMMENT 'number of mailings sent (within this package)',
	no_of_bytes                INT(11) NOT NULL DEFAULT 0 COMMENT 'number of bytes (within this package)',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'entry creation / last change',
	maildrop_id                INT(11) NOT NULL DEFAULT 0 COMMENT 'references maildrop-status-entry (maildrop_status_tbl)',
	status_field               VARCHAR(10) NOT NULL DEFAULT '' COMMENT 'A=Admin, T=Test, W= Wolrd, E=Event, R=rule-based, V=predelivery-test, D=onDemand (C, X - deprecated)',
	blocknr                    INT(11) COMMENT 'XML-block number',
	mediatype                  INT(11) NOT NULL DEFAULT 0 COMMENT '0 = Email, 1 = Fax, 2 = Print, 3 = MMS, 4 = SMS(from recipient-binding settings)',
	PRIMARY KEY (mailing_account_id),
	KEY macc$mid_noofml$idx (mailing_id, no_of_mailings),
	KEY macc$mid_nofml_stat$idx (mailing_id, no_of_mailings, status_field),
	KEY macc$tmst$idx (timestamp),
	KEY mailingacc$maildropid$idx (maildrop_id),
	KEY mailing_acc$coid_mid_mdid$idx (company_id, mailing_id, maildrop_id),
	KEY mailing_acc$mltp_nofm$idx (mailtype, no_of_mailings)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'logs detailinformation about sending-process';

CREATE TABLE mailing_backend_log_tbl (
	mailing_id                 INT(10) NOT NULL COMMENT 'references mailing (mailing_tbl)',
	current_mails              INT(10) COMMENT 'number of mailings alread generated',
	total_mails                INT(10) COMMENT 'number of mailings to generate',
	status_id                  INT(10) COMMENT 'references maildrop_status_tbl.status_id',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	creation_date              TIMESTAMP NOT NULL COMMENT 'entry creation date'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'mailing-generation process-tbl';

CREATE TABLE mailing_info_tbl (
	mailing_info_id            INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use mailing_info_tbl_seq',
	mailing_id                 INT(11) COMMENT 'references Mailing (mailing_tbl.mailing_id)',
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	name                       VARCHAR(200) COMMENT 'parameter name',
	value                      VARCHAR(4000) COMMENT 'parameter value',
	description                VARCHAR(500) COMMENT 'comment on entry',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	creation_admin_id          INT(11) COMMENT 'references creating EMM-User (admin_tbl)',
	change_admin_id            INT(11) COMMENT 'references changing EMM-User (admin_tbl)',
	PRIMARY KEY (mailing_info_id),
	KEY mainfo$mid$idx (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores mailing-parameters';

CREATE TABLE mailing_tbl (
	archived                   INT(11) UNSIGNED DEFAULT 0 COMMENT '1 = yes, mailing in online - archive',
	is_template                INT(10) UNSIGNED DEFAULT 0 COMMENT '1 = this is a template, 0 = this is a mailing',
	target_expression          VARCHAR(1000) COMMENT '(combination of) Target-ID(s)',
	split_id                   INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'listsplit - TargetID',
	needs_target               INT(1) UNSIGNED DEFAULT 0 COMMENT '1 = targetgroup is mandatory',
	mailing_id                 INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use mailing_tbl_seq',
	mailtemplate_id            INT(10) UNSIGNED DEFAULT 0 COMMENT 'template used for mailing creation (parent reference)',
	mailinglist_id             INT(10) UNSIGNED DEFAULT 0 COMMENT 'references mailinglist (mailinglist_tbl)',
	description                TEXT COMMENT 'comment on mailing',
	shortname                  VARCHAR(200) DEFAULT '' COMMENT 'mailing name',
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	xor_key                    INT(10) UNSIGNED DEFAULT 0 COMMENT 'key - value to encode mensurable links',
	auto_url                   VARCHAR(200) COMMENT 'basic link URL (from mailinglist-settings)',
	mailing_type               INT(10) UNSIGNED DEFAULT 0 COMMENT '0=world-mailing, 1=event-based, 3=rule-based, 4=follow up',
	action_id                  INT(10) UNSIGNED DEFAULT 0 COMMENT 'legacy PROJ-711',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1=yes, not shown in EMM, 0=no',
	campaign_id                INT(11) UNSIGNED DEFAULT 0 COMMENT 'Archive this mailing belongs to',
	test_lock                  INT(11) UNSIGNED DEFAULT 0 COMMENT 'locked during test-sending in order to avoid cascade-effects',
	work_status                VARCHAR(80) COMMENT 'e.g.: mailing.status.scheduled, mailing.status.new, mailing.status.sent',
	statmail_recp              VARCHAR(512) COMMENT 'recipient-address for mailing statistics',
	unique_link_count          INT(11) UNSIGNED DEFAULT 0 COMMENT 'number of unique links used in mailing',
	creation_date              TIMESTAMP NULL COMMENT 'mailing creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'mailing last change',
	cms_has_classic_content    INT(1) DEFAULT 0 COMMENT 'compatibility mode',
	trackable_link_extension   VARCHAR(1024) COMMENT 'link-extension parameter(s)',
	dynamic_template           INT(11) COMMENT '1 = yes(for templates: modifications of this template will be published to mailings, for mailings: published template modifications will be adapted), 0/NULL = no/off',
	openaction_id              INT(11) DEFAULT 0 COMMENT 'references action to execute if mailing is opened, e.g. to count up a recipient profile field (interest counter)',
	clickaction_id             INT(11) DEFAULT 0 COMMENT 'references action to execute if mailing is clicked',
	delivered                  INT(11) COMMENT 'number of sent mailings, aviable after sending',
	plan_date                  DATETIME COMMENT 'send date (for later sendings)',
	priority                   INTEGER COMMENT 'priority for a template, 0/NULL no priority set, otherwise the higher the number, the higher is the priority',
	content_type               VARCHAR(20) COMMENT 'Content type description for this mailing. Allowed values transaction or advertising',
	is_text_version_required   TINYINT(1) DEFAULT 1 NOT NULL COMMENT 'If set to 1, mailing must have a text version (otherwise it cannot be sent, see GWUA-3991)',
	is_prioritization_allowed  TINYINT(1) DEFAULT 1 NOT NULL COMMENT 'If set to 1, then prioritization for this mailing will be applied see mailing priority for more details',
	PRIMARY KEY (mailing_id),
	KEY mailingtbl$mlid$idx (mailinglist_id),
	KEY mailing_tbl$mid_mlid$idx (mailing_id, mailinglist_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores mailing meta-data';
CREATE INDEX mailing$coid$mid$mtype$del$idx ON mailing_tbl (company_id, mailing_id, mailing_type, deleted);

CREATE TABLE mailing_mt_tbl (
	mailing_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'references mailing (mailing_tbl)',
	mediatype                  INT(10) UNSIGNED DEFAULT 0 COMMENT '0 = Email, 1 = Fax, 2 = Print, 3 = MMS, 4 = SMS',
	priority                   INT(10) UNSIGNED DEFAULT 0 COMMENT 'ranking, if there is more than one entry per mailing',
	status                     INT(10) UNSIGNED DEFAULT 0 COMMENT '0=not used, 1=not active, 2=active',
	param                      TEXT COMMENT '[private_data] list of parameters',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	KEY mailing_id (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[private_data] contains mailing parameters per mediatype - e.g. subject, sender-address etc.';

CREATE TABLE mailinglist_tbl (
	mailinglist_id             INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, mailinglist_tbl_seq',
	company_id                 INT(10) UNSIGNED COMMENT 'tenant - ID (company_tbl)',
	description                TEXT COMMENT 'comment on mailinglist',
	shortname                  VARCHAR(100) NOT NULL DEFAULT '' COMMENT 'mailinglist name',
	auto_url                   VARCHAR(200) COMMENT 'legacy',
	remove_data                INT(10) DEFAULT 0 COMMENT 'legacy?',
	rdir_domain                VARCHAR(200) COMMENT '(default) ridir domain for this mailinglist, overwrites company_id.rdir_domain, if NOT NULL',
	creation_date              TIMESTAMP NULL COMMENT 'mailinglist creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP COMMENT 'mailinglist last change',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '1=yes',
	binding_clean              INT(1) DEFAULT 0 COMMENT 'Flag for nightly cleaning of bindings 1=on, 0=off',
	PRIMARY KEY (mailinglist_id),
	KEY mailinglist$coid$idx (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores mailinglists';

CREATE TABLE mailloop_rule_tbl (
	rid                        INT(11) NOT NULL COMMENT 'This rule is added for the filter mailloop_tbl.rid',
	section                    VARCHAR(32) NOT NULL COMMENT 'This is the target section (systemmail, filter, hard, soft)',
	pattern                    VARCHAR(256) NOT NULL COMMENT 'The pattern as a regular expression to be checked against incoming mails'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Adding rules for the filter (mailloop) service to assign a pattern to a section for a specific filter definition';

CREATE TABLE mailloop_tbl (
	rid                        INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use mailloop_tbl_seq',
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	forward                    VARCHAR(128) DEFAULT '' COMMENT '[private_data] EMailaddress where all not filtered mails would be forwarded',
	ar_sender                  VARCHAR(200) DEFAULT '' COMMENT '[private_data] autoresponder: sender-address',
	ar_subject                 TEXT COMMENT 'autoresponder: Subject (if not set: Re: <incomming subject>)',
	ar_text                    LONGTEXT COMMENT 'autoresponder: text-content',
	ar_html                    LONGTEXT COMMENT 'autoresponder: html-content (optional)',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	ar_enable                  INT(10) UNSIGNED DEFAULT 0 COMMENT 'autoresponder is active, if this value is <>0',
	forward_enable             INT(10) UNSIGNED DEFAULT 0 COMMENT 'forwarding is active, if this value is <>0',
	shortname                  VARCHAR(200) NOT NULL DEFAULT '' COMMENT 'entrys name',
	description                TEXT COMMENT 'entrys name' COMMENT 'comment on entry',
	filter_address             VARCHAR(128) DEFAULT '' COMMENT '[private_data] ',
	subscribe_enable           INT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '1 = opt in by email is active',
	mailinglist_id             INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'mailinglistID used for opt in by email',
	form_id                    INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'form_ID (references user_form_tbl) used for double opt in, 0 = none',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	spam_required              INT(11) COMMENT '1 = yes',
	spam_email                 VARCHAR(200) COMMENT '[private_data]',
	spam_forward               INT(11) COMMENT '1 = yes',
	autoresponder_mailing_id   INT(10) UNSIGNED COMMENT 'Mailing_ID (references mailing_tbl) used as autoresponder',
	security_token             VARCHAR(100) COMMENT '[secret_data]',
	PRIMARY KEY (rid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[private_data] stores Mailloop-data';

CREATE TABLE mailtrack_1_tbl (
	maildrop_status_id         INT(10) COMMENT 'references maildrop_status_tbl.status_id',
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'references recipient (customer_xxx_tbl.customer_id)',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'sending timestamp',
	mailing_id                 INT(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '(automation-package) stores sended mailings per recipient, would be deleted after a period (see company_info_tbl), filled during mailGENERATION, so stopping a mailing later (while sending e.g.) has entries for all recipients anyway!';
CREATE INDEX mailtr1$cid$idx ON mailtrack_1_tbl (customer_id);
CREATE INDEX mailtr1$mdrstatid$idx ON mailtrack_1_tbl (maildrop_status_id);

CREATE TABLE onepixellog_1_tbl (
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'references recipient (customer_xxx_tbl.customer_id)',
	mailing_id                 INT(10) NOT NULL COMMENT 'references mailing (mailing_tbl.mailing_id)',
	company_id                 INT(10) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	ip_adr                     VARCHAR(15) NOT NULL COMMENT 'IP where the opening came from',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(last) open timestamp',
	open_count                 INT(10) COMMENT 'sum of all openings (per mailing, per recipient)',
	mobile_count               INT(11) COMMENT 'sum of all mobile openings (per mailing, per recipient)',
	first_open                 TIMESTAMP NULL COMMENT 'First time this customer opened the defined mailing',
	last_open                  TIMESTAMP NULL COMMENT 'Last time this customer opened the defined mailing',
	KEY onpx1$coid_mlid_cuid$idx (company_id, mailing_id, customer_id),
	KEY onpx1$mid$idx (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores opening-data';

CREATE TABLE onepixellog_device_1_tbl (
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	mailing_id                 INT(11) NOT NULL COMMENT 'references mailing (mailing_tbl.mailing_id)',
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'references recipient (customer_xxx_tbl.customer_id)',
	device_id                  INT(11) COMMENT 'specifies matched device (references device_tbl.device_id)',
	creation                   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'opening timesstamp = entry creation date',
	device_class_id            INT(2) COMMENT 'specifies matched device-class: 1=DESKTOP, 2=MOBILE, 3=TABLET, 4=SMARTTV, references deviceclass_tbl.id',
	client_id                  INTEGER COMMENT 'Client id of client_tbl for the software which was used to open a mailing'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'one entry per registered opening, cleaned up regulary (default: 1000d)';
CREATE INDEX onepixdev1$mlid_cuid$idx ON onepixellog_device_1_tbl (mailing_id, customer_id);
CREATE INDEX onedev1$ciddevclidmlid$idx ON onepixellog_device_1_tbl (customer_id, device_class_id, mailing_id);
CREATE INDEX onedev1$creat$idx ON onepixellog_device_1_tbl (creation);

CREATE TABLE plugins_tbl (
	plugin_id                  VARCHAR(100) NOT NULL COMMENT 'plugin ID',
	activate_on_startup        INT(1) NOT NULL DEFAULT 0 COMMENT '0 = not activated on startUp, 1 = activated',
	PRIMARY KEY (plugin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'defines / lists plugins which should be activated on EMM - startUP (or not)';

CREATE TABLE rdir_action_tbl (
	action_id                  INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use rdir_action_tbl_seq',
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	shortname                  VARCHAR(50) NOT NULL DEFAULT '' COMMENT 'action name',
	description                VARCHAR(1000) NOT NULL DEFAULT '' COMMENT 'comment on action',
	action_type                INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'defines action usage: 0=link only, 1=form only, 9=all',
	creation_date              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'action creation date',
	action_sql                 VARCHAR(500) COMMENT 'legacy',
	change_date                TIMESTAMP NULL COMMENT 'action last change',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '0=no, 1=yes',
	active                     INT(1) NOT NULL DEFAULT 1 COMMENT 'If set to 0, then the action should not be available for using by forms and mailings',
	PRIMARY KEY (action_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores actions';

CREATE TABLE rdir_url_param_tbl (
	url_id                     INT(10) UNSIGNED COMMENT 'references link (rdir_url_tbl.url_id)',
	param_type                 VARCHAR(32) COMMENT 'type,  e.g. LinkExtension',
	param_key                  VARCHAR(32) COMMENT 'key added to the link',
	param_value                VARCHAR(2000) COMMENT 'value for this key',
	KEY fk_rdir_url_param_id (URL_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores data for link parameters. e.g. LinkExtensions';
CREATE INDEX urlparam$urlid$idx ON rdir_url_param_tbl (url_id);

CREATE TABLE rdir_url_tbl (
	deep_tracking              INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=not active, 1=using Cookie, 2=using URL-parameter, 3=using Cookie AND URL-parameter',
	relevance                  INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'relevance for statistics: 0=complete, 1=not for Click-summary, 2=not considered',
	url_id                     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use rdir_url_tbl_seq',
	full_url                   TEXT NOT NULL COMMENT 'complete URL',
	mailing_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'references mailing (mailing_tbl.mailing_id)',
	company_id                 INT(10) UNSIGNED COMMENT 'tenant - ID (company_tbl)',
	mailingtemplate_id         INT(10) UNSIGNED COMMENT 'legacy?',
	`usage`                    INT(10) COMMENT '0=not mesurable, 1=text-version only, 2=html-version only, 3=always',
	action_id                  INT(10) UNSIGNED COMMENT 'references action (executed on click) (rdir_action_tbl.action_id)',
	shortname                  VARCHAR(1000) COMMENT 'url-name',
	alt_text                   VARCHAR(200) COMMENT 'shown alternative Text for a link in statistic',
	creation_date              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	extend_url                 INT(10) NOT NULL DEFAULT 0 COMMENT 'additional parameters (mailing_tbl.trackable_link_extension)',
	admin_link                 INT(11) DEFAULT 0 COMMENT '0=no, 1=yes - set e.g. for fullview - links or other administrative links',
	from_mailing               INT(11) COMMENT 'If this is 1, then the URL had been added from the mailing content, otherwise a 3rd party process had added this and should not be removed',
	deleted                    INT(1) NOT NULL DEFAULT 0 COMMENT '0=no, 1=yes',
	original_url               VARCHAR(2000) COMMENT 'If the full_url has modified after sending the original URL is stored here for reference',
	static_value               INT(1) COMMENT 'If this value is 1 then the current value of referenced database columns are passed for redirect requests',
	PRIMARY KEY (url_id),
	KEY rdir_url$coid_mid$idx (company_id, mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores links in mailings';
CREATE INDEX rdir_url$rlv_coid_mid$idx ON rdir_url_tbl (relevance, company_id, mailing_id);

CREATE TABLE rdir_url_userform_param_tbl (
	url_id                     INT(11) COMMENT 'references link (rdir_url_tbl.url_id)',
	param_type                 VARCHAR(32) COMMENT 'type,  e.g. LinkExtension',
	param_key                  VARCHAR(32) COMMENT 'key added to the link',
	param_value                VARCHAR(2000) COMMENT 'value for this key',
	KEY fk_rdir_url_userform_param_id (URL_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores data for form parameters. e.g. LinkExtensions';

CREATE TABLE rdir_url_userform_tbl (
	url_id                     INT(11) NOT NULL AUTO_INCREMENT COMMENT 'PK, use RDIR_URL_USERFORM_TBL_SEQ',
	full_url                   VARCHAR(2000) NOT NULL COMMENT 'complete URL used',
	form_id                    INT(11) NOT NULL COMMENT 'refernces Form (userform_tbl)',
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	`usage`                    INT(11) COMMENT 'Whether this link is used in the userform or kept vfor historic reasons',
	action_id                  INT(11) COMMENT 'refernces called action',
	shortname                  VARCHAR(1000) COMMENT 'name of this entry',
	deep_tracking              INT(11) DEFAULT 0 COMMENT '1=enabled',
	relevance                  INT(11) DEFAULT 0 COMMENT 'relevance for statistics: 0=complete, 1=not for Click-summary, 2=not considered',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	PRIMARY KEY (url_id),
	KEY rdir_userform_url$coid_mid$idx (company_id, form_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores form details';

CREATE TABLE rdirlog_1_tbl (
	customer_id                INTEGER UNSIGNED COMMENT 'references recipient (customer_xxx_tbl.customer_id)',
	url_id                     INT(10) COMMENT 'references url (rdir_url_tbl.url_id)',
	company_id                 INT(10) COMMENT 'tenant - ID (company_tbl)',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'click timestamp',
	ip_adr                     VARCHAR(15) NOT NULL COMMENT 'IP where the click came from',
	mailing_id                 INT(10) COMMENT'references mailing (mailing_tbl.mailing_id)',
	device_id                  INT(11) COMMENT 'references device (device_tbl.device_id)',
	device_class_id            INT(2) COMMENT '1=DESKTOP, 2=MOBILE, 3=TABLET, 4=SMARTTV',
	client_id                  INTEGER
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores click-data';
CREATE INDEX rlog1$mid_urlid_cuid$idx ON rdirlog_1_tbl (mailing_id, url_id, customer_id);
CREATE INDEX rlog1$ciddevclidmlid$idx ON rdirlog_1_tbl (customer_id, device_class_id, mailing_id);
CREATE INDEX rlog1$tmst$idx ON rdirlog_1_tbl (timestamp);

CREATE TABLE rdirlog_1_val_num_tbl (
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	customer_id                INTEGER UNSIGNED COMMENT 'references recipient (customer_xxx_tbl.customer_id)',
	ip_adr                     VARCHAR(15) COMMENT 'IP where the trackingdata came from',
	mailing_id                 INT(11) COMMENT 'references mailing (mailing_tbl.mailing_id)',
	session_id                 INT(11) COMMENT 'cookie - sessionID',
	`timestamp` timestamp      DEFAULT CURRENT_TIMESTAMP COMMENT 'entry timestamp',
	num_parameter              DOUBLE COMMENT 'pageID for page-view data, sales volume for sales tracking ',
	page_tag                   VARCHAR(30) COMMENT 'revenue= shop sales tracking, page-view = retargeting (page view) data, more might be defined'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores (shop / website) tracking data';
CREATE INDEX rvalnum1$cod_cid_mid$idx ON rdirlog_1_val_num_tbl (company_id, customer_id, mailing_id);
CREATE INDEX rvalnum1$mid_pagetag$idx ON rdirlog_1_val_num_tbl (mailing_id, page_tag);

CREATE TABLE rdirlog_userform_1_tbl (
	form_id                    INT(11) COMMENT 'references form (userform_tbl.form_id)',
	customer_id                INTEGER UNSIGNED COMMENT 'references recipient (customer_xxx_tbl.customer_id)',
	url_id                     INT(11) COMMENT 'references url (rdir_url_tbl.url_id)',
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	ip_adr                     VARCHAR(15) COMMENT 'entry IP-address',
	mailing_id                 INT(11) COMMENT 'references mailing (mailing_tbl.mailing_id)',
	device_id                  INT(11) COMMENT 'references device (device_tbl.device_id)',
	device_class_id            INT(2) COMMENT '1=DESKTOP, 2=MOBILE, 3=TABLET, 4=SMARTTV',
	client_id                  INTEGER,
	KEY rlogform1$fid_urlid$idx (form_id, url_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'storing form-statistics';

CREATE TABLE rulebased_sent_tbl (
	mailing_id                 INT(11) NOT NULL COMMENT 'Mailing_ID (references mailing_tbl)',
	lastsent                   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'last sending timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores last sending time for any rule based mailing';

CREATE TABLE softbounce_email_tbl (
	email                      VARCHAR(200) NOT NULL DEFAULT '' COMMENT '[secret_data] bounced address',
	bnccnt                     INT(11) NOT NULL DEFAULT 0 COMMENT 'softbounce - counter (per adress, per mailing)',
	mailing_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'references mailing (mailing_tbl.mailing_id)',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'entry last change',
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	KEY email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[secret_data] proccess-tbl for (soft-)bounce-handling';

CREATE TABLE sourcegroup_tbl (
	sourcegroup_id             INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use sourcegroup_tbl_seq',
	sourcegroup_type           VARCHAR(2) NOT NULL COMMENT 'sourcegroup - code',
	description                VARCHAR(1000) NOT NULL COMMENT 'comment on sourcegroup',
	timestamp                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'sourcegroup last change',
	creation_date              TIMESTAMP NOT NULL COMMENT 'sourcegroup creation date',
	PRIMARY KEY (sourcegroup_id)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores groups for data-sources, e.g. file, DataAgent, ...';

CREATE TABLE swyn_click_tbl (
	network_id                 VARCHAR(20) COMMENT 'This is the content of the field "SOURCE" of the SWYN_TBL to identify the network from where the click came.',
	mailing_id                 INT(11) COMMENT 'references mailing (mailing_tbl.mailing_id)',
	customer_id                INTEGER UNSIGNED COMMENT 'references recipient who shared the newsletter (customer_xxx_tbl.customer_id)',
	ip_address                 VARCHAR(15) COMMENT 'The ip-address of the clicker',
	timestamp                  TIMESTAMP NULL COMMENT 'The timestamp of the click',
	selector                   VARCHAR(2000) COMMENT 'If the used anon.view is restricted to a part of the newsletter, this contains the selector used to limit the output of the content'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'This table records all clicks for displaying a shared newsletter on a network.';

CREATE TABLE swyn_tbl (
	swyn_id                    INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use swyn_tbl_seq',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	name                       VARCHAR(100) COMMENT 'The name for this entry as selectable by the [agnSWYN ...] parameter networks="...". Special names staring end ending with tow underscores. At the moment these special names are supported: "__prefix__", "__infix__", "__postfix__". These entries are used to build the frame for the output unless the parameter bare="true" is used in the agnSWYN tag',
	source                     VARCHAR(20) COMMENT 'A short ID for this network which is used to determinate the source of an anonymous click in the swyn_click_tbl.',
	charset                    VARCHAR(50) COMMENT 'The character set to be used to encode free text inserted in the target URL',
	ordering                   INT(11) COMMENT 'This is used to define an order within the display of the networks, if they are not explicit defined',
	image                      VARCHAR(80) COMMENT 'The name of the icon.',
	icon                       LONGBLOB COMMENT 'The icon graphic itself.',
	target                     VARCHAR(1000) COMMENT 'The URL to call for sharing a newsletter in a social network',
	code                       VARCHAR(2000) COMMENT 'The HTML code to be inserted in the newsletter using the agnSWYN tag',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	timestamp                  TIMESTAMP NULL COMMENT 'entry last change',
	isize                      VARCHAR(2000) COMMENT 'Defines the size of this icon with a symbolic name, which can be used as an optional parameter for [agnSWYN ...] as size="....". For the standard size, use the name "default" here',
	PRIMARY KEY (swyn_id)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'This table contains the data to be used for the [agnSWYN ...] tag (SWYN = share with your network). This information is used to build a HTML output to simply allow the recipient to share the newsletter via different networks. The link to share this newsletter as well as the icon to be displayed in the newsletter are stored herein';

CREATE TABLE tag_function_tbl (
	tag_function_id            INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use tag_function_tbl_seq',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	timestamp                  TIMESTAMP NULL COMMENT 'entry last change',
	name                       VARCHAR(128) NOT NULL COMMENT 'Name of the function',
	lang                       VARCHAR(32) NOT NULL COMMENT 'Language the function is written in',
	description                VARCHAR(1000) COMMENT 'comment on entry',
	code                       LONGTEXT COMMENT 'The function execution code',
	PRIMARY KEY (tag_function_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'This table contains the definitions for scripted tags.';

CREATE TABLE tag_tbl (
	tag_id                     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use tag_tbl_seq',
	tagname                    VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'tags name',
	selectvalue                TEXT NOT NULL COMMENT 'used in SQL request, provides tag - value (except: TYPE = FUNCTION)',
	type                       VARCHAR(10) NOT NULL DEFAULT '' COMMENT 'FUNCTION = script based, SIMPLEX = simple tag, COMPLEX=tag using parameters',
	company_id                 INT(10) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	description                TEXT COMMENT 'comment on tag',
	change_date                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'tag creation / last change date',
	PRIMARY KEY (tag_id)
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores / provides dynamic tags wich could be used in mailings';

CREATE TABLE timestamp_tbl (
	timestamp_id               INT(10) COMMENT 'unique ID, no sequence set, check max (id)',
	description                VARCHAR(250) COMMENT '[secret_data] comment (for the service using that entry!)',
	name                       VARCHAR(64) COMMENT '[secret_data] name (of the service using that entry!)',
	cur                        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'actuall run - timestamp of this service, set prev = cur at the end of any successfull run',
	prev                       TIMESTAMP NOT NULL COMMENT 'last run - timestamp of this service, set prev = cur at the end of any successfull run',
	temp                       TIMESTAMP NOT NULL COMMENT 'possibility to set another temp timestamp if needed'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'primary used for dataAgents, stores last run of a special service in order to provide diff - selections since last run';

CREATE TABLE title_gender_tbl (
	title_id                   INT(11) NOT NULL DEFAULT 0 COMMENT 'title-type (references title_tbl.title_id)',
	gender                     INT(11) NOT NULL DEFAULT 0 COMMENT 'gender as used in customer_xxx_tbl: 0-male, 1-female, 2-unknown, 5-company',
	title                      VARCHAR(150) NOT NULL DEFAULT '' COMMENT 'title value for this specific type and gender',
	PRIMARY KEY (title_id, gender)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores specific title values per (company and) title-type and gender';

CREATE TABLE title_tbl (
	title_id                   INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use title_tbl_seq',
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	description                VARCHAR(1000) NOT NULL DEFAULT '' COMMENT 'comment on title',
	PRIMARY KEY (title_id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'types for agnTITLE - tags which might be used in mailings';

CREATE TABLE trackpoint_def_tbl (
	company_id                 INT(10) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	pagetag                    VARCHAR(2000) NOT NULL COMMENT '(unique)trackpoint name (as used in trackpoint url)',
	mailing_id                 INT(10) NOT NULL DEFAULT 0 COMMENT 'references mailing (mailing_tbl.mailing_id)',
	action_id                  INT(10) NOT NULL DEFAULT 0 COMMENT 'references action (rdir_action_tbl.action_id) to be executed on trackpoint call',
	shortname                  VARCHAR(2000) COMMENT 'trackpoint shortname',
	description                VARCHAR(2000) COMMENT 'comment on trackpoint',
	type                       INT(10) COMMENT '0=simple, 1=numeric, 2=alpha numeric',
	currency                   VARCHAR(200) COMMENT '(optional) currency symbol',
	format                     INT(10) COMMENT 'numeric trackpoints only: 0=float, 1=integer',
	trackpoint_id              INT(22) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use trackpoint_def_tbl_seq',
	creation_date              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '',
	PRIMARY KEY (trackpoint_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores details on trackpoints';

CREATE TABLE undo_component_tbl (
	company_id                 INT(11) NOT NULL COMMENT 'Client reference',
	mailtemplate_id            INT(11) COMMENT 'Same as cmponent_tbl.mailtemplate_id',
	mailing_id                 INT(11) COMMENT 'Reference of mailing',
	component_id               INT(11) COMMENT 'Reference of component',
	mtype                      VARCHAR(100) COMMENT 'Same as cmponent_tbl.mtype',
	required                   INT(11) COMMENT 'Is component used in Mailing?',
	comptype                   INT(11) COMMENT 'Type of component',
	comppresent                INT(11) COMMENT 'Same as cmponent_tbl.comppresent',
	compname                   VARCHAR(1000) COMMENT 'Original component name',
	emmblock                   LONGTEXT COMMENT 'Original text data',
	binblock                   LONGBLOB COMMENT 'Original binary data',
	target_id                  INT(11) COMMENT 'Original targetgroup this component was configured for',
	timestamp                  TIMESTAMP NOT NULL COMMENT 'Change date of component',
	url_id                     INT(11) NOT NULL DEFAULT 0 COMMENT 'Referenced url for click on this component',
	undo_id                    INT(11) NOT NULL COMMENT 'Reference Key',
	KEY undocomponent$mid$idx (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'copies entries in component_tbl (plus undo - ID) to provide undo function, for column description see component_tbl';

CREATE TABLE undo_dyn_content_tbl (
	dyn_content_id             INT(11) COMMENT 'Original content id',
	dyn_name_id                INT(11) COMMENT 'Original content name',
	target_id                  INT(11) COMMENT 'Original targetgroup this content was configured for',
	dyn_order                  INT(11) COMMENT 'Original order of overlay contents to display',
	dyn_content                LONGTEXT COMMENT 'Original content text',
	mailing_id                 INT(11) COMMENT 'Referenced mailing',
	company_id                 INT(11) COMMENT 'Referenced tennant',
	undo_id                    INT(11) NOT NULL COMMENT 'Reference key',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Change date of content',
	KEY undodyncontent$mid$idx (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'copies entries in dyn_content_tbl (plus undo - ID) to provide undo function, for column description see dyn_content_tbl';

CREATE TABLE undo_id_seq (
	value                      INT(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci  COMMENT 'is related to undo_dyn_content_tbl and undo_component_tbl';
INSERT INTO undo_id_seq (value) VALUES (1);

CREATE TABLE undo_mailing_tbl (
	mailing_id                 INT(11) COMMENT 'mailing - ID (mailing_tbl)',
	undo_id                    INT(11) NOT NULL COMMENT 'unique ID, use undo_id_seq',
	undo_creation_date         TIMESTAMP NOT NULL COMMENT 'entry creation date',
	undo_admin_id              INT(11) NOT NULL COMMENT 'admin who made changes to EMC mailing and caused undo entry creation - ID (admin_tbl)',
	KEY undomailing$mid$idx (mailing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'copies entries in mailing_tbl (plus undo - ID) to provide undo function, for column description see mailing_tbl';

CREATE TABLE upload_tbl (
	upload_id                  INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use upload_tbl_seq',
	admin_id                   INT(11) COMMENT 'references (targeted) EMM-User (admin_tbl)',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'entry last change',
	contact_name               VARCHAR(100) COMMENT 'uploading person: lastname',
	contact_firstname          VARCHAR(100) COMMENT 'uploading person: firstname',
	contact_phone              VARCHAR(30) COMMENT 'uploading person: phone',
	contact_mail               VARCHAR(100) COMMENT 'uploading person: email-address',
	sendto_mail                VARCHAR(100) COMMENT 'address where upload notification should be sent to',
	description                LONGTEXT COMMENT 'comment on entry, part of the email-notification',
	payload                    LONGBLOB COMMENT 'the content of the file',
	filename                   VARCHAR(100) COMMENT 'name of uploaded file',
	filesize                   INT(11) COMMENT 'size of uploaded file',
	company_id                 INT(11) COMMENT 'tenant - ID (company_tbl)',
	no_delete                  INT(1) DEFAULT 0 COMMENT '1= entry wont be cleaned up',
	from_admin_id              INT(11) DEFAULT 0 COMMENT 'references (uploading) EMM-User (admin_tbl)',
	PRIMARY KEY (upload_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[secret_data] (all the table to be cleared on anonymization) stores information about file - Exchange via EMM - Upload';

CREATE TABLE userform_tbl (
	form_id                    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use userform_tbl_seq',
	company_id                 INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	formname                   VARCHAR(50) NOT NULL DEFAULT '' COMMENT 'name of the form',
	description                TEXT NOT NULL COMMENT 'comment on form',
	startaction_id             INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'references action (rdir_action_tbl.action_id) to be executed on form start',
	endaction_id               INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'references action (rdir_action_tbl.action_id) to be executed on form end',
	success_template           LONGTEXT NOT NULL COMMENT 'script to execute or site to show on successfull startaction execution (velocity)',
	error_template             LONGTEXT NOT NULL COMMENT 'script to execute or site to show on non-successfull startaction execution (velocity)',
	creation_date              TIMESTAMP NULL COMMENT 'form creation date',
	trackable_link_extension   VARCHAR(200) COMMENT 'addional parameter(s) to extend URL',
	success_url                VARCHAR(500) COMMENT 'URL called after successfull form execution',
	error_url                  VARCHAR(500) COMMENT 'URL called after non-successfull form execution',
	error_use_url              INT(1) DEFAULT 0 COMMENT '1=use error_url',
	success_use_url            INT(1) DEFAULT 0 COMMENT '1=use success_url',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'form last change',
	success_mimetype           VARCHAR(20) COMMENT 'Mimetype of the success html text',
	error_mimetype             VARCHAR(20) COMMENT 'Mimetype of the error html text',
	active                     INT(1) NOT NULL DEFAULT 1 COMMENT 'If set to 0, then the form should not be available for using',
	PRIMARY KEY (form_id),
	KEY formname (formname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores data for form (e.g. opt-out / opt-in forms';
CREATE UNIQUE INDEX usrfo$cidname$uq ON userform_tbl (company_id, formname);

CREATE TABLE world_mailing_backend_log_tbl (
	mailing_id                 INT(10) DEFAULT 0 COMMENT 'references mailing (mailing_tbl.mailing_id)',
	current_mails              INT(10) DEFAULT 0 COMMENT 'mumber of mails already generated',
	total_mails                INT(10) DEFAULT 0 COMMENT 'mumber of mails to send',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry last change',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'in line with mailing_backend_log_tbl, but world mailings only. filled after mailgeneration is done';

CREATE TABLE userlog_tbl (
	logtime                    TIMESTAMP NOT NULL COMMENT 'action - time',
	username                   VARCHAR(200) COMMENT 'EMM - User',
	action                     VARCHAR(100) COMMENT 'name of this action',
	description                VARCHAR(4000) COMMENT 'additional information',
	supervisor_name            VARCHAR(100) COMMENT 'if this was a supervisor access it is stored here'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores log of actions an EMM - user had been done via EMM GUI, auto- cleaned up after 180d';
CREATE INDEX userlog$logtime$idx ON userlog_tbl (logtime);
CREATE INDEX userlog$username$idx ON userlog_tbl (username);

CREATE TABLE messages_tbl (
	message_key                VARCHAR(150) NOT NULL COLLATE utf8mb4_bin COMMENT 'key - value referenced in EMM',
	value_default              TEXT COMMENT 'default message / identifier - english-',
	value_de                   TEXT COMMENT 'german translation',
	value_es                   TEXT COMMENT 'spanish translation',
	value_fr                   TEXT COMMENT 'french translation',
	value_nl                   TEXT COMMENT 'dutch translation',
	value_pt                   TEXT COMMENT 'Portuguese translation',
	value_it                   TEXT COMMENT 'Italian translation',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL COMMENT 'entry last change',
	deleted                    INT(1) DEFAULT 0 COMMENT '1=yes',
	PRIMARY KEY (message_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores any messages or identifiers used in EMM-GUI including translations for different languages';

CREATE TABLE admin_pref_tbl (
	admin_id                   INT(11) DEFAULT 0 COMMENT 'references EMM-User (admin_tbl)',
	pref                       VARCHAR(40) NOT NULL COMMENT 'parameter - name, e.g. listsize',
	val                        VARCHAR(5) DEFAULT '0' COMMENT 'parameter - value, e.g. 50',
	KEY (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'allows to store settings for EMM users such as listsize or startpage';

CREATE TABLE actop_activate_doi_tbl (
	action_operation_id        INT(11) NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	for_all_lists              INT(1) NOT NULL DEFAULT 0 COMMENT '1= state is changed from 5 (waiting for DOI) to 1 (active) for all mailinglists, 0= given ML only',
	media_type                 INTEGER(1) COMMENT 'Media type for DOI confirmation'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'action-step to confirm DOI';

CREATE TABLE csv_imexport_description_tbl (
	id                         INT(11) AUTO_INCREMENT COMMENT 'unique ID, use csv_imexport_descr_tbl_seq',
	company_id                 INT(11) NOT NULL COMMENT 'tenant - ID (company_tbl)',
	name                       VARCHAR(64) NOT NULL COMMENT 'Setting-name',
	delimiter                  VARCHAR(1) NOT NULL COMMENT 'defines csv column delimters',
	encoding                   VARCHAR(64) NOT NULL COMMENT 'defines csv encoding',
	stringquote                VARCHAR(1) COMMENT 'defines csv String identifying marks',
	fullimportonly             INT(1) NOT NULL COMMENT 'Import all data or nothing at all, if any error is included in data like invalid email',
	for_import                 INT(1) DEFAULT 0 COMMENT '1=import, 0=export',
	importmethod               VARCHAR(32) COMMENT 'e.g. ClearBeforeInsert = esp for reference-tables, table will be cleared befor import, UpdateAndInsert, UpdateOnly',
	updatemethod               VARCHAR(32) COMMENT 'UpdateAll or DontUpdateWithEmptyData = no overwriting, if newvalue is null',
	tablename                  VARCHAR(200) COMMENT 'null = customer_table, table_name for reference-tables',
	creation_date_from         INTEGER NULL COMMENT 'for exports: only in this period created entries would be exported',
	creation_date_till         INTEGER NULL COMMENT 'for exports: only in this period created entries would be exported',
	change_date_from           INTEGER NULL COMMENT 'for exports: only in this period modified entries would be exported',
	change_date_till           INTEGER NULL COMMENT 'for exports: only in this period modified entries would be exported',
	no_headers                 INTEGER COMMENT 'Csv file without headers',
	zipped                     INTEGER COMMENT 'Zipped import file',
	zippassword                VARCHAR(100) COMMENT 'Encrypted zip password',
	checkforduplicates         INTEGER COMMENT 'Duplicate check method id',
	report_email               VARCHAR(400) COMMENT 'Email for import information',
	error_email                VARCHAR(400) COMMENT 'Always use delimiter for quotation of strings in csv outout',
	automapping                INTEGER COMMENT 'Used db cloumn names for csv columns',
	always_quote               INTEGER DEFAULT 0 COMMENT 'Always use delimiter for quotation of strings in csv outout',
	PRIMARY KEY (id),
	UNIQUE KEY unique_csv_cid_name_idx (company_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'contains more details about EMM - import or -export - settings';

CREATE TABLE rdirlog_val_num_dupl_tbl (
	company_id                 INT(10) COMMENT 'Referenced client',
	customer_id                INTEGER UNSIGNED COMMENT 'Referenced customer',
	ip_adr                     VARCHAR(15) COMMENT 'IP of customer when creating this data',
	mailing_id                 INT(10) COMMENT 'Referenced mailing',
	session_id                 INT(10) COMMENT 'Seesion id of customer when creation this data',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation date for this data entry',
	num_parameter              INT(10) COMMENT 'Numeric value to be measured',
	page_tag                   VARCHAR(30) COMMENT 'Text describing this measure point'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'to clean up dublicate entries in rdirlog_val_num_tbl if a values is measured multiple times';
ALTER TABLE admin_tbl ADD CONSTRAINT admin_tbl_ibfk_1 FOREIGN KEY (company_id) REFERENCES company_tbl (company_id);

ALTER TABLE auto_import_mlist_bind_tbl ADD CONSTRAINT auto_import_mlist_bind_tbl_ibfk_1 FOREIGN KEY (company_id) REFERENCES company_tbl (company_id);
ALTER TABLE auto_import_mlist_bind_tbl ADD CONSTRAINT auto_import_mlist_bind_tbl_ibfk_2 FOREIGN KEY (auto_import_id) REFERENCES auto_import_tbl (auto_import_id);
ALTER TABLE auto_import_mlist_bind_tbl ADD CONSTRAINT auto_import_mlist_bind_tbl_ibfk_3 FOREIGN KEY (mailinglist_id) REFERENCES mailinglist_tbl (mailinglist_id);

ALTER TABLE auto_import_tbl ADD CONSTRAINT auto_import_tbl_ibfk_1 FOREIGN KEY (company_id) REFERENCES company_tbl (company_id);
ALTER TABLE auto_import_tbl ADD CONSTRAINT auto_import_tbl_ibfk_2 FOREIGN KEY (admin_id) REFERENCES admin_tbl (admin_id);

ALTER TABLE auto_import_used_files_tbl ADD CONSTRAINT auto_import_used_files_tbl_ibfk_1 FOREIGN KEY (company_id) REFERENCES company_tbl (company_id);
ALTER TABLE auto_import_used_files_tbl ADD CONSTRAINT auto_import_used_files_tbl_ibfk_2 FOREIGN KEY (auto_import_id) REFERENCES auto_import_tbl (auto_import_id);

ALTER TABLE customer_1_binding_tbl ADD CONSTRAINT customer_1_binding_tbl_ibfk_1 FOREIGN KEY (customer_id) REFERENCES customer_1_tbl (customer_id);

ALTER TABLE datasource_description_tbl ADD CONSTRAINT datasource_description_tbl_ibfk_2 FOREIGN KEY (sourcegroup_id) REFERENCES sourcegroup_tbl (sourcegroup_id);

ALTER TABLE job_queue_parameter_tbl ADD CONSTRAINT job_queue_parameter_tbl_ibfk_1 FOREIGN KEY (job_id) REFERENCES job_queue_tbl (id);

ALTER TABLE rdir_url_param_tbl ADD CONSTRAINT fk_rdir_url_param_id FOREIGN KEY (URL_ID) REFERENCES rdir_url_tbl (url_id);

ALTER TABLE rdir_url_userform_param_tbl ADD CONSTRAINT fk_rdir_url_userform_param_id FOREIGN KEY (URL_ID) REFERENCES rdir_url_userform_tbl (url_id);

CREATE TABLE actop_tbl (
	action_operation_id        INTEGER NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use actop_tbl_seq',
	company_id                 INTEGER NOT NULL COMMENT 'tenant - ID (company_tbl)',
	type                       VARCHAR(255) NOT NULL COMMENT 'defines type (and sub - table containg detail-data) e.g. GetCustomer => actop_get_customer_tbl',
	action_id                  INT(10) UNSIGNED NOT NULL COMMENT 'references action metaData (rdir_action_tbl.action_id)',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'splits EMM - action into operation steps (order defined by action_operation_id - order)';

CREATE TABLE actop_execute_script_tbl (
	script                     TEXT NOT NULL COMMENT 'velocity - code',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'detail info about action-step to execute scripts';

CREATE TABLE actop_update_customer_tbl (
	column_name                VARCHAR(255) NOT NULL COMMENT 'column name in customer_xxx_tbl to be updated',
	update_type                INTEGER NOT NULL COMMENT '1 -> Increment, 2 -> Decrement, 3 -> Set',
	update_value               VARCHAR(255) NOT NULL COMMENT 'eg. 1 for increment by 1 or sysdate for set = sysdate',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	trackpoint_id              INT(22) COMMENT 'if != 0: used for profile-field modification',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'allows updates on customer_xxx_tbl by action - step';

CREATE TABLE actop_get_customer_tbl (
	load_always                TINYINT(1) NOT NULL COMMENT '1= inactive recipients are loaded, too, 0 = loading active recipients only',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'action-step for loading recipient';

CREATE TABLE actop_subscribe_customer_tbl (
	double_check               TINYINT(1) NOT NULL COMMENT '1=checks, if recipient already exists, 0=no check',
	key_column                 VARCHAR(255) NOT NULL COMMENT 'column double_check, e.g. email',
	double_opt_in              TINYINT(1) NOT NULL COMMENT '1 = state is set to DOI - waiting for confirm (5)',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'details for subscribe action steps';

CREATE TABLE actop_send_mailing_tbl (
	mailing_id                 INTEGER NOT NULL COMMENT 'references mailing (mailing_tbl.mailing_id)',
	delay_minutes              INTEGER NOT NULL COMMENT 'delay between action is triggered and mail is send',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	use_as_doi                 INT DEFAULT 0 NOT NULL COMMENT '1=this is a DOI mailing, send to recipients having user_status = 5',
	bcc                        VARCHAR(4000),
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'details for action step sending action based mailing';

CREATE TABLE actop_service_mail_tbl (
	text_mail                  TEXT NOT NULL COMMENT 'email content -text format',
	subject_line               VARCHAR(255) NOT NULL COMMENT 'email subject',
	to_addr                    VARCHAR(255) NOT NULL COMMENT '[private_data]recipient',
	mailtype                   INTEGER NOT NULL COMMENT '1= html and text, 0 = text ',
	html_mail                  TEXT NOT NULL COMMENT 'email content -html format',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	from_address               VARCHAR(100) COMMENT 'Senders email address',
	reply_address              VARCHAR(100) COMMENT 'Emailaddress to reply to',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '[secret_data] (?) action-step to send a service mail to specified recipient(s) (actually customer-specific feature)';

CREATE TABLE campaign_tbl (
	campaign_id                INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use campaign_tbl_seq',
	company_id                 INT(11) NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	shortname                  VARCHAR(100) DEFAULT '' COMMENT 'archive - name',
	description                VARCHAR(1000) DEFAULT '' COMMENT 'comment on entry',
	creation_date              TIMESTAMP NULL COMMENT 'entry creation date',
	change_date                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'entry last change',
	PRIMARY KEY (campaign_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Table for archives, used like a folder to group mailings';

CREATE TABLE actop_get_archive_list_tbl (
	campaign_id                INTEGER NOT NULL COMMENT 'references campaign_tbl (ARCHIVED Mailings, not WM)',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'action-step to list mailings (archived only) e.g. for links "show my prev. mailings"';

CREATE TABLE actop_get_archive_mailing_tbl (
	expire_day                 INTEGER NOT NULL COMMENT 'expire - timestamp DD',
	expire_month               INTEGER NOT NULL COMMENT 'expire - timestamp MM',
	expire_year                INTEGER NOT NULL COMMENT 'expire - timestamp YYYY',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Action-step to load archive mailing';

CREATE TABLE actop_content_view_tbl (
	tag_name                   VARCHAR(255) NOT NULL COMMENT 'content-block name to be shown',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'action-step to load special content';

CREATE TABLE actop_identify_customer_tbl (
	key_column                 VARCHAR(255) NOT NULL COMMENT 'matching column (in customer_xxx_tbl) e.g. email',
	pass_column                VARCHAR(255) NOT NULL COMMENT 'allows to protect loading customer_data by password, password has to be stored in this customer_xxx_tbl - column',
	action_operation_id        INTEGER NOT NULL COMMENT 'references actop_tbl.action_operation_id',
	PRIMARY KEY (action_operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'detail for action steps to find a recipient in customer_xxx_tbl';

ALTER TABLE actop_tbl ADD INDEX idx_ao_a(action_id), ADD CONSTRAINT idx_ao_a FOREIGN KEY (action_id) REFERENCES rdir_action_tbl (action_id);
ALTER TABLE actop_execute_script_tbl ADD INDEX idx_ao1_ao(action_operation_id), ADD CONSTRAINT idx_ao1_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_update_customer_tbl ADD INDEX idx_ao2_ao(action_operation_id), ADD CONSTRAINT idx_ao2_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_get_customer_tbl ADD INDEX idx_ao3_ao(action_operation_id), ADD CONSTRAINT idx_ao3_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_subscribe_customer_tbl ADD INDEX idx_ao4_ao(action_operation_id), ADD CONSTRAINT idx_ao4_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_send_mailing_tbl ADD INDEX idx_ao5_ao(action_operation_id), ADD CONSTRAINT idx_ao5_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_service_mail_tbl ADD INDEX idx_ao6_ao(action_operation_id), ADD CONSTRAINT idx_ao6_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_get_archive_list_tbl ADD INDEX idx_ao7_ao(action_operation_id), ADD CONSTRAINT idx_ao7_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_get_archive_mailing_tbl ADD INDEX idx_ao8_ao(action_operation_id), ADD CONSTRAINT idx_ao8_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_content_view_tbl ADD INDEX idx_ao9_ao(action_operation_id), ADD CONSTRAINT idx_ao9_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);
ALTER TABLE actop_identify_customer_tbl ADD INDEX idx_a11_ao(action_operation_id), ADD CONSTRAINT idx_a11_ao FOREIGN KEY (action_operation_id) REFERENCES actop_tbl (action_operation_id);

CREATE TABLE auto_export_tbl (
	auto_export_id             INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique ID, use auto_export_tbl_seq',
	export_profile_id          INT(10) UNSIGNED NOT NULL COMMENT 'references export_profile (stored also in IMPORT_profile_tbl!)',
	shortname                  VARCHAR(100) NOT NULL COMMENT 'export - name',
	description                VARCHAR(1000) COMMENT 'comment on entry',
	file_path                  VARCHAR(400) NOT NULL COMMENT 'path to deliver export file(s)',
	one_time                   INT(1) NOT NULL COMMENT '1= executed only once',
	company_id                 INT(11) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	admin_id                   INT(11) NOT NULL COMMENT 'references EMM-User (admin_tbl)',
	active                     INT(1) DEFAULT 0 NOT NULL COMMENT'0 = deactivated / done',
	executed                   INT(1) DEFAULT 0 NOT NULL COMMENT '1= yes',
	auto_activation_date       TIMESTAMP NULL COMMENT 'export will be activated at this time',
	deactivate_by_campaign     INT(1) DEFAULT 0 NOT NULL COMMENT 'If autoexport is used by a campaign, this campaign may be deactivated and then deactivates this autoexport also',
	type                       VARCHAR(64) COMMENT 'Mailing / Recipient / ReferenceTable',
	csvdescription_id          INT COMMENT 'references csv_imexport_description_tbl.id',
	referencetable_id          INT COMMENT 'references reference_tbl.id if reference table should be exported',
	allow_unknown_hostkeys     INT(1) COMMENT '1=allowed',
	file_server_encrypted      VARCHAR(400) COMMENT 'encryped path to file server',
	filename_with_patterns     VARCHAR(100) COMMENT 'name of export-file, optionally containing patterns e.g. to add a date in resulting file-name',
	private_key                VARCHAR(2048) COMMENT 'for sftp connection',
	created                    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	changed                    TIMESTAMP NULL COMMENT 'entry last change',
	laststart                  TIMESTAMP NULL COMMENT 'last run timestamp',
	running                    INT(1) DEFAULT 0 COMMENT '1=actually executing',
	lastresult                 VARCHAR(512) NULL COMMENT 'last run result (ok or error message)',
	intervalpattern            TEXT NULL COMMENT 'defines execution times',
	nextstart                  TIMESTAMP NULL COMMENT 'next run timestamp',
	lasthostname               VARCHAR(64) NULL COMMENT 'last host on wich the job was executed',
	emailonerror               VARCHAR(64) NULL COMMENT '[private_data] email - recipient for any error-reports',
	mailing_id                 INTEGER COMMENT 'Mailing this export is linked to for execution after delivery',
	hidden                     INT(1) DEFAULT 0 COMMENT 'Hide this special autoexport from GUI, so noone may change its configuration',
	interval_as_json           TEXT COMMENT 'interval pattern as json data',
	timezone                   VARCHAR(48) COMMENT 'Timezone for calculation of next export',
	email_for_report           VARCHAR(64) COMMENT 'Emails list separated by [,; ] for send report after autoexport',
	PRIMARY KEY (auto_export_id),
	KEY company_id (company_id),
	KEY admin_id (admin_id),
	KEY export_profile_id (export_profile_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'contains information about sheduled exports';

CREATE TABLE auto_export_result_tbl (
	auto_export_id             INT(4) NOT NULL COMMENT 'references auto_export_tbl.auto_export_id',
	time                       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'starting timestamp',
	result                     VARCHAR(512) NOT NULL COMMENT 'success / error message',
	duration                   INT(8) DEFAULT 0 COMMENT 'in sec',
	hostname                   VARCHAR(64) NOT NULL COMMENT 'executing host',
	fieldcount                 INTEGER COMMENT 'Number of fields exported',
	exportcount                INTEGER COMMENT 'Number of lines exported',
	filesize                   INTEGER COMMENT 'Filesize of exported file'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'history / log for done imports: result and duration for monitoring / tracing issues and export report';
ALTER TABLE auto_export_result_tbl ADD CONSTRAINT aexpresult$id$fk FOREIGN KEY (auto_export_id) REFERENCES auto_export_tbl (auto_export_id);

CREATE TABLE hostauth_pending_tbl (
	admin_id                   INTEGER NOT NULL COMMENT 'references  EMM-User (admin_tbl)',
	host_id                    VARCHAR(80) NOT NULL COMMENT 'defines requesting host',
	security_code              VARCHAR(10) NOT NULL COMMENT 'security-code for authentification as sent to user',
	creation_date              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	PRIMARY KEY (admin_id, host_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'contains pending authentification info used for 2-factor-auth.';

CREATE TABLE authenticated_hosts_tbl (
	admin_id                   INTEGER NOT NULL COMMENT 'references  EMM-User (admin_tbl)',
	host_id                    VARCHAR(80) NOT NULL COMMENT 'defines requesting host',
	expire_date                TIMESTAMP NOT NULL COMMENT 'entry expire date',
	creation_date              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'entry creation date',
	change_date                TIMESTAMP NOT NULL COMMENT 'entry last change',
	PRIMARY KEY (admin_id, host_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'contains successfull authentification info used for 2-factor-auth.';

CREATE TABLE job_queue_result_tbl (
	job_id                     INT(11) NOT NULL COMMENT 'references job_queue_tbl.id',
	time                       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'execution-timestamp',
	result                     VARCHAR(512) COMMENT 'execution result: OK or error-message',
	duration                   INT(10) DEFAULT 0 COMMENT 'execution duration',
	hostname                   VARCHAR(64) COMMENT 'execution host'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'history / log for done jobs triggered by job-queue: result and duration for monitoring / tracing issues';
ALTER TABLE job_queue_result_tbl ADD CONSTRAINT jobresult$jobid$fk FOREIGN KEY (job_id) REFERENCES job_queue_tbl (id);

CREATE TABLE admin_password_reset_tbl (
	admin_id                   INTEGER NOT NULL COMMENT 'references EMM-User (admin_tbl)',
	time                       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'last pwsd - change',
	valid_until                TIMESTAMP NOT NULL COMMENT 'pswd expire date',
	ip_address                 VARCHAR(64) NOT NULL COMMENT '[secret_data] address calling last change',
	token_hash                 VARCHAR(64) NOT NULL COMMENT 'hashed pswd - token',
	error_count                INTEGER NOT NULL COMMENT 'fail counter'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores information about password changes and - expire dates';

CREATE TABLE form_component_tbl (
	id                         INTEGER NOT NULL AUTO_INCREMENT COMMENT 'refernce key',
	form_id                    INTEGER NOT NULL COMMENT 'Referenced for this content',
	company_id                 INTEGER NOT NULL COMMENT 'Referenced client',
	name                       VARCHAR(64) NOT NULL COMMENT 'Component name',
	type                       INTEGER NOT NULL COMMENT 'Component like hosted image or external data',
	data                       LONGBLOB COMMENT 'Binary data of component',
	data_size                  INTEGER NOT NULL COMMENT 'Data size',
	width                      INTEGER COMMENT 'Image width',
	height                     INTEGER COMMENT 'Image height',
	mimetype                   VARCHAR(32) NOT NULL COMMENT 'Mimetype of component',
	description                VARCHAR(100) COMMENT 'Description of component',
	creation_date              TIMESTAMP NOT NULL COMMENT 'Creation date of component',
	change_date                TIMESTAMP NOT NULL COMMENT 'Change date of component',
	PRIMARY KEY (id),
	UNIQUE KEY (form_id, name, type)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Images or other binary content for userforms';

CREATE TABLE mail_notification_buffer_tbl (
	id                         INTEGER NOT NULL AUTO_INCREMENT COMMENT 'Reference key',
	recipients                 VARCHAR(400) NOT NULL COMMENT 'Recipients email addresses',
	subject                    VARCHAR(400) NOT NULL COMMENT 'Email subject',
	text                       VARCHAR(1000) NOT NULL COMMENT 'Email text',
	send_time                  TIMESTAMP NOT NULL COMMENT 'Last send time of this email notification',
	last_request_time          TIMESTAMP NOT NULL COMMENT 'Latest request to send exactly this email and its text',
	request_count              INTEGER NOT NULL COMMENT 'Number of send retries',
	PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Buffer for email notification on errors and events to not send spam emails to notified email';

CREATE TABLE mailing_statistic_job_tbl (
	mailing_stat_job_id        INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Statistic job id',
	job_status                 INT(11) NOT NULL COMMENT 'STatus of the generation of statistics data',
	mailing_id                 INT(11) NOT NULL COMMENT 'Mailing referenced for statistics',
	target_groups              VARCHAR(40) COMMENT 'Used targetgroups for statistics',
	recipients_type            INT(11) NOT NULL COMMENT 'Recipient types (World, Testser, ADmin)',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation date of this request',
	change_date                TIMESTAMP NULL COMMENT 'Change Date of this request',
	job_status_descr           VARCHAR(4000) COMMENT 'Status info text',
	PRIMARY KEY (mailing_stat_job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Webservice statistic jobs to request asynchronously';

CREATE TABLE mailing_statistic_tgtgrp_tbl (
	mailing_stat_tgtgrp_id     INT(11) NOT NULL AUTO_INCREMENT COMMENT 'ID of entry',
	mailing_stat_job_id        INT(11) NOT NULL COMMENT 'ID of statistics job',
	mailing_id                 INT(11) NOT NULL COMMENT 'ID of mailing for statistics. Reference to mailing_tbl.id',
	target_group_id            INT(11) NOT NULL COMMENT 'ID of target group used in statistics. Reference to dyn_target_tbl.target_id',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation date of entry',
	revenue                    DECIMAL(5, 2) DEFAULT 0.0 COMMENT 'revenue of mailing for selected target group',
	PRIMARY KEY (mailing_stat_tgtgrp_id),
	UNIQUE KEY `unique_job_tg_idx` (`mailing_stat_job_id`, `target_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Target group lists for MailingSummary webservice';

CREATE TABLE mailing_statistic_value_tbl (
	mailing_stat_tgtgrp_id     INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Reference to mailing_statistic_tgtgrp_tbl.mailing_stat_tgtgrp_id',
	category_index             INT(11) NOT NULL COMMENT 'Type of statistics value',
	stat_value                 INT DEFAULT 0 COMMENT 'Statistics vlaue (absolute)',
	stat_quotient              DECIMAL(5, 2) DEFAULT 0.0 COMMENT 'Statistics value (relative)',
	UNIQUE KEY `unique_bl_cat_idx` (`mailing_stat_tgtgrp_id`, `category_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Holds values for statistics computes by MailingSummary webservice';

CREATE TABLE server_command_tbl (
	command                    VARCHAR(200) COMMENT 'Command to execute by servers like clear all image chaches',
	server_name                VARCHAR(50) COMMENT 'Server to execute the command',
	execution_date             TIMESTAMP NULL COMMENT 'Execution date',
	admin_id                   INT(11) COMMENT 'Admin who created this command',
	description                VARCHAR(2000) COMMENT 'Decription of command',
	timestamp                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Change date of command'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Internal command storage for EMM servers. Can be set by EMM and is executed on RDIRs';

CREATE TABLE calendar_custom_recipients_tbl (
	comment_id                 INT(11) NOT NULL COMMENT 'Referenced Comment',
	company_id                 INT(11) NOT NULL COMMENT 'Referenced client',
	email                      VARCHAR(200) COMMENT 'Email of recipient',
	admin_id                   INT(11) DEFAULT 0 NOT NULL COMMENT 'Admin who created this notification request',
	notified                   INT DEFAULT 0 NOT NULL COMMENT 'Was recipient notified yet'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Send comments on calendar dates to email addresses';

CREATE TABLE sessionhijackingprevention_tbl (
	ip_group                   INT(2) COMMENT 'Reference key',
	ip                         VARCHAR(200) COMMENT 'IP entry for a whitelist group',
	comments                   VARCHAR(200) COMMENT 'Description of this group'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Definition of groups which may change their request IP on an EMM without being blocked';

CREATE TABLE landingpage_tbl (
	domain                     VARCHAR(64) COMMENT 'Domain used in rdir request',
	landingpage                VARCHAR(64) COMMENT 'Landingpage for redirect of rdir requests without any parameter'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Landigpage info for Rdir servers';

CREATE TABLE import_action_tbl (
	importaction_id            INTEGER NOT NULL AUTO_INCREMENT COMMENT 'Reference key used by import_profile_tbl',
	company_id                 INTEGER NOT NULL COMMENT 'Referenced client',
	name                       VARCHAR(128) COMMENT 'Name of this pre import action',
	type                       VARCHAR(32) NOT NULL COMMENT 'Only SQL by now',
	action                     LONGTEXT NOT NULL COMMENT 'SQL script text to be executed',
	creation_date              TIMESTAMP NULL COMMENT 'Creation date of this action',
	change_date                TIMESTAMP NULL COMMENT 'Change date of this action',
	PRIMARY KEY (importaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Pre import actions';

CREATE TABLE scripthelper_email_log_tbl (
	company_id                 INTEGER COMMENT 'Referenced client',
	from_email                 VARCHAR(256) COMMENT 'Senders email',
	to_email                   VARCHAR(256) COMMENT 'Recipients email',
	cc_email                   VARCHAR(256) COMMENT 'CC emails',
	subject                    VARCHAR(256) COMMENT 'Email subject',
	send_date                  TIMESTAMP NULL COMMENT 'Send date of email',
	mailing_id                 INTEGER COMMENT 'Referenced mailing',
	form_id                    INTEGER COMMENT 'Referenced userform_tbl entry'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Logging of sent emails by Velocity scripts';

CREATE TABLE download_tbl (
	download_id                INT(11) UNSIGNED AUTO_INCREMENT COMMENT 'Reference key',
	content                    LONGBLOB NOT NULL COMMENT 'File data',
	PRIMARY KEY (download_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Downloadable files like exports';

CREATE TABLE admin_use_tbl (
	admin_id                   INTEGER NOT NULL COMMENT 'Referenced admin',
	feature                    VARCHAR(100) NOT NULL COMMENT 'Feature used by this admin',
	use_count                  INTEGER DEFAULT 0 NOT NULL COMMENT 'Times of usage',
	last_use                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Latest usage',
	last_hint                  TIMESTAMP NULL COMMENT 'legacy',
	CONSTRAINT pk_adminuse PRIMARY KEY (admin_id, feature),
	CONSTRAINT adminuse$admin$fk FOREIGN KEY (admin_id) REFERENCES admin_tbl (admin_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Logging of admin usage of EMM';

CREATE TABLE csv_imexport_mapping_tbl (
	description_id             INTEGER NOT NULL COMMENT 'Foreighn key to csv_imexport_description_tbl',
	dbcolumn                   VARCHAR(100) NOT NULL COMMENT 'DBs column to map to',
	filecolumn                 VARCHAR(100) NOT NULL COMMENT 'Files column to map from',
	defaultvalue               VARCHAR(100) COMMENT 'Defaultvalue for data',
	format                     VARCHAR(100) COMMENT 'Format for data',
	mandatory                  INTEGER NOT NULL COMMENT 'Is field mandatory',
	encrypted                  INTEGER NOT NULL COMMENT 'Is fields data encrypted',
	keycolumn                  INTEGER NOT NULL COMMENT 'Is this a keycolumn'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Columnmappings for csv imports';
ALTER TABLE csv_imexport_mapping_tbl ADD CONSTRAINT csv$mapping FOREIGN KEY (description_id) REFERENCES csv_imexport_description_tbl (id);

CREATE TABLE bcc_mailing_account_tbl (
	mailing_account_id         INT(11) NOT NULL COMMENT '-> mailing_account_tbl.mailing_account_id',
	no_of_mailings             INT(11) COMMENT 'number of mailings sent as bcc mailings',
	no_of_bytes                INT(11) COMMENT 'number of bytes sent as bcc mailings',
	PRIMARY KEY (mailing_account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores accounting information for bcc mails';

CREATE TABLE cust_temporary_tbl (
	uuid                       VARCHAR(100) NOT NULL COMMENT 'Uniq number of transaction',
	customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'Customer id',
	PRIMARY KEY (uuid, customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Temp table for save customer id and continue use them for lock before update';

CREATE TABLE test_recipients_tbl (
    maildrop_status_id         INT(11) NOT NULL COMMENT 'Reference to maildrop_status_tbl.status_id',
    customer_id                INTEGER UNSIGNED NOT NULL COMMENT 'Reference to customer_xx_tbl.customer_id',
    PRIMARY KEY (maildrop_status_id, customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'If maildrop_status_tbl.selected_test_recipients=1, then the recpients for this test run are taken from this table';

CREATE TABLE pending_email_change_tbl (
	company_ref                INT(11) NOT NULL COMMENT 'References company',
	customer_ref               INT(11) NOT NULL COMMENT 'References customer',
	new_email_address          VARCHAR(100) NOT NULL COMMENT 'New (unconfirmed) email address',
	confirmation_code          VARCHAR(100) NOT NULL COMMENT 'Random code required for confirmation',
	creation_date              TIMESTAMP NOT NULL COMMENT 'Creation date of record'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'List of unconfirmed email address changes';

CREATE TABLE auto_import_ws_tbl (
	job_id                     INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT COMMENT 'unique ID',
	company_id                 INTEGER NOT NULL COMMENT 'tenant - ID (company_tbl)',
	auto_import_id             INTEGER NOT NULL COMMENT 'auto-import - ID (auto_import_tbl)',
	status                     INTEGER NOT NULL COMMENT 'current job status; 1=queued, 2=running, 3=transferring, 4=done, 5=failed',
	expire_timestamp           TIMESTAMP COMMENT 'an expiration timestamp — once it''s reached a cleanup is permitted',
	report                     TEXT COMMENT 'a JSON representation of extra info about job results, to be set once job is completed/failed'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores WS-triggered auto-import job state while running and some time after completion';

CREATE TABLE import_profile_mlist_bind_tbl (
	import_profile_id          INT(11) UNSIGNED NOT NULL COMMENT 'references import_profile_tbl.id',
	mailinglist_id             INT(11) UNSIGNED NOT NULL COMMENT 'references mailinglist_tbl. mailinglist_id',
	company_id                 INT(11) UNSIGNED NOT NULL COMMENT 'tenant - ID (company_tbl)',
	PRIMARY KEY (import_profile_id, mailinglist_id),
	CONSTRAINT import_profile_mlist_ibfk_1 FOREIGN KEY (import_profile_id) REFERENCES import_profile_tbl (id),
	CONSTRAINT import_profile_mlist_ibfk_2 FOREIGN KEY (mailinglist_id) REFERENCES mailinglist_tbl (mailinglist_id),
	CONSTRAINT import_profile_mlist_ibfk_3 FOREIGN KEY (company_id) REFERENCES company_tbl (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'allows n:m relation between import profiles and mailinglists';

CREATE TABLE rdir_traffic_amount_tbl (
	company_id                 INTEGER COMMENT 'CompanyID of acquired data object',
	mailing_id                 INTEGER COMMENT 'MailingID of acquired data object, 0 for Mediapool data',
	content_name               VARCHAR(3000) COMMENT 'Name of data object',
	content_size               INTEGER COMMENT 'Size of data object',
	demand_date                DATE COMMENT 'Date of data transfer',
	amount                     INTEGER COMMENT 'Number of calls for same data object'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Stores data amount for billing';

CREATE TABLE webservice_user_tbl (
	username                   VARCHAR(200) NOT NULL COMMENT '(unique) username',
	company_id                 INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'tenant - ID (company_tbl)',
	default_data_source_id     INT(10) NOT NULL COMMENT 'created (datasource_ID) or updated (latest_datasource_ID) recipients are marked by this ID if no other datasource_ID is given',
	req_rate_limit             DECIMAL(5, 2) COMMENT 'Limit for requests over time',
	bulk_size_limit            INT(10) DEFAULT 1000 NOT NULL COMMENT 'possibilty to set limit for bulk updates',
	password_encrypted         VARCHAR(256) COMMENT 'authentification password (encrypted)',
	max_result_list_size       INT(10) DEFAULT 0 NOT NULL COMMENT 'possibilty to set limit for requested list length',
	active                     INT(1) UNSIGNED COMMENT '1 = yes',
	contact_info               VARCHAR(2000) COMMENT 'e.g. email',
	contact_email              VARCHAR(400) COMMENT 'Email for contact'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'stores webservice (2.0) - user';
ALTER TABLE webservice_user_tbl ADD CONSTRAINT websuser$cid$fk FOREIGN KEY (company_id) REFERENCES company_tbl (company_id);
ALTER TABLE webservice_user_tbl ADD CONSTRAINT websuser$dds$fk FOREIGN KEY (default_data_source_id) REFERENCES datasource_description_tbl (datasource_id);

CREATE TABLE recipients_report_tbl (
	recipients_report_id       INT(11) UNSIGNED AUTO_INCREMENT COMMENT 'Reference key',
	report_date                TIMESTAMP NOT NULL COMMENT 'Date of import or export',
	filename                   VARCHAR(100) NOT NULL COMMENT 'Imported filename',
	datasource_id              INTEGER COMMENT 'Used datasource id for import',
	admin_id                   INTEGER NOT NULL COMMENT 'admin which executed the import or export',
	company_id                 INTEGER NOT NULL COMMENT 'Referenced client',
	report                     TEXT COMMENT 'Report text (HTML)',
	type                       VARCHAR(15) NOT NULL COMMENT 'Import or export',
	download_id                INTEGER COMMENT 'Id of downloadable export file',
	autoimport_id              INTEGER COMMENT 'Reference id of the autoimport used for this reports import',
	error                      INTEGER COMMENT 'Flag to show if this report contains description of an data error',
	content                    LONGBLOB COMMENT 'Report data as file',
	PRIMARY KEY (recipients_report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Report on executed recipient imports and exports';

CREATE TABLE birtreport_tbl (
	report_id                  INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Reference key',
	company_id                 INT(10) UNSIGNED DEFAULT 0 COMMENT 'Refernced client',
	shortname                  VARCHAR(300) COMMENT 'Shortname for this report',
	description                VARCHAR(1000) COMMENT 'Description for this report',
	active                     INT(10) UNSIGNED DEFAULT 0 COMMENT 'Is this report activated',
	report_type                INT(10) UNSIGNED DEFAULT 0 COMMENT 'Report type like mailing report or recipients report',
	send_days                  VARCHAR(10) COMMENT 'Weekdays to send this report',
	format                     INT(10) UNSIGNED DEFAULT 0 COMMENT 'Data format like pdf or csv',
	email                      VARCHAR(200) COMMENT 'Emailaddress to send this report to',
	email_subject              VARCHAR(200) COMMENT 'Email subject',
	email_description          VARCHAR(1000) COMMENT 'Email text',
	send_time                  TIMESTAMP NULL COMMENT 'Time to send this report on days defined in send_days',
	send_date                  TIMESTAMP NULL COMMENT 'Next send date',
	creation_date              TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation date of this report definition',
	activation_date            TIMESTAMP NULL COMMENT 'Date this report was activated',
	end_date                   TIMESTAMP NULL COMMENT 'Last date this report should be delivered',
	active_tab                 INT(1) DEFAULT 1 NOT NULL COMMENT 'default tab to be shown in GUI',
	language                   VARCHAR(10) COMMENT 'Language to create report data in',
	hidden                     INT DEFAULT 0 NOT NULL COMMENT 'Do not show this report in EMM-GUI',
	delivery_date              TIMESTAMP NULL COMMENT 'Date of the last sending of a report',
	change_date                TIMESTAMP NULL COMMENT 'Change date of this report definition',
	PRIMARY KEY  (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Definition of preconfigured reports to be created by birt and sent via email';

CREATE TABLE birtreport_sent_mailings_tbl (
	report_id                  INT(11) COMMENT 'Referenced birtreport_tbl',
	mailing_id                 INT(11) COMMENT 'Report for mailing',
	company_id                 INT(11) COMMENT 'Refernced client',
	delivery_date              TIMESTAMP NULL COMMENT 'Date of delivery per email'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Delivery statistics of birt reports';

CREATE TABLE birtreport_parameter_tbl (
	report_id                  INT(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Referenced birtreport',
	parameter_name             VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'Parameter name',
	parameter_value            VARCHAR(4000) NOT NULL DEFAULT '' COMMENT 'Parameter value',
	report_type                INT(11) COMMENT 'Report type like mailing report or recipients report',
	change_date                TIMESTAMP NULL,
	KEY report_id (report_id),
	CONSTRAINT birtreport_parameter_tbl_ibfk_1 FOREIGN KEY (report_id) REFERENCES birtreport_tbl (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Stores additional configuration for birt reports of birtreport_tbl';

CREATE TABLE birt_report_tmp_tbl_seq (
	value                      INT(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO birt_report_tmp_tbl_seq (value) VALUES (1);

CREATE TABLE mimetype_whitelist_tbl (
	mimetype                   VARCHAR(100) NOT NULL COMMENT 'Mimetype pattern (can include asterisk)',
	description                VARCHAR(100) COMMENT 'Optional description',
	creation_date              TIMESTAMP NOT NULL COMMENT 'Timestamp of creating record'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT 'Whitelist for Mimetypes supported for uploads';

DELIMITER ;;
CREATE PROCEDURE emm_log_db_errors(IN p_error_message VARCHAR(255), IN p_company_id INT(11), IN p_module_name VARCHAR(255))
BEGIN
	DECLARE v_client_info VARCHAR(500);
	SET v_client_info = (SELECT user());
	INSERT INTO emm_db_errorlog_tbl (company_id, errortext, module_name, client_info) VALUES (p_company_id, p_error_message, p_module_name, v_client_info);
END;;
DELIMITER ;

DELIMITER ;;
CREATE TRIGGER mailing_account_sum_trg
AFTER INSERT ON mailing_account_tbl
FOR EACH ROW
BEGIN
	DECLARE v_mintime      TIMESTAMP;
	DECLARE v_maxtime      TIMESTAMP;
	DECLARE v_mailing_id   INT(11);
	DECLARE v_status_field VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
	
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT;
		CALL emm_log_db_errors(@msg, 0, 'mailing_account_sum_trg');
	END;

	SET v_mailing_id = new.mailing_id;
	SET v_status_field = new.status_field COLLATE utf8mb4_unicode_ci;

	IF ((SELECT mintime FROM mailing_account_sum_tbl WHERE mailing_id = v_mailing_id AND status_field = v_status_field) IS NULL) THEN
		INSERT INTO mailing_account_sum_tbl (mailing_id, company_id, no_of_mailings, no_of_bytes, mintime, maxtime, status_field)
		VALUES (new.mailing_id, new.company_id, new.no_of_mailings, new.no_of_bytes, new.timestamp, new.timestamp, new.status_field);
	ELSE
		SET v_mintime = (SELECT mintime FROM mailing_account_sum_tbl WHERE mailing_id = v_mailing_id AND status_field = v_status_field);
		SET v_maxtime = (SELECT maxtime FROM mailing_account_sum_tbl WHERE mailing_id = v_mailing_id AND status_field = v_status_field);

		IF (new.timestamp > v_maxtime) THEN
			UPDATE mailing_account_sum_tbl
			SET maxtime = new.timestamp
			WHERE mailing_id = new.mailing_id
			AND status_field = v_status_field;
		END IF;

		UPDATE mailing_account_sum_tbl
			SET no_of_mailings = no_of_mailings + new.no_of_mailings,
			no_of_bytes = no_of_bytes + new.no_of_bytes
			WHERE mailing_id = new.mailing_id
			AND status_field = new.status_field;
	END IF;
END;;
DELIMITER ;

INSERT INTO config_tbl (class, name, value) VALUES ('system', 'url', '[to be defined]');
INSERT INTO config_tbl (class, name, value) VALUES ('expire', 'SuccessDef', '180');
INSERT INTO config_tbl (class, name, value) VALUES ('logon', 'iframe.url.en', 'https://www.agnitas.de/en/openemm-login/');
INSERT INTO config_tbl (class, name, value) VALUES ('logon', 'iframe.url.de', 'https://www.agnitas.de/openemm-login/');

INSERT INTO sourcegroup_tbl (sourcegroup_id, sourcegroup_type, description, timestamp, creation_date) VALUES
	(1, 'A', 'Subscriber Interface', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(2, 'D', 'File', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(3, 'O', 'Other', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(4, 'FO', 'Autoinsert Forms', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(5, 'DD', 'default datasource for companies', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(6, 'WS', 'Webservices 2.0 - Spring', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO company_tbl (company_id, rdir_domain, shortname, description, status, mailtracking, creator_company_id, mailerset, customer_type, pricing_id, xor_key, send_immediately, offpeak, notification_email, mailloop_domain, expire_stat, max_fields, stat_admin, expire_bounce, expire_onepixel, expire_cookie, creation_date, timestamp, max_login_fails, login_block_time, sector, business_field, secret_key, mails_per_day, uid_version, expire_recipient, max_recipients, auto_mailing_report_active, salutation_extended, enabled_uid_version, expire_upload, maxadminmails, export_notify)
	VALUES (1, 'http://[to be defined]', 'EMM-Master', 'EMM-Master', 'active', 1, 1, 0, 'UNKNOWN', NULL, 12345, 0, 0, NULL, '[to be defined]', 1100, 0, 0, 0, 1100, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 3, 300, NULL, NULL, 'SecretKeyToBeDefined', NULL, NULL, 30, 10000, 0, 0, 3, 14, 100, 0);

INSERT INTO admin_tbl (admin_id, username, company_id, admin_group_id, admin_lang, admin_country) VALUES (1, 'emm-master', 1, 1, 'en', 'US');

INSERT INTO datasource_description_tbl (description, company_id, sourcegroup_id)
	VALUES ('Default Datasource', 1, (SELECT sourcegroup_id FROM sourcegroup_tbl WHERE sourcegroup_type = 'DD'));
UPDATE company_tbl SET default_datasource_id = (SELECT datasource_id FROM datasource_description_tbl WHERE company_id = 1 AND description = 'Default Datasource') WHERE company_id = 1;

INSERT INTO datasource_description_tbl (description, company_id, sourcegroup_id)
	VALUES ('Bulk recipient update', 0, (SELECT sourcegroup_id FROM sourcegroup_tbl WHERE sourcegroup_type = 'O'));

INSERT INTO company_info_tbl (company_id, cname, cvalue, description, creation_date, timestamp) VALUES
	(0, 'keep-xml-files', 'true', 'Admin-/Testmail XML Files nicht loeschen', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'use-extended-usertypes', 'true', 'USER_TYPE fuer VIP Verteiler ermoeglichen', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'url-default', 'http://UndefinedInCompanyInfoTbl', 'Bei fehlender RDIR_DOMAIN in der COMPANY_TBL wird diese URL genommen', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'expire-recv', '90', 'Expiration period for recv_xxx_tbl entries', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'expire-recipients-report', 90, 'Expiration period for recipients_report_tbl rows', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'host_authentication.authentication', 'disabled', 'Two way authentication', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'limit-block-operations', '500000', 'Splitting Merger Updates for customer_tbls', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'limit-block-operations-max', '5', 'Splitting Merger Updates for customer_tbls', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'imagelink-template', '%(rdir-domain)/image/%(licence-id)/%(company-id)/%(mailing-id)/[name]', 'Path-structure by default (EMM-4603)', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
	(0, 'imagelink-template-no-cache', '%(rdir-domain)/image/nc/%(licence-id)/%(company-id)/%(mailing-id)/[name]', 'Path-structure by default (EMM-4603)', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO rdir_action_tbl (company_id, shortname, description, action_type)
	VALUES (1, 'Web-View_SAMPLE', 'Fullview', 1);
INSERT INTO actop_tbl (company_id, type, action_id)
	VALUES (1, 'GetArchiveMailing', (SELECT action_id FROM rdir_action_tbl WHERE action_type = 1 AND shortname = 'Web-View_SAMPLE' AND company_id = 1));
INSERT INTO actop_get_archive_mailing_tbl (action_operation_id, expire_day, expire_month, expire_year)
	VALUES ((SELECT action_operation_id FROM actop_tbl WHERE company_id = 1 AND action_id = (SELECT action_id FROM rdir_action_tbl WHERE action_type = 1 AND shortname = 'Web-View_SAMPLE' AND company_id = 1)), 0, 0, 0);
INSERT INTO userform_tbl (company_id, formname, description, startaction_id, endaction_id, success_template, error_template,  creation_date, success_url, error_url, error_use_url, success_use_url)
	VALUES (1, 'webview_SAMPLE', 'Shows email in browser', (SELECT action_id FROM rdir_action_tbl WHERE action_type = 1 AND shortname = 'Web-View_SAMPLE' AND company_id = 1), 0, '$archiveHtml', 'An error occured - we cannot show you the email in the browser.', NULL, NULL, NULL, (SELECT action_id FROM rdir_action_tbl WHERE company_id = 1 AND shortname = 'GetArchiveMailing'), 0);

INSERT INTO emm_layout_base_tbl (layout_base_id, base_url, creation_date, change_date, company_id, shortname) VALUES (1, 'assets/core', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 'default');
UPDATE emm_layout_base_tbl SET layout_base_id = 0 WHERE layout_base_id = 1;
-- Autoincrement of layout_base_id does not allow to insert 0 directly

INSERT INTO click_stat_colors_tbl (id, company_id, range_start, range_end, color) VALUES
	(1, 0, 0, 5, 'F4F9FF'),
	(2, 0, 5, 10, 'D5E6FF'),
	(3, 0, 10, 15, 'E1F7E1'),
	(4, 0, 15, 20, 'FEFECC'),
	(5, 0, 20, 25, 'FFE4BA'),
	(6, 0, 25, 100, 'FFCBC3'),
	(7, 1, 0, 5, 'F4F9FF'),
	(8, 1, 5, 10, 'D5E6FF'),
	(9, 1, 10, 15, 'E1F7E1'),
	(10, 1, 15, 20, 'FEFECC'),
	(11, 1, 20, 25, 'FFE4BA'),
	(12, 1, 25, 100, 'FFCBC3');

INSERT INTO date_tbl (type, format) VALUES
	(0, 'd.M.yyyy'),
	(1, 'MM/dd/yyyy'),
	(2, 'EEEE, d. MMMM yyyy'),
	(3, 'yyyy-MM-dd'),
	(4, 'd. MMMM yyyy'),
	(5, 'EEEE, d MMMM yyyy'),
	(6, 'dd/MM/yyyy'),
	(7, 'yyyy/MM/dd'),
	(8, 'yyyy-MM-dd');

INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('image/*', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/pdf', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('text/plain', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('text/csv', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/zip', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/vnd.ms-excel', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/x-zip-compressed', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/msword', CURRENT_TIMESTAMP);
INSERT INTO mimetype_whitelist_tbl (mimetype, creation_date) VALUES ('application/vnd.openxmlformats-officedocument.wordprocessingml.document', CURRENT_TIMESTAMP);

INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('importStep2', 'assigning_the_csv_columns_to_t.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('userRights', 'assigning_user_rights.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('bounceFilter', 'bounce-filter.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('trackableLinkView', 'building_trackable_links_into_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('calendar', 'calendar_function.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('classicImport', 'classic_import.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('compareMailings', 'comparing_mailings.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('contentSource', 'content_sources.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newArchive', 'create_a_new_archive.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newMailingWizard', 'create_new_mailing_using_the_w.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newRecipient', 'create_new_recipients.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-view-setup', 'creating_a_contribution.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-view-setup', 'creating_a_div_container.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-view-setup', 'creating_a_grid.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newMailinglist', 'modifying_a_mailing_list.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newAction', 'creating_a_new_action.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newCompany', 'what_are_users_and_clients_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newImportProfile', 'creating_a_new_import_profile.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('createNewMailing', 'creating_a_new_mailing.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newUser', 'creating_a_new_user.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-list-setup', 'creating_and_managing_a_grid.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-category-list-setup', 'creating_and_managing_categori.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-list-setup', 'creating_and_managing_div_cont.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-list-setup', 'creating_and_managing_posts.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('targetGroupView', 'creating_and_managing_target_g.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-category-view-setup', 'creating_categories.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newProfileField', 'creating_new_fields.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-view-setup', 'creating_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('contentView', 'creating_text_and_html_modules.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('dashboard', 'dashboard.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('archiveView', 'display_and_amend_details.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newTemplateNormal', 'display_and_amend_details.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('domainStatistic', 'domain_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newMailingNormal', 'entering_basic_mailing_data.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newTemplate', 'entering_basic_template_data.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('importStep3', 'errorhandling.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('export', 'export_function_for_recipient_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('heatmap', 'heatmap.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('contentList', 'further_details_for_creating_t.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('ipStatistic', 'ip_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mailingList', 'list_existing_mailings.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mailingStatistic', 'click_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('manageProfile', 'managing_a_profile__deleting_a.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('actionList', 'managing_actions.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('workflow', 'managing_campaigns.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('manageFields', 'managing_fields.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('formList', 'managing_forms.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('profileFieldList', 'managing_profile_fields.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('recipientList', 'managing_recipients.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-list-setup', 'managing_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mailinglists', 'modifying_a_mailing_list.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('monthlyOverview', 'monthly_overview.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('recipientStatistic', 'recipient_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('sendMailing', 'send_mailing.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('attachments', 'further_details_for_creating_t.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('recipientView', 'show_recipient_profile.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mailingTestAndSend', 'testing_and_sending_a_mailing.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('importStep1', 'the_import_assistant.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('formView', 'this_is_how_forms_work.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('salutationForms', 'types_of_address.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('upload', 'upload_files.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-view-setup', 'uploading_a_background_image.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-list-setup', 'uploading_and_managing_backgro.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-list-setup', 'uploading_and_managing_images.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-view-setup', 'uploading_images_one-off_uploa.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-mass-upload-setup', 'uploading_images_volume_upload.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('userlog', 'user_log.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('user_self-administration', 'user_self-administration.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('pictureComponents', 'further_details_for_creating_t.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('templateList', 'what_are_templates_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('targetGroupList', 'what_is_a_traget_group_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('dashboard_calendar', 'what_is_the_calendar_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-view-new', 'creating_a_contribution.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-view-new', 'creating_a_div_container.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-view-view', 'creating_a_div_container.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-view-new', 'creating_a_grid.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-list-view', 'creating_and_managing_a_grid.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-category-list-view', 'creating_and_managing_categori.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-delete-view', 'creating_and_managing_div_cont.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-list-view', 'creating_and_managing_div_cont.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-list-view', 'creating_and_managing_posts.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-category-view-new', 'creating_categories.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-view-new', 'creating_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-view-view', 'creating_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newUserGroup', 'defining_own_user_groups.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('UserGroupDelete', 'defining_own_user_groups.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('UserGroupList', 'defining_own_user_groups.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-category-delete-view', 'editing_a_category.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-category-view-view', 'editing_a_category.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-delete-view', 'editing_a_contribution.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-view-view', 'editing_a_contribution.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-view-view', 'editing_an_image_entry.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-view-view', 'editing_background_image_entry.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-delete-view', 'editing_grids.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-view-view', 'editing_grids.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Grid', 'grid_cms.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('ipStatistics', 'ip_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mailingParameter', 'mailing_parameters.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-delete-view', 'managing_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-list-view', 'managing_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-view-new', 'uploading_a_background_image.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-bulk-delete-view', 'uploading_and_managing_backgro.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-delete-view', 'uploading_and_managing_backgro.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('grid-background-image-list-view', 'uploading_and_managing_backgro.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-list-view', 'uploading_and_managing_images.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-delete-view', 'uploading_and_managing_images.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-bulk-delete-view', 'uploading_and_managing_images.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-view-new', 'uploading_images_one-off_uploa.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('mediapool-image-mass-upload-view', 'uploading_images_volume_upload.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('topDomainStatistic', 'domain_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('help_workflow_edit', 'opening_a_campaign_in_the_edit.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('blacklist', 'blacklist_-_do_not_mail.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('reports', 'statistics_reports_by_e-mail.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('autoImport', 'auto_import.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('help_workflow_new', 'building_up_a_campaign_in_the_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('importStep4', 'importing_the_csv-file.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('autoExport', 'auto_export.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('NewGridMailing', 'creating_a_new_grid_mailing.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('autooptimization', 'auto-optimization_of_mailings.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('trackableLinks', 'further_details_for_creating_t.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('inboxPreview', 'automatic_pre-delivery_check_p.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('template-header-info-view', 'setting_delivery_options.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('pluginmanagerList', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('gridTemplate', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('ReferenceTables', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('feedbackAnalysis', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-container-generate-thumbnails-view', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('newTable', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('div-child-generate-thumbnails-view', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('supervisors', 'produktname_-_the_basics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('recipientHistory', 'recipient_history.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('recipientMailingHistory', 'mailing_history.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('managingUsers', 'managing_user.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('managingUserGroups', 'defining_own_user_groups.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('graphicsInForms', 'using_graphics_in_forms.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('trackpointsList', 'display_and_amend_details_for_.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('trackpointsEdit', 'creating_shop_tracking_points.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('socialNetworkStatistic', 'click_statistics_for_social_ne.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('openingProgressStatistic', 'opening_rate.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('bounceStatistic', 'bounce_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('revenueStatistic', 'statistical_evaluation2.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('deliveryProgressStatistic', 'delivery_progress.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('benchmarkStatistic', 'benchmark.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('top_domains_statistics', 'top_domains_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('action-based_mailing', 'action-based_mailing.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('searching_for_mailings', 'searching_for_mailings.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('the_tracking_point_revenue', 'the_tracking_point_revenue.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('creating_advanced_target_groups', 'creating_advanced_target_groups.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('manage_tables', 'manage_tables.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('creating_new_reference_tables', 'creating_new_reference_tables.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('defining_fields_tables', 'defining_fields_tables.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('adding_and_deleting_fields_tables', 'adding_and_deleting_fields_tables.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('editing_a_reference_table', 'editing_a_reference_table.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('import_tables', 'import_tables.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('export_tables', 'export_tables.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('retargeting_history', 'retargeting_history.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('E-Mail-Creator', 'e-mail_creator.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('create_a_mailing_E-Mail_Creator', 'create_a_mailing_e-mail-creator.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Content', 'content.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Styles', 'styles.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('File_attachments', 'file_attachments.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Links', 'links.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Preview', 'preview.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Sending_out_test_mails2', 'sending_out_test_mails2.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Mailing_statistic2', 'mailing_statistic2.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('clickstatistic_per_link', 'clickstatistic_per_link.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('progress_of_gross_openings', 'progress_of_gross_openings.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('summary', 'summary.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Progress_of_openings', 'progress_of_openings.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Content_blocks', 'content_blocks.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Heatmap2', 'heatmap2.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Recipients2', 'recipients2.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Using_image_elements', 'using_image_elements.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Create_trackable_and_non-track', 'create_trackable_and_non-track.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Statistics', 'statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Recipients', 'recipients.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('End_device_history', 'end_device_history.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Managing profile fields', 'managing_profile_fields.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Edit_field_content', 'edit_field_content.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Logs', 'logs.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Progress_of_clicks', 'progress_of_clicks.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('top_domains', 'top_domains.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('End_device_statistics', 'end_device_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Domain_overview', 'domain_overview.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('End_device_overview', 'end_device_overview.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Customer_Insights', 'customer_insights.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Approval', 'approval.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Manage_create_send_and_evaluate_push_notifications', 'what_are_web_push_notifications.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Create_a_new_push_notification', 'creating_a_new_push_notification.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Shipping_settings_and_statistics_for_push', 'shipping_settings_and_statistics_for_push_notification.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Push-trigger_notifications', 'push_trigger_notifications.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Push_statistics', 'push_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('User', 'user.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('User_approval', 'user_approval.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Clients', 'clients.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Create_new_voucher_code_table', 'create_new_voucher_code_table.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Create_and_manage_templates', 'create_and_manage_templates.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Create_template', 'create_template.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Edit_template', 'edit_template.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('End_device_statistic2', 'end_device_overview.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('End_device_statistic', 'end_device_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('Recipient_Insights', 'insights.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('supervisor-permissions', 'supervisor-permissions.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('push_global_statistics', 'push_statistics.htm');
INSERT INTO doc_mapping_tbl (pagekey, filename) VALUES ('push_notification_view', 'shipping_settings_and_statistics_for_push_notification.htm');

INSERT INTO dyn_target_tbl (target_id, company_id, mailinglist_id, target_shortname, target_sql, target_description, target_representation, deleted, change_date, creation_date, admin_test_delivery, locked) VALUES
	(1, 0, 0, '__listsplit_050505050575_1', 'mod(cust.CUSTOMER_ID, 20) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(2, 0, 0, '__listsplit_050505050575_2', 'mod(cust.CUSTOMER_ID, 20) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(3, 0, 0, '__listsplit_050505050575_3', 'mod(cust.CUSTOMER_ID, 20) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(4, 0, 0, '__listsplit_050505050575_4', 'mod(cust.CUSTOMER_ID, 20) = 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(5, 0, 0, '__listsplit_050505050575_5', 'mod(cust.CUSTOMER_ID, 20) = 4', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(6, 0, 0, '__listsplit_050505050575_6', 'mod(cust.CUSTOMER_ID, 20) >= 5', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(7, 0, 0, '__listsplit_0505050580_1', 'mod(cust.CUSTOMER_ID, 20) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(8, 0, 0, '__listsplit_0505050580_2', 'mod(cust.CUSTOMER_ID, 20) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(9, 0, 0, '__listsplit_0505050580_3', 'mod(cust.CUSTOMER_ID, 20) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(10, 0, 0, '__listsplit_0505050580_4', 'mod(cust.CUSTOMER_ID, 20) = 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(11, 0, 0, '__listsplit_0505050580_5', 'mod(cust.CUSTOMER_ID, 20) >= 4', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(12, 0, 0, '__listsplit_05050585_1', 'mod(cust.CUSTOMER_ID, 20) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(13, 0, 0, '__listsplit_05050585_2', 'mod(cust.CUSTOMER_ID, 20) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(14, 0, 0, '__listsplit_05050585_3', 'mod(cust.CUSTOMER_ID, 20) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(15, 0, 0, '__listsplit_05050585_4', 'mod(cust.CUSTOMER_ID, 20) >= 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(16, 0, 0, '__listsplit_101010101050_1', 'mod(cust.CUSTOMER_ID, 10) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(17, 0, 0, '__listsplit_101010101050_2', 'mod(cust.CUSTOMER_ID, 10) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(18, 0, 0, '__listsplit_101010101050_3', 'mod(cust.CUSTOMER_ID, 10) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(19, 0, 0, '__listsplit_101010101050_4', 'mod(cust.CUSTOMER_ID, 10) = 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(20, 0, 0, '__listsplit_101010101050_5', 'mod(cust.CUSTOMER_ID, 10) = 4', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(21, 0, 0, '__listsplit_101010101050_6', 'mod(cust.CUSTOMER_ID, 10) >= 5', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(22, 0, 0, '__listsplit_1010101060_1', 'mod(cust.CUSTOMER_ID, 10) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(23, 0, 0, '__listsplit_1010101060_2', 'mod(cust.CUSTOMER_ID, 10) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(24, 0, 0, '__listsplit_1010101060_3', 'mod(cust.CUSTOMER_ID, 10) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(25, 0, 0, '__listsplit_1010101060_4', 'mod(cust.CUSTOMER_ID, 10) = 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(26, 0, 0, '__listsplit_1010101060_5', 'mod(cust.CUSTOMER_ID, 10) >= 4', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(27, 0, 0, '__listsplit_10101070_1', 'mod(cust.CUSTOMER_ID, 10) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(28, 0, 0, '__listsplit_10101070_2', 'mod(cust.CUSTOMER_ID, 10) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(29, 0, 0, '__listsplit_10101070_3', 'mod(cust.CUSTOMER_ID, 10) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(30, 0, 0, '__listsplit_10101070_4', 'mod(cust.CUSTOMER_ID, 10) >= 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(31, 0, 0, '__listsplit_101080_1', 'mod(cust.CUSTOMER_ID, 10) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(32, 0, 0, '__listsplit_101080_2', 'mod(cust.CUSTOMER_ID, 10) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(33, 0, 0, '__listsplit_101080_3', 'mod(cust.CUSTOMER_ID, 10) > 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(34, 0, 0, '__listsplit_1090_10', 'mod(cust.CUSTOMER_ID, 10) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(35, 0, 0, '__listsplit_1090_90', 'mod(cust.CUSTOMER_ID, 10) > 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(36, 0, 0, '__listsplit_151570_1', 'mod(cust.CUSTOMER_ID, 100) < 15', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(37, 0, 0, '__listsplit_151570_2', 'mod(cust.CUSTOMER_ID, 100) > 14 AND mod(cust.CUSTOMER_ID, 100) < 30', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(38, 0, 0, '__listsplit_151570_3', 'mod(cust.CUSTOMER_ID, 100) > 29', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(39, 0, 0, '__listsplit_2080_20', 'mod(cust.CUSTOMER_ID, 10) < 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(40, 0, 0, '__listsplit_2080_80', 'mod(cust.CUSTOMER_ID, 10) > 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(41, 0, 0, '__listsplit_25252525_1', 'mod(cust.CUSTOMER_ID, 4) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(42, 0, 0, '__listsplit_25252525_2', 'mod(cust.CUSTOMER_ID, 4) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(43, 0, 0, '__listsplit_25252525_3', 'mod(cust.CUSTOMER_ID, 4) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(44, 0, 0, '__listsplit_25252525_4', 'mod(cust.CUSTOMER_ID, 4) = 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(45, 0, 0, '__listsplit_252550_1', 'mod(cust.CUSTOMER_ID, 4) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(46, 0, 0, '__listsplit_252550_2', 'mod(cust.CUSTOMER_ID, 4) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(47, 0, 0, '__listsplit_252550_3', 'mod(cust.CUSTOMER_ID, 4) > 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(48, 0, 0, '__listsplit_3070_30', 'mod(cust.CUSTOMER_ID, 100) < 30', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(49, 0, 0, '__listsplit_3070_70', 'mod(cust.CUSTOMER_ID, 100) > 29', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(50, 0, 0, '__listsplit_333333_1', 'mod(cust.CUSTOMER_ID, 3) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(51, 0, 0, '__listsplit_333333_2', 'mod(cust.CUSTOMER_ID, 3) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(52, 0, 0, '__listsplit_333333_3', 'mod(cust.CUSTOMER_ID, 3) = 2', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(53, 0, 0, '__listsplit_4060_40', 'mod(cust.CUSTOMER_ID, 10) < 4', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(54, 0, 0, '__listsplit_4060_60', 'mod(cust.CUSTOMER_ID, 10) > 3', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(55, 0, 0, '__listsplit_5050_1', 'mod(cust.CUSTOMER_ID, 2) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(56, 0, 0, '__listsplit_5050_2', 'mod(cust.CUSTOMER_ID, 2) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(57, 0, 0, '__listsplit_050590_1', 'mod(cust.CUSTOMER_ID, 20) = 0', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(58, 0, 0, '__listsplit_050590_2', 'mod(cust.CUSTOMER_ID, 20) = 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1),
	(59, 0, 0, '__listsplit_050590_3', 'mod(cust.CUSTOMER_ID, 20) > 1', NULL, NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, 1);

INSERT INTO dyn_target_tbl (company_id, target_shortname, target_sql, target_description, deleted, change_date, creation_date, admin_test_delivery, locked, component_hide, invalid, hidden, target_representation)
	VALUES (1, 'Gender Male', '(cust.GENDER = 0)', NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, NULL, 0, 0, 0, UNHEX('ACED0005737200306F72672E61676E697461732E7461726765742E696D706C2E546172676574526570726573656E746174696F6E496D706CB8F6FC8363F901CD0200014C0008616C6C4E6F6465737400104C6A6176612F7574696C2F4C6973743B7870737200136A6176612E7574696C2E41727261794C6973747881D21D99C7619D03000149000473697A65787000000001770400000001737200296F72672E61676E697461732E7461726765742E696D706C2E5461726765744E6F64654E756D657269635C83C687D5C13A4E02000949000D636861696E4F70657261746F725A0011636C6F7365427261636B657441667465725A00116F70656E427261636B65744265666F726549000F7072696D6172794F70657261746F724900117365636F6E646172794F70657261746F7249000E7365636F6E6461727956616C75654C000C7072696D6172794669656C647400124C6A6176612F6C616E672F537472696E673B4C00107072696D6172794669656C645479706571007E00064C000C7072696D61727956616C756571007E0006787000000000000000000001000000000000000074000647454E444552740006444F55424C457400013078'));
INSERT INTO dyn_target_tbl (company_id, target_shortname, target_sql, target_description, deleted, change_date, creation_date, admin_test_delivery, locked, component_hide, invalid, hidden, target_representation)
	VALUES (1, 'Gender Female', '(cust.GENDER = 1)', NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, NULL, 0, 0, 0, UNHEX('ACED0005737200306F72672E61676E697461732E7461726765742E696D706C2E546172676574526570726573656E746174696F6E496D706CB8F6FC8363F901CD0200014C0008616C6C4E6F6465737400104C6A6176612F7574696C2F4C6973743B7870737200136A6176612E7574696C2E41727261794C6973747881D21D99C7619D03000149000473697A65787000000001770400000001737200296F72672E61676E697461732E7461726765742E696D706C2E5461726765744E6F64654E756D657269635C83C687D5C13A4E02000949000D636861696E4F70657261746F725A0011636C6F7365427261636B657441667465725A00116F70656E427261636B65744265666F726549000F7072696D6172794F70657261746F724900117365636F6E646172794F70657261746F7249000E7365636F6E6461727956616C75654C000C7072696D6172794669656C647400124C6A6176612F6C616E672F537472696E673B4C00107072696D6172794669656C645479706571007E00064C000C7072696D61727956616C756571007E0006787000000000000000000001000000000000000074000647454E444552740006444F55424C457400013178'));
INSERT INTO dyn_target_tbl (company_id, target_shortname, target_sql, target_description, deleted, change_date, creation_date, admin_test_delivery, locked, component_hide, invalid, hidden, target_representation)
	VALUES (1, 'Gender Unknown', '(cust.GENDER = 2)', NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, NULL, 0, 0, 0, UNHEX('ACED0005737200306F72672E61676E697461732E7461726765742E696D706C2E546172676574526570726573656E746174696F6E496D706CB8F6FC8363F901CD0200014C0008616C6C4E6F6465737400104C6A6176612F7574696C2F4C6973743B7870737200136A6176612E7574696C2E41727261794C6973747881D21D99C7619D03000149000473697A65787000000001770400000001737200296F72672E61676E697461732E7461726765742E696D706C2E5461726765744E6F64654E756D657269635C83C687D5C13A4E02000949000D636861696E4F70657261746F725A0011636C6F7365427261636B657441667465725A00116F70656E427261636B65744265666F726549000F7072696D6172794F70657261746F724900117365636F6E646172794F70657261746F7249000E7365636F6E6461727956616C75654C000C7072696D6172794669656C647400124C6A6176612F6C616E672F537472696E673B4C00107072696D6172794669656C645479706571007E00064C000C7072696D61727956616C756571007E0006787000000000000000000001000000000000000074000647454E444552740006444F55424C457400013278'));
INSERT INTO dyn_target_tbl (company_id, target_shortname, target_sql, target_description, deleted, change_date, creation_date, admin_test_delivery, locked, component_hide, invalid, hidden, target_representation)
	VALUES (1, 'Openers and Clickers', '((cust.LASTCLICK_DATE IS NOT NULL) AND ((cust.LASTOPEN_DATE IS NOT NULL) AND (cust.LASTSEND_DATE IS NOT NULL)))', NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, NULL, 0, 0, 0, UNHEX('ACED0005737200306F72672E61676E697461732E7461726765742E696D706C2E546172676574526570726573656E746174696F6E496D706CB8F6FC8363F901CD0200014C0008616C6C4E6F6465737400104C6A6176612F7574696C2F4C6973743B7870737200136A6176612E7574696C2E41727261794C6973747881D21D99C7619D03000149000473697A65787000000003770400000003737200266F72672E61676E697461732E7461726765742E696D706C2E5461726765744E6F646544617465A07381E091CC113202000849000D636861696E4F70657261746F725A0011636C6F7365427261636B657441667465725A00116F70656E427261636B65744265666F726549000F7072696D6172794F70657261746F724C000A64617465466F726D61747400124C6A6176612F6C616E672F537472696E673B4C000C7072696D6172794669656C6471007E00064C00107072696D6172794669656C645479706571007E00064C000C7072696D61727956616C756571007E0006787000000000000000000008740008797979796D6D646474000E4C415354434C49434B5F44415445740004444154457400086E6F74206E756C6C7371007E00050000000100000000000871007E000874000D4C4153544F50454E5F4441544571007E000A7400086E6F74206E756C6C7371007E00050000000100000000000871007E000874000D4C41535453454E445F4441544571007E000A7400086E6F74206E756C6C78'));

INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('BirtReports', CURRENT_TIMESTAMP, NULL, 0, 'OK', 0, 0, '***0;***5', CURRENT_TIMESTAMP, NULL, 'com.agnitas.emm.core.birtreport.service.ComBirtReportJobWorker', '0');

INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('LoginTrackTableCleaner', CURRENT_TIMESTAMP, NULL, 0, 'OK', 0, 0, '0400', CURRENT_TIMESTAMP, NULL, 'org.agnitas.util.quartz.LoginTrackTableCleanerJobWorker', 0);
INSERT INTO job_queue_parameter_tbl (job_id, parameter_name, parameter_value) VALUES ((SELECT id FROM job_queue_tbl WHERE description = 'LoginTrackTableCleaner'), 'retentionTime', '14');
INSERT INTO job_queue_parameter_tbl (job_id, parameter_name, parameter_value) VALUES ((SELECT id FROM job_queue_tbl WHERE description = 'LoginTrackTableCleaner'), 'deleteBlockSize', '1000');

INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('CalendarCommentMailingService', CURRENT_TIMESTAMP, NULL, 0, 'OK', 0, 0, '**00', CURRENT_TIMESTAMP, NULL, 'com.agnitas.emm.core.calendar.service.ComCalendarCommentMailingServiceJobWorker', 0);
INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('DeletedContentblockCleaner', CURRENT_TIMESTAMP, NULL, '0', 'OK', 0, 0, '0135', CURRENT_TIMESTAMP, NULL, 'com.agnitas.service.job.DeletedContentblockCleanerJobWorker', 0);
INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('UndoRelictCleaner', CURRENT_TIMESTAMP, NULL, 0, 'OK', 0, 0, '0130', CURRENT_TIMESTAMP, NULL, 'com.agnitas.service.job.UndoRelictCleanerJobWorker', 0);
INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('AutoOptimization', CURRENT_TIMESTAMP, NULL, 0, 'OK', 0, 0, '***0;***5', CURRENT_TIMESTAMP, NULL, 'com.agnitas.mailing.autooptimization.service.ComOptimizationJobWorker', 0);
INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('DBErrorCheck', CURRENT_TIMESTAMP, NULL, 0, 'OK', 0, 0, '**00', CURRENT_TIMESTAMP, NULL, 'org.agnitas.util.quartz.DBErrorCheckJobWorker', 0);
	
INSERT INTO job_queue_tbl (description, created, laststart, running, lastresult, startaftererror, lastduration, `interval`, nextstart, hostname, runclass, deleted)
	VALUES ('AggregateRdirTrafficStatisticJobWorker', CURRENT_TIMESTAMP, null, 0, 'OK', 0, 0, '0000', CURRENT_TIMESTAMP, null, 'com.agnitas.service.job.AggregateRdirTrafficStatisticJobWorker', 0);

INSERT INTO mailinglist_tbl (company_id, description, shortname, auto_url, remove_data, rdir_domain, creation_date, change_date)
	VALUES (1, 'Default, please do not delete!', 'Default-Mailinglist', NULL, '0', NULL, NULL, NULL);

INSERT INTO tag_tbl (tagname, selectvalue, type, company_id, description) VALUES
	('agnFIRSTNAME', 'cust.firstname', 'SIMPLE', 0, ''),
	('agnLASTNAME', 'cust.lastname', 'SIMPLE', 0, ''),
	('agnAUTOURL', 'cust.mailtype', 'COMPLEX', 0, ''),
	('agnEMAIL', '', 'SIMPLE', 0, ''),
	('agnCUSTOMERID', 'cust.customer_id', 'SIMPLE', 0, ''),
	('agnITAS', '''Hello World''', 'SIMPLE', 0, ''),
	('agnMAILTYPE', 'cust.mailtype', 'SIMPLE', 0, ''),
	('agnPROFILE', '''[rdir-domain]/form.do?agnCI=[company-id]&agnFN=profile&agnUID=##AGNUID##''', 'COMPLEX', 0, 'create a link to an emm-profile-form'),
	('agnUNSUBSCRIBE', '''[rdir-domain]/form.do?agnCI=[company-id]&agnFN=unsubscribe&agnUID=##AGNUID##''', 'COMPLEX', 0, 'create a link to an emm-unsubscribe-form'),
	('agnDATE', '', 'SIMPLE', 0, 'Dummy Tag for Preview'),
	('agnTITLE', 'title1({type}, [company-id], cust.customer_id)', 'COMPLEX', 0, 'shows title - print out title, lastname - by tw'),
	('agnTITLEFULL', '', 'COMPLEX', 0, 'shows title - print out title, firstname, lastname - by tw'),
	('agnFORM', '''[rdir-domain]/form.do?agnCI=[company-id]&agnFN={name}&agnUID=##AGNUID##''', 'COMPLEX', 0, 'create a link to an emm-form'),
	('agnDB', '', 'COMPLEX', 0, 'Selects a generic column from DB'),
	('agnSUBSCRIBERCOUNT', '', 'SIMPLE', 0, 'Dummy-Tag for Preview'),
	('agnIMAGE', '', 'COMPLEX', 0, 'Generates URL for hosted images'),
	('agnIMGLINK', '', 'COMPLEX', 0, ''),
	('agnALTER', 'TIMESTAMPDIFF(YEAR, cust.{column}, CURRENT_TIMESTAMP)', 'COMPLEX', 0, 'Returns years from column value until now'),
	('agnDATEDB', 'to_char(cust.{column}, ''{format}'')', 'COMPLEX', 0, 'returns date value in column custom formatted'),
	('agnCUSTOMDATE', 'DATE_FORMAT(DATE_ADD(CURRENT_TIMESTAMP, INTERVAL {offset} DAY), ''{format}'')', 'COMPLEX', 0, 'Adds an offset in days to the sysdate value and returns the formatted date'),
	('agnDATEDB_DE', 'rtrim(ltrim(to_char(cust.{column}, ''{format}'', ''nls_date_language = german'')))', 'COMPLEX', 0, 'Returns date in column custom formatted in german lang'),
	('agnCUSTOMDATE_DE', 'DATE_FORMAT(DATE_ADD(CURRENT_TIMESTAMP, INTERVAL {offset} DAY), ''{format}'')', 'COMPLEX', 0, 'Adds an offset in days to the sysdate value and returns the formatted date in german lang'),
	('agnTITLE_SHORT', 'title_short({type}, cust.gender)', 'COMPLEX', 0, 'Returns title without Names'),
	('agnDBV', '', 'COMPLEX', 0, 'Selects a virtual column not existing in DB'),
	('agnTITLEFIRST', '', 'COMPLEX', 0, 'shows title - print out firstname'),
	('agnDAYS_UNTIL', 'DATEDIFF(cust.{column}, CURRENT_TIMESTAMP)', 'COMPLEX', 0, 'Returns days until endday (endday MUST lie in future!!!)'),
	('agnNULL', '''''', 'FUNCTION', 0, 'Created by script-tag'),
	('agnCALC', 'cust.{column} {op} {value}', 'COMPLEX', 0, 'calculate with NUM-Field'),
	('agnCALC2', '{value} {op} cust.{column}', 'COMPLEX', 0, 'Calculate with NUM-Fields'),
	('agnDYN', 'agnDYN textComponent {name}', 'FLOW', 0, 'agnDYN-Tag works optionally with agnDVALUE'),
	('agnDVALUE', 'agnDVALUE textComponent {name}', 'FLOW', 0, 'agnDVALUE-Tag works only with agnDYN'),
	('agnALTERCALC', 'TIMESTAMPDIFF(YEAR, cust.{column}, CURRENT_TIMESTAMP) {op} {value}', 'COMPLEX', 0, 'like agnALTER with operator and value'),
	('agnDATEDB_LANG', 'to_char(cust.{column}, ''{format}'', ''nls_date_language = {lang}'')', 'COMPLEX', 0, 'Returns date in column custom formatted in given language'),
	('agnYEARCALC', 'to_char (cust.{field}, ''YYYY'') {op} {value}', 'COMPLEX', 0, 'to calculate with column'),
	('agnYEARCALC_F', 'to_char (cust.{column}, ''{format}'') {op} {value}', 'COMPLEX', 0, 'like agnYEARCALC with formating the date'),
	('agnUID', '''''', 'SIMPLE', 0, 'agnUID'),
	('agnMESSAGEID', '''''', 'SIMPLE', 0, 'Dummy content replaced by merger');

INSERT INTO title_gender_tbl (title_id, gender, title) VALUES
	(1, 0, 'Sehr geehrter Herr'),
	(1, 1, 'Sehr geehrte Frau'),
	(1, 2, 'Sehr geehrte Damen und Herren');

INSERT INTO title_tbl (title_id, company_id, description) VALUES (1, 0, '');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Sehr geehrter Herr/Sehr geehrte Frau/Sehr geehrte Damen und Herren');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE company_id = 0 AND description = 'Sehr geehrter Herr/Sehr geehrte Frau/Sehr geehrte Damen und Herren'), 0, 'Sehr geehrter Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE company_id = 0 AND description = 'Sehr geehrter Herr/Sehr geehrte Frau/Sehr geehrte Damen und Herren'), 1, 'Sehr geehrte Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE company_id = 0 AND description = 'Sehr geehrter Herr/Sehr geehrte Frau/Sehr geehrte Damen und Herren'), 2, 'Sehr geehrte Damen und Herren');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Hallo Herr/Hallo Frau/Hallo lieber Kunde');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE company_id = 0 AND description = 'Hallo Herr/Hallo Frau/Hallo lieber Kunde'), 0, 'Hallo Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE company_id = 0 AND description = 'Hallo Herr/Hallo Frau/Hallo lieber Kunde'), 1, 'Hallo Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE company_id = 0 AND description = 'Hallo Herr/Hallo Frau/Hallo lieber Kunde'), 2, 'Hallo lieber Kunde');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Hallo Herr/Hallo Frau/Hallo lieber Leser');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hallo Herr/Hallo Frau/Hallo lieber Leser' AND company_id = 0), 0, 'Hallo Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hallo Herr/Hallo Frau/Hallo lieber Leser' AND company_id = 0), 1, 'Hallo Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hallo Herr/Hallo Frau/Hallo lieber Leser' AND company_id = 0), 2, 'Hallo lieber Leser');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Lieber Herr/Liebe Frau/Liebe Damen und Herren');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Liebe Damen und Herren' AND company_id = 0), 0, 'Lieber Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Liebe Damen und Herren' AND company_id = 0), 1, 'Liebe Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Liebe Damen und Herren' AND company_id = 0), 2, 'Liebe Damen und Herren');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Lieber Herr/Liebe Frau/Lieber Kunde');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Lieber Kunde' AND company_id = 0), 0, 'Lieber Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Lieber Kunde' AND company_id = 0), 1, 'Liebe Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Lieber Kunde' AND company_id = 0), 2, 'Lieber Kunde');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Lieber Herr/Liebe Frau/Lieber Leser');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Lieber Leser' AND company_id = 0), 0, 'Lieber Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Lieber Leser' AND company_id = 0), 1, 'Liebe Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Lieber Herr/Liebe Frau/Lieber Leser' AND company_id = 0), 2, 'Lieber Leser');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'lieber Herr/liebe Frau/liebe Damen und Herren');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/liebe Damen und Herren' AND company_id = 0), 0, 'lieber Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/liebe Damen und Herren' AND company_id = 0), 1, 'liebe Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/liebe Damen und Herren' AND company_id = 0), 2, 'liebe Damen und Herren');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'lieber Herr/liebe Frau/lieber Kunde');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/lieber Kunde' AND company_id = 0), 0, 'lieber Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/lieber Kunde' AND company_id = 0), 1, 'liebe Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/lieber Kunde' AND company_id = 0), 2, 'lieber Kunde');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'lieber Herr/liebe Frau/lieber Leser');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/lieber Leser' AND company_id = 0), 0, 'lieber Herr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/lieber Leser' AND company_id = 0), 1, 'liebe Frau');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'lieber Herr/liebe Frau/lieber Leser' AND company_id = 0), 2, 'lieber Leser');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Dear Mr/Dear Mrs/Dear Sir or Madam');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear Mr/Dear Mrs/Dear Sir or Madam' AND company_id = 0), 0, 'Dear Mr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear Mr/Dear Mrs/Dear Sir or Madam' AND company_id = 0), 1, 'Dear Mrs');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear Mr/Dear Mrs/Dear Sir or Madam' AND company_id = 0), 2, 'Dear Sir or Madam');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'dear Mr/dear Mrs/dear Sir or Madam');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear Mr/dear Mrs/dear Sir or Madam' AND company_id = 0), 0, 'dear Mr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear Mr/dear Mrs/dear Sir or Madam' AND company_id = 0), 1, 'dear Mrs');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear Mr/dear Mrs/dear Sir or Madam' AND company_id = 0), 2, 'dear Sir or Madam');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Dear/Dear/Dear Sir or Madam');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear/Dear/Dear Sir or Madam' AND company_id = 0), 0, 'Dear');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear/Dear/Dear Sir or Madam' AND company_id = 0), 1, 'Dear');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear/Dear/Dear Sir or Madam' AND company_id = 0), 2, 'Dear Sir or Madam');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'dear/dear/dear Sir or Madam');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear/dear/dear Sir or Madam' AND company_id = 0), 0, 'dear');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear/dear/dear Sir or Madam' AND company_id = 0), 1, 'dear');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear/dear/dear Sir or Madam' AND company_id = 0), 2, 'dear Sir or Madam');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Dear Mr/Dear Mrs/Ladies and Gentleman');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear Mr/Dear Mrs/Ladies and Gentleman' AND company_id = 0), 0, 'Dear Mr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear Mr/Dear Mrs/Ladies and Gentleman' AND company_id = 0), 1, 'Dear Mrs');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Dear Mr/Dear Mrs/Ladies and Gentleman' AND company_id = 0), 2, 'Ladies and Gentleman');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'dear Mr/dear Mrs/Ladies and Gentleman');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear Mr/dear Mrs/Ladies and Gentleman' AND company_id = 0), 0, 'dear Mr');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear Mr/dear Mrs/Ladies and Gentleman' AND company_id = 0), 1, 'dear Mrs');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'dear Mr/dear Mrs/Ladies and Gentleman' AND company_id = 0), 2, 'Ladies and Gentleman');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Hello/Hello/Hello reader');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hello/Hello/Hello reader' AND company_id = 0), 0, 'Hello');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hello/Hello/Hello reader' AND company_id = 0), 1, 'Hello');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hello/Hello/Hello reader' AND company_id = 0), 2, 'Hello reader');

INSERT INTO title_tbl (company_id, description) VALUES (0, 'Hello/Hello/Hello customer');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hello/Hello/Hello customer' AND company_id = 0), 0, 'Hello');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hello/Hello/Hello customer' AND company_id = 0), 1, 'Hello');
INSERT INTO title_gender_tbl (title_id, gender, title) VALUES ((SELECT MAX(title_id) FROM title_tbl WHERE description = 'Hello/Hello/Hello customer' AND company_id = 0), 2, 'Hello customer');

DELIMITER ;;
CREATE PROCEDURE createIndices()
BEGIN
	DECLARE sqlStatus INT DEFAULT 0;
	-- Catch the error if MySQL doesn't support fulltext indices (#1214)
	DECLARE CONTINUE HANDLER FOR 1214 SET sqlStatus = 1214;
	-- Do nothing, just eat the exception
	BEGIN
		CREATE FULLTEXT INDEX mailing$sname$idx ON mailing_tbl(shortname);
		CREATE FULLTEXT INDEX mailing$descr$idx ON mailing_tbl(description);
		CREATE FULLTEXT INDEX component$emmblock$idx ON component_tbl(emmblock);
		CREATE FULLTEXT INDEX dyncontent$content$idx ON dyn_content_tbl(dyn_content);
		CREATE FULLTEXT INDEX dyntg$sname$idx ON dyn_target_tbl(target_shortname);
		CREATE FULLTEXT INDEX dyntg$descr$idx ON dyn_target_tbl(target_description);
	END;
END;
;;

DELIMITER ;
CALL createIndices;
DROP PROCEDURE createIndices;


INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.004', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.012', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.029', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.066', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.097', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.111', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.129', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.160', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.181', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.182', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.188', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.191', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.228', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.234', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.260', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.297', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.299', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.303', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.311', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.316', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.321', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.322', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.328', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.333', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.346', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.364', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.386', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.398', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.404', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.406', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.445', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.00.454', CURRENT_USER, CURRENT_TIMESTAMP);

INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.006', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.008', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.014', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.015', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.029', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.061', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.124', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.129', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.149', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.151', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.177', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.210', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.240', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.270', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.328', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.344', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.349', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.366', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.369', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.392', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.398', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.404', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.413', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.421', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.451', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.452', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.490', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.492', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.493', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.04.497', CURRENT_USER, CURRENT_TIMESTAMP);

INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.148', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.191', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.194', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.274', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.284', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.322', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.355', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.361', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.390', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.428', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.490', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.540', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.564', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.583', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.608', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.07.640', CURRENT_USER, CURRENT_TIMESTAMP);

INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.000', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.039', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.041', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.060', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.068', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.074', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.111', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.134', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.146', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.147', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.180', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.199', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.263', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.268', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.286', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.287', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.357', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.369', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.381', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.415', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.474', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('18.10.493', CURRENT_USER, CURRENT_TIMESTAMP);

INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.013', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.038', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.140', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.155', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.234', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.241', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.243', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.255', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.303', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
    VALUES ('19.01.432', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.433', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
	VALUES ('19.01.550', CURRENT_USER, CURRENT_TIMESTAMP);
INSERT INTO agn_dbversioninfo_tbl (version_number, updating_user, update_timestamp)
    VALUES ('19.01.634', CURRENT_USER, CURRENT_TIMESTAMP);

COMMIT;
