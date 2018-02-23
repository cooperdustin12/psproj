SELECT TOP 10
Nodes.NodeID,
Nodes.Caption,

CASE
     WHEN (CTP.UniqueName = 'hrSystemUptime')
          THEN CASE
               WHEN (Nodes.MachineType LIKE 'Windows 2003%' OR Nodes.MachineType = 'Windows 2008 Server')
                    THEN CASE
                         WHEN (CAST(CTPS.Status AS BIGINT)/1000 + DATEDIFF(SECOND,CTPS.DateTime,GETUTCDATE()) > CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
                              THEN (CAST(CTPS.Status AS BIGINT)/1000 + DATEDIFF(SECOND,CTPS.DateTime,GETUTCDATE()))
                         ELSE (CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
                    END
               WHEN CAST(CTPS.Status AS BIGINT)/100 + DATEDIFF(SECOND,CTPS.DateTime,GETUTCDATE()) > (CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
                    THEN (CAST(CTPS.Status AS BIGINT)/100 + DATEDIFF(SECOND,CTPS.DateTime,GETUTCDATE()))
               ELSE (CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
          END
     WHEN (CTP.UniqueName = 'snmpEngineTime')
          THEN CASE
               WHEN (CAST(CTPS.Status AS BIGINT) + DATEDIFF(SECOND,CTPS.DateTime,GETUTCDATE()) > CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
                    THEN (CAST(CTPS.Status AS BIGINT) + DATEDIFF(SECOND,CTPS.DateTime,GETUTCDATE()))
               ELSE (CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
          END
     ELSE (CAST(Nodes.SystemUpTime AS BIGINT) + DATEDIFF(SECOND,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()))
END AS Seconds

FROM Nodes
LEFT JOIN CustomPollerAssignment CTPA
ON (Nodes.NodeID = CTPA.NodeID AND
          (CTPA.AssignmentName LIKE 'hrSystemUptime%' OR CTPA.AssignmentName LIKE 'snmpEngineTime%'))
LEFT JOIN CustomPollers CTP
ON CTPA.CustomPollerID = CTP.CustomPollerID
LEFT JOIN CustomPollerStatus CTPS
ON CTPA.CustomPollerAssignmentID = CTPS.CustomPollerAssignmentID


WHERE ((CTP.UniqueName IS NOT NULL)
OR CAST(Nodes.SystemUpTime AS BIGINT) >0)
AND (Nodes.Status <> 2)
AND (DATEDIFF(HOUR,Nodes.LastSystemUpTimePollUtc,GETUTCDATE()) < 1)

ORDER BY Seconds DESC
)

SELECT
SysUptime.NodeID,
SysUptime.caption,
SysUptime.Seconds/86400 AS Days,
SysUptime.Seconds/3600%24 AS Hours,
SysUptime.Seconds/60%60 AS Mins,
SysUptime.Seconds%60 AS Secs

FROM SysUptime