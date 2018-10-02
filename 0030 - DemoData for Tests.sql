-- Only for db Berater GmbH to fill example data into the tables
-- the data are for test purposes only and are referring to the
-- infrastructure of db Berater GmbH-
USE CollectionDB;
GO

SET NOCOUNT ON;

DELETE system.Configurations;
DELETE data.AdminServers;
DELETE data.SQLServers;
GO

-- data.AdminServers
INSERT INTO data.AdminServers
(HostName, ServerName, DomainName, is_publisher)
VALUES
(N'NB-LENOVO-I', N'SQL_2016', N'asp.lidl.net', 0),
(N'NB-LENOVO-I', N'SQL_2014', N'ads.schwarz', 0),
(N'NB-LENOVO-I', N'SQL_2018', N'k-ads.schwarz', 0),
(N'NB-LENOVO-I', N'SQL_2017', N'de.int.kaufland', 1);
GO

-- Insert configuration parameters for the procedures and functions
INSERT INTO system.Configurations
(configuration_name, configuration_desc, configuration_value, AdminServer)
VALUES
('linked_server_name','internal name for the linked server object', N'lk_collector', NULL),
('cms_root_node', 'Root node in CMS under which the directories are to be created for the servers', 'Monitoring', NULL),
('activate_activity_log', 'set the parameter to 1 to track messages in data.ActivityLog', N'1', NULL);
GO

-- Fill data.SQLServers with test data
TRUNCATE TABLE data.SQLServers;
GO

INSERT	INTO data.SQLServers
(
	hostname,
	instance,
	systemtyp,
	type,
    alias,
    description,
    application,
    application_contact,
    application_contact_manual,
    Ticket,
    nagiosstate,
    nagioslinkname,
	AdminServer
)
SELECT
        SL.hostname,
        SL.instance,
        SL.systemtyp,
		SL.type,
        SL.alias,
        SL.description,
        SL.application,
        SL.application_contact,
        SL.application_contact_manual,
        SL.Ticket,
        SL.nagiosstate,
        SL.nagioslinkname,
		AdmS.Id AS AdminServer
FROM	dbo.[SQl-Server-Liste] AS SL
		INNER JOIN data.AdminServers AS AdmS
		ON (AdmS.DomainName = SL.domain);

-- show the data
SELECT * FROM system.Configurations;
SELECT * FROM data.AdminServers;
SELECT * FROM data.SQLServers;
GO

