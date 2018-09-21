require("stream")
require("net")
require("strutil")
require("terminal")
require("time")

SectionBreak="----*"

function TokensGetWord(Tokens)
local str=""

	while str==""
	do
	str=Tokens:next()
	end

return str
end


function TelnetReadLine(S)
local inchar
local str=""

inchar=S:readch()
while inchar ~= '\0' and inchar ~='\n'
do
	if string.byte(inchar) == 255
	then
		inchar=S:readch()
		inchar=S:readch()
	elseif inchar=='\r'
	then
			--do nothing
	else
		str=str..inchar
	end

inchar=S:readch()
end

return str
end



function TelnetReadPrompt(S, Prompt)
local inchar
local str=""

while str ~= Prompt
do
	str=""
	inchar=S:readch()
	while inchar ~='\0' and inchar ~='\n'
	do
		if string.byte(inchar) == 255
		then
			inchar=S:readch()
			inchar=S:readch()
		elseif inchar=='\r'
		then
			--do nothing
		else
			str=str..inchar
		end
		if str==Prompt then break end
		inchar=S:readch()
	end
end

return str
end



function TelnetWriteLine(S, line)
local str

S:writeln(line.."\r\n")
str=TelnetReadLine(S)
if string.len(str) ==0 then str=TelnetReadLine(S) end
return str
end


function TelnetCapturePrompt(S)
local cmdprompt

cmdprompt=TelnetWriteLine(S, "")
return cmdprompt
end



function TelnetReadToLine(S, pattern)
local str

str=TelnetReadLine(S)
while str ~= nil and strutil.pmatch(pattern,str) ==0
do
str=TelnetReadLine(S)
end

end


function ConnectLogin(IP, Port, User, Pass)
local S, str

str="tcp://"..IP..":"..Port
print(str.. " "..User.." "..Pass)
S=stream.STREAM(str);

if S ~= nil
then
	str=TelnetReadPrompt(S,"User:")
	TelnetWriteLine(S, User)
	str=TelnetReadPrompt(S,"Password:")
	str=TelnetWriteLine(S, Pass)
	--send blank line to ensure we get a prompt
	S:writeln("\r\n")
	
	-- A blank line is a bad sign, possible login fail
	str=TelnetReadLine(S)
	if str=="" then
		str=TelnetReadLine(S)
		-- This message means 'login failed'
		if str=="Applying Interface configuration, please wait ..."
		then
		S:close()
		return nil
		end
	end
	
	S:silence(100)
end

return S
end


function SysInfoCreate()
local sysinfo={}

sysinfo["name"]=""
sysinfo["model"]=""
sysinfo["mac"]=""
sysinfo["ip"]=""
sysinfo["netmask"]=""
sysinfo["gateway"]=""
sysinfo["ip4_source"]=""
sysinfo["ip6_source"]=""
sysinfo["serial"]=""
sysinfo["description"]=""
sysinfo["firmware"]=""
sysinfo["bootcode"]=""
sysinfo["time"]=""
sysinfo["uptime"]=""
sysinfo["location"]=""
sysinfo["contact"]=""
sysinfo["logging"]=""
sysinfo["syslog_hosts"]=""
sysinfo["sntp_server"]=""
sysinfo["sntp_mode"]=""
sysinfo["sntp_status"]=""
sysinfo["port_security"]=""
sysinfo["snmp"]=""

return sysinfo
end



function SysinfoParse(sysinfo, str, prefix, div1, div2, div3)
local Tokens, key, value


--[[
[System Description............................. GS724Tv4 ProSafe 24-port Gigabit Ethernet Smart Switch, 6.3.1.11, B1.0.0.4] [(GS724Tv4) #]
[System Name.................................... 5 Switch In Patch Panel] [(GS724Tv4) #]
[System Location................................ Unit 18] [(GS724Tv4) #]
[System Contact.................................] [(GS724Tv4) #]
[System Object ID............................... 1.3.6.1.4.1.4526.100.4.32] [(GS724Tv4) #]
[System Up Time................................. 340 days 8 hrs 45 mins 21 secs] [(GS724Tv4) #]
[Current SNTP Synchronized Time................. SNTP Client Mode Is Disabled] [(GS724Tv4) #]
]]--

--[[
show hardware

Switch: 1

System Description............................. GS748Tv5 ProSafe 48-port Gigabit Ethernet Smart Switch, 6.3.1.4, B1.0.0.4
Machine Model.................................. GS748Tv5
Serial Number.................................. 3H324XXXXXXXX
Burned In MAC Address.......................... 08:BD:43:XX:XX:XX
Software Version............................... 6.3.1.4
Bootcode Version............................... B1.0.0.4
Supported Java Plugin Version.................. 1.6
Current Time................................... Jan 30 09:56:44 2018 (UTC+0:00)
Current SNTP Sync Status....................... Success


]]--

if string.sub(str, 1, 2)=="[" then str=string.sub(str, 2) end
Tokens=strutil.TOKENIZER(str)
key=prefix..strutil.stripTrailingWhitespace(Tokens:next(div1))
if strutil.strlen(div2) > 0 then Tokens:next(div2) end
value=strutil.stripLeadingWhitespace(Tokens:next(div3))

if strutil.strlen(value) > 0
then
if key=="System Name" then sysinfo["name"]=value
elseif key=="Machine Model" then sysinfo["model"]=value
elseif key=="Serial Number" then sysinfo["serial"]=value
elseif key=="Software Version" then sysinfo["firmware"]=value
elseif key=="Bootcode Version" then sysinfo["bootcode"]=value
elseif key=="System Description" then sysinfo["description"]=value
elseif key=="Current Time" then sysinfo["time"]=value
elseif key=="System Up Time" then sysinfo["uptime"]=value
elseif key=="System Location" then sysinfo["location"]=value
elseif key=="System Contact" then sysinfo["contact"]=value
elseif key=="Burned In MAC Address" then sysinfo["mac"]=value
elseif key=="HTTP Mode (Unsecure)" then sysinfo["http_manage"]=value
elseif key=="HTTP Mode (Secure)" then sysinfo["https_manage"]=value
elseif key=="Java Mode" then sysinfo["java_manage"]=value
elseif key=="IP Address" then sysinfo["ip"]=value
elseif key=="Subnet Mask" then sysinfo["netmask"]=value
elseif key=="Default Gateway" then sysinfo["gateway"]=value
elseif key=="Configured IPv4 Protocol" then sysinfo["ip4_source"]=value
elseif key=="Configured IPv6 Protocol" then sysinfo["ip6_source"]=value
elseif key=="Console Logging" and value=="enabled" then sysinfo["logging"]=sysinfo["logging"].."console, "
elseif key=="Buffered Logging" and value=="enabled" then sysinfo["logging"]=sysinfo["logging"].."buffered, "
elseif key=="Syslog Logging" and value=="enabled" then sysinfo["logging"]=sysinfo["logging"].."syslog, "
elseif key=="Persistent Logging" and value=="enabled" then sysinfo["logging"]=sysinfo["logging"].."persistent, "
elseif key=="CLI Command Logging" and value=="enabled" then sysinfo["logging"]=sysinfo["logging"].."commands, "
elseif key=="Port Security Administration Mode" then sysinfo["port_security"]=value
elseif key=="Current SNTP Sync Status" then sysinfo["sntp_status"]=value
elseif key=="SNTP Client Mode" then sysinfo["sntp_mode"]=value
elseif key=="SNTP Host Address" then sysinfo["sntp_server"]=value
end

--[[
Logging Client Local Port           : 514
Logging Client Source Interface     : (not configured)

Log Messages Received               : 13903
Log Messages Dropped                : 0
Log Messages Relayed                : 0
]]--
end

return sysinfo
end



function	ProsafeGatherSysInfo(S, SysInfo, Send, prefix, div1, div2, div3)
local str, cmdprompt

cmdprompt=TelnetCapturePrompt(S)
str=TelnetWriteLine(S, Send)

--these commands don't end in a prompt, so we must send another line to trigger one
S:writeln("\r\n")

while str ~= cmdprompt
do
SysinfoParse(SysInfo, str, prefix, div1, div2, div3)
str=TelnetReadLine(S)
end
end


--[[
(GS724Tv4) #show port all

                 Admin     Physical   Physical   Link   Link    LACP   Flow
Intf      Type   Mode      Mode       Status     Status Trap    Mode   Mode
--------- ------ --------- ---------- ---------- ------ ------- ------ -------
g1               Enable    Auto                  Down   Enable  Enable Disable
g2               Enable    Auto       1000 Full  Up     Enable  Enable Disable
g3               Enable    Auto                  Down   Enable  Enable Disable
g4               Enable    Auto                  Down   Enable  Enable Disable
g5               Enable    Auto                  Down   Enable  Enable Disable
g6               Enable    Auto                  Down   Enable  Enable Disable
g7               Enable    Auto                  Down   Enable  Enable Disable
g8               Enable    Auto                  Down   Enable  Enable Disable
g9               Enable    Auto                  Down   Enable  Enable Disable
g10              Enable    Auto                  Down   Enable  Enable Disable
g11              Enable    Auto                  Down   Enable  Enable Disable
g12              Enable    Auto                  Down   Enable  Enable Disable
g13              Enable    Auto                  Down   Enable  Enable Disable
g14              Enable    Auto       1000 Full  Up     Enable  Enable Disable
g15              Enable    Auto                  Down   Enable  Enable Disable
g16              Enable    Auto                  Down   Enable  Enable Disable
g17              Enable    Auto                  Down   Enable  Enable Disable
g18              Enable    Auto                  Down   Enable  Enable Disable
g19              Enable    Auto                  Down   Enable  Enable Disable
g20              Enable    Auto       1000 Full  Up     Enable  Enable Disable
g21              Enable    Auto                  Down   Enable  Enable Disable
g22              Enable    Auto                  Down   Enable  Enable Disable
g23              Enable    Auto                  Down   Enable  Enable Disable
g24              Enable    Auto                  Down   Enable  Enable Disable
g25              Enable    Auto                  Down   Enable  Enable Disable
g26              Enable    Auto                  Down   Enable  Enable Disable

NOTE: "Admin mode" means the port is active
]]--

function ProsafeParsePortInfo(info)
local Port={}

Port.name=strutil.stripTrailingWhitespace(string.sub(info,1,8))
Port.active=strutil.stripTrailingWhitespace(string.sub(info,18,26))
Port.speed=strutil.stripTrailingWhitespace(string.sub(info,39,48))
Port.state=strutil.stripTrailingWhitespace(string.sub(info,50,56))
Port.macs=""

return(Port)
end


function ProsafeParsePortSecurity(info, Ports)
local Port, name

name=strutil.stripTrailingWhitespace(string.sub(info,1,8))
Port=Ports[tonumber(string.sub(name, 2))]
if Port ~= nil
then
Port.security=strutil.stripTrailingWhitespace(string.sub(info,9,17));
Port.dynamic_macs=strutil.stripTrailingWhitespace(string.sub(info,18,26))
Port.static_macs=strutil.stripTrailingWhitespace(string.sub(info,30,38))
end
end




function ProsafeGatherPortInfo(S)
local Ports={}
local str, Port, Tokens

TelnetWriteLine(S,"show port all")
TelnetReadToLine(S, SectionBreak)
str=TelnetReadLine(S);
while strutil.strlen(str) > 0
do
Port=ProsafeParsePortInfo(str)
if string.sub(Port.name, 1, 4) ~= "lag " then Ports[tonumber(string.sub(Port.name, 2))]=Port end

str=TelnetReadLine(S);
end

TelnetWriteLine(S,"show port-security all")
TelnetReadToLine(S, SectionBreak)
str=TelnetReadLine(S);
while strutil.strlen(str) > 0
do
ProsafeParsePortSecurity(str, Ports)
str=TelnetReadLine(S);
end


TelnetWriteLine(S,"show switchport protected")
TelnetReadToLine(S,"Member Ports :")
str=TelnetReadLine(S)
if strutil.strlen(str)==0 then str=TelnetReadLine(S) end

Tokens=strutil.TOKENIZER(str, ", ")
str=Tokens:next()
while str ~= nil
do
portnum=tonumber(string.sub(str, 2))
if Ports[portnum] ~= nil then Ports[portnum].protected="Enabled" end
str=Tokens:next()
end

return Ports
end



function ParseMACAddress(Ports, line)
local Tokens, MAC, str, Port

Tokens=strutil.TOKENIZER(line, " ")
if tonumber(Tokens:next()) ~= nil 
then
	
	MAC=TokensGetWord(Tokens)
	Port=tonumber(string.sub(TokensGetWord(Tokens), 2))
	
	if Ports[Port] ~= nil
	then
	if strutil.strlen(Ports[Port].macs) > 0 then Ports[Port].macs=Ports[Port].macs..", "..MAC
	else Ports[Port].macs=MAC
	end
	end
end

end



function ProsafeGatherMACAddressesOnPorts(S, Ports)
local str, cmdprompt
local Found=false


cmdprompt=TelnetCapturePrompt(S)
S:writeln("show mac-addr-table all\r\n");
str=TelnetReadLine(S)
while str ~= cmdprompt
do
	if Found == true
	then 
		if str=="" then break
		else
		ParseMACAddress(Ports, str)
		end
	end

	if string.sub(str,1,8)=="VLAN ID " then Found=true end
	str=TelnetReadLine(S)
end

end


--[[
SNMP Community Name Client IP Address  Client IP Mask   Access Mode  Status
------------------- ----------------- ----------------- ----------- --------
public              0.0.0.0           0.0.0.0           Read Only   Enable
private             0.0.0.0           0.0.0.0           Read/Write  Enable
]]--

function ProsafeParseSNMPCommunity(str)
local Tokens
local SNMPCom={}

	Tokens=strutil.TOKENIZER(str," ")
	SNMPCom.name=Tokens:next()
	SNMPCom.iprange=TokensGetWord(Tokens)
	SNMPCom.ipmask=TokensGetWord(Tokens)
	SNMPCom.access=TokensGetWord(Tokens)
	SNMPCom.status=TokensGetWord(Tokens)

	return SNMPCom
end



function ProsafeGatherSNMP(S, sysinfo)
local str
SNMPCommunities={}

TelnetWriteLine(S, "show snmpcommunity")
TelnetReadToLine(S, SectionBreak)
str=TelnetReadLine(S)
while strutil.strlen(str) > 0
do
	SNMPCom=ProsafeParseSNMPCommunity(str)
	if SNMPCom.access=="Read/Write" and SNMPCom.status=="Enable"
	then
	sysinfo["snmp_manage"]="Enabled"
	end

	table.insert(SNMPCommunities, SNMPCom)
	str=TelnetReadLine(S)
end

return SNMPCommunities
end


function ProsafeClearSNMPCommunities(S, SNMPCommunities)
local i, comm, str

for i,comm in ipairs(SNMPCommunities)
do
	str=TelnetWriteLine(S, "no snmp-server community "..comm.name)
	print(str)
end

end


function ProsafeAddSNMPCommunity(S, name, ip_range, ip_mask, perms)
local i, comm, str

if strutil.strlen(ip_range) > 0
then
str=TelnetWriteLine(S, "snmp-server community " .. name .. " " .. ip_range .. " " .. ip_mask .. " enable " .. perms)
else
str=TelnetWriteLine(S, "snmp-server community " .. name .. " " .. perms)
end
print(str)

end






--[[
Index  IP Address/Hostname       Severity   Port   Status
----- ------------------------ ---------- ------ -------------
1     192.168.5.1              warning    514    Active
]]--

function ProsafeGatherLoggingHosts(S, sysinfo)
local str, val, Tokens

-- logging hosts\r\n\r\nLogging Host List Empty\r\n\r\n(GS724Tv4) #"
--
TelnetWriteLine(S, "show logging hosts")
str=TelnetReadLine(S)
if strutil.strlen(str) == 0 then str=TelnetReadLine(S) end

if str == nil then return end
if str == "Logging Host List Empty" then return end

if strutil.pmatch(SectionBreak,str) ~= 0 then TelnetReadToLine(S,SectionBreak) end

str=TelnetReadLine(S)
while strutil.strlen(str) > 0
do
	Tokens=strutil.TOKENIZER(str," ")
	str=Tokens:next()
	
	val=tonumber(str)
	if val ~= nil and val > 0
	then
	sysinfo.syslog_hosts=sysinfo.syslog_hosts..TokensGetWord(Tokens)..", ";
	end
str=TelnetReadLine(S)
end

end



function ProsafeChangePassword(S, Old, New)

print(TelnetWriteLine(S, "password"))

S:expect("Enter old password:", Old.."\r\n")
S:expect("Enter new password:", New.."\r\n")
S:expect("Confirm new password:", New.."\r\n")

S:silence(100)
end

function ProsafeSetClock(S)
local str

str="clock set ".. time.format("%H:%M:%S")
str=TelnetWriteLine(S, str)

str="clock set ".. time.format("%m/%d/%Y")
str=TelnetWriteLine(S, str)

S:silence(100)
end


function ProsafeSetJavaManagement(S, active)
local str

if active == true
then
str=TelnetWriteLine(S, "ip http java")
str=TelnetWriteLine(S, "network javamode")
else
str=TelnetWriteLine(S, "no ip http java")
str=TelnetWriteLine(S, "no network javamode")
end

end

function ProsafeSetHTTPManagement(S, active)
local str

if active == true
then
str=TelnetWriteLine(S, "ip http server")
else
str=TelnetWriteLine(S, "no ip http server")
end

end



function ProsafeSetSntpSource(S, source)

if source=="" or source=="none"
then
TelnetWriteLine(S, "no sntp server ")
TelnetWriteLine(S, "no sntp client mode")
elseif string.sub(source, 1,6)=="bcast:"
then
TelnetWriteLine(S, "sntp server "..string.sub(source,7))
TelnetWriteLine(S, "sntp client mode broadcast")
else
TelnetWriteLine(S, "sntp server "..source)
TelnetWriteLine(S, "sntp client mode unicast")
end

end



function ProsafeReadSystemLog(S)
local str, Tokens

cmdprompt=TelnetCapturePrompt(S)
str=TelnetWriteLine(S, "show logging buffered")
S:writeln("\r\n")

str=TelnetReadLine(S)
while str ~= nil and str ~= cmdprompt
do
	if string.sub(str, 1, 1) == "<" then 
	Tokens=strutil.TOKENIZER(string.sub(str, 2), ">")
	level=tonumber(Tokens:next()) & 7
	
	if level== 0 then str="~r~eemergency~0 "..Tokens:remaining()
	elseif level== 1 then str="~ralert~0 "..Tokens:remaining()
	elseif level== 2 then str="~rcritical~0 "..Tokens:remaining()
	elseif level== 3 then str="~merror~0 "..Tokens:remaining()
	elseif level== 4 then str="~mwarn~0 "..Tokens:remaining()
	elseif level== 5 then str="~ynotice~0 "..Tokens:remaining()
	elseif level== 6 then str="~ginfo~0 "..Tokens:remaining()
	elseif level== 7 then str="~gdebug~0 "..Tokens:remaining()
	end
	
	Term:puts(str.."\r\n")
end
str=TelnetReadLine(S)
end

end


function UnpackSyslogURL(url)
local level=""
local ip=""
local port="514"
local len, Tokens, str

--[[
<severitylevel>          Enter Logging Severity Level (emergency|0, alert|1,
                         critical|2, error|3, warning|4, notice|5, info|6,
                         debug|7).
]]--

for i,str in ipairs({"emerg:","alert:","crit:","error:","warn:","notice:","info:","debug:"})
do
	len=string.len(str)
	if string.sub(url, 1, len)==str then 
		level=tostring(i-1) 
		url=string.sub(url, len+1)
		break
	end
end

Tokens=strutil.TOKENIZER(url,":")
ip=Tokens:next()
str=Tokens:next()
if strutil.strlen(str) > 0 then port=str end

return level, ip, port
end



function ProsafeSyslogConfig(S, active, servers)
local Tokens, serv, str

if active == true
then
	str=TelnetWriteLine(S, "logging syslog")

	Tokens=strutil.TOKENIZER(servers, ",")
	serv=Tokens:next()
	if serv ~= nil
	then
		for i=1,9,1
		do
			str=TelnetWriteLine(S, "logging host remove "..i)
		end
		S:silence(100)

		while serv ~= nil
		do
		level,ip,port=UnpackSyslogURL(serv)
		str="logging host "..ip.." ipv4 "..port
		if string.len(level) then str=str.." "..level end
		str=TelnetWriteLine(S, str)
		serv=Tokens:next()
		end
	end
else
	TelnetWriteLine(S, "no logging syslog")
end

end


function ProsafeSetBanner(S, banner)
print("set banner: "..banner)
TelnetWriteLine(S, "set clibanner \""..banner.."\"");
end



function ProsafeShowPorts(Term, Ports)
local name, Port, status=""

		for name,Port in pairs(Ports)
		do
			if Port.active=="Enable" then status="~gU~0"
			else status="~rD~0"
			end

			if Port.security=="Enabled" then status=status.."~ms~0" end
			if Port.protected=="Enabled" then status=status.."~yp~0" end

			while terminal.strlen(status) < 4
			do
				status=status.." "
			end
	
			Term:puts(string.format("% 4s %s % 10s % 5d % 5d %s\r\n", Port.name, status, Port.speed, tonumber(Port.dynamic_macs), tonumber(Port.static_macs), Port.macs))
		end
end


function ProsafePortEnable(S, port, state)

TelnetWriteLine(S, "interface "..port)
if state==true then TelnetWriteLine(S, "no shutdown")
else TelnetWriteLine(S, "shutdown")
end

TelnetWriteLine(S, "exit")
end


function ProsafeEnablePortList(S, ports, state)
local Tokens, curr

Tokens=strutil.TOKENIZER(ports,",")
curr=Tokens:next()
while curr ~=nil
do
ProsafePortEnable(S, curr, state)
curr=Tokens:next()
end

end



function ProsafePortLockMACs(S, port, macs)
local Tokens, mac, count

TelnetWriteLine(S, "interface "..port)
if macs=="" then TelnetWriteLine(S, "no port-security")
else 
	count=0
print("LOCK MACS: "..port.. " ".. macs)
	Tokens=strutil.TOKENIZER(macs, ",")
	mac=Tokens:next()
	while mac ~= nil
	do
	TelnetWriteLine(S, "port-security mac-address "..mac.." 1")
	count=count+1
	mac=Tokens:next()
	end

TelnetWriteLine(S, "port-security max-dynamic 0")
TelnetWriteLine(S, "port-security max-static "..tostring(count))
end
TelnetWriteLine(S, "exit")
end



function ProsafeLockPortList(S, Ports, list, locked)
local Tokens, curr

if locked == true then TelnetWriteLine(S, "port-security") end
Tokens=strutil.TOKENIZER(list, ",")
curr=Tokens:next()
while curr ~=nil
do
	portno=tonumber(string.sub(curr, 2))
	if Ports[portno] ~= nil and strutil.strlen(Ports[portno].macs) > 0
	then
		if locked 
		then 
			ProsafePortLockMACs(S, curr, Ports[portno].macs)
		else
			ProsafePortLockMACs(S, curr, "")
		end
	end
	curr=Tokens:next()
end

end


function ProsafeUnusedPortsOff(Ports)
local name,Port

		for name,Port in pairs(Ports)
		do
			print(Port.name.."  "..Port.state)
			if Port.state ~= "Up" then print(Port.name.." off") end
		end
end


function ProsafeAllPortsOn(Ports)
TelnetWriteLine(S, "no shutdown all")
end


function ProsafeSetIP4(S, ip4) 
if ip4=="dhcp" then TelnetWriteLine(S, "network protocol dhcp")
elseif ip4=="bootp" then TelnetWriteLine(S, "network protocol bootp")
else 
TelnetWriteLine(S, "network parms "..ip4.. " "..netmask.." "..gateway)
TelnetWriteLine(S, "network protocol none")
end
end


function DisplaySysInfo(Term, sysinfo)
local name, str, value, i, diff
local location=""
local contact=""

name=sysinfo.name
if name == "" then name="(unnamed)" end
if sysinfo.location ~="" then location=" at '"..sysinfo.location.."' " end

if sysinfo.contact ~="" 
then contact=" contact: '"..sysinfo.contact.."' "
else contact=""
end

Term:puts("~B"..sysinfo.model.." switch~0 ".. " '".. name.."' "..location.." ~cserialno:~0 ".. sysinfo.serial.. "  ~cmac:~0 "..sysinfo.mac .. contact.."\r\n")
Term:puts("~e~cIPv4:~0 "..sysinfo.ip.. " ~e~cnetmask:~0 "..sysinfo.netmask.. " ~e~cgateway:~0 ".. sysinfo.gateway.. " ~cset by:~0 ~m"..sysinfo.ip4_source.."~0\r\n")
value=time.tosecs("%b %d %H:%M:%S %Y ",sysinfo.time);
diff=time.secs() - value
if diff > 3600 then str="~r("..tostring(diff).."..s adrift from local)~0"
elseif diff > 60 then str="~y("..tostring(diff).."..s adrift from local)~0"
else str="("..tostring(diff).."..s adrift from local)"
end
if sysinfo.sntp_server ~= "" then str=str.." set by ~m"..sysinfo.sntp_mode.."~0 from ~m"..sysinfo.sntp_server.."~0".. "("..sysinfo.sntp_status..")" end

Term:puts("~cclock:~0  " .. sysinfo.time.. " "..str.."\r\n")
Term:puts("~cuptime:~0 ".. sysinfo.uptime.."\r\n")

Term:puts("~cport-security:~0 "..sysinfo.port_security.. "   ")
str="~cmanagement:~0 "
for i,value in ipairs({"http","https","java","snmp"})
do
	if sysinfo[value.."_manage"]=="Enabled" then str=str..value..", " end
end
Term:puts(str.."\r\n")
Term:puts("~clogging:~0 "..sysinfo.logging.." "..sysinfo.syslog_hosts.."\r\n")

--[[
if key=="Software Version" then sysinfo["firmware"]=value end
if key=="Bootcode Version" then sysinfo["bootcode"]=value end
if key=="System Description" then sysinfo["description"]=value end
if key=="Current Time" then sysinfo["time"]=value end
if key=="System Up Time" then sysinfo["uptime"]=value end
if key=="System Location" then sysinfo["location"]=value end
if key=="System Contact" then sysinfo["contact"]=value end
]]--


end



function PrintUsage()

print("USAGE:")
print("  lua prosafe.lua <host> [options]")
print()
print("-pass <password>         supply password for logging in")
print("-proxy <host>            proxy to connect to target via")
print("-set-pass <password>     change password")
print("-set-ip <address>        change ip4 address")
print("-sync-clock              sync clock to local")
print("-sntp <host>             set sntp server to get time updates from")
print("-syslog <host>           set server to send logging to")
print("-banner <text>           set telnet login banner")
print("-snmp                    set Simple Network Management Protocol to 'off', 'on' or ")
print("-ports                   show port status")
print("-disable-port <port>     turn off/disable a port")
print("-enable-port <port>      turn on a previously disabled/turned off port")
print("-lock-port <port>        lock a port to the current MAC address(es)")
print("-unlock-port <port>      unlock port to accept any MAC address")
print("-unused-off              turn off unusued ports")
print("-all-on                  turn on all ports")
print("-unlock                  unlock all ports")
print("-showlog                 output logs")
print("-save                    make setting changes permanent")
end	

function ParseCommandLine(args)
local i, arg
local settings={}

settings.target=""
settings.proxy=""
settings.port=60000
settings.password="password"
settings.ip4=""
settings.action=""
settings.enable_ports=""
settings.disable_ports=""
settings.lock_ports=""
settings.banner=nil
settings.sync_clock=false
settings.get_log=false
settings.clear_log=false
settings.check_log=false
settings.save=false

for i,arg in ipairs(args)
do
if strutil.strlen(arg) > 0
then
	if arg=="-pass" or arg=="-password"
	then
		settings.password=args[i+1]
		args[i+1]=""
	elseif arg=="-proxy" 
	then
		settings.proxy=args[i+1]
		args[i+1]=""
	elseif arg=="-set-pass" or arg=="-set-password"
	then
		settings.new_password=args[i+1]
		args[i+1]=""
	elseif arg=="-set-ip" or arg=="-set-ip4"
	then
		settings.ip4=args[i+1]
		args[i+1]=""
	elseif arg=="-sync-clock"
	then
		settings.sync_clock=true
	elseif arg=="-sntp"
	then
	settings.sntp_source=args[i+1]
	args[i+1]=""
	elseif arg=="-snmp"
	then
	settings.snmp=args[i+1]
	args[i+1]=""
	elseif arg=="-unused-off"
	then
	settings.action="unused-off"
	elseif arg=="-unlock"
	then
	settings.action="unlock"
	elseif arg=="-all-on"
	then
	settings.action="all-on"
	elseif arg=="-disable-port"
	then
	settings.disable_ports=settings.disable_ports..args[i+1]..","
	args[i+1]=""
	elseif arg=="-enable-port"
	then
	settings.enable_ports=settings.enable_ports..args[i+1]..","
	args[i+1]=""
	elseif arg=="-lock-port"
	then
	settings.lock_ports=settings.lock_ports..args[i+1]..","
	args[i+1]=""
	elseif arg=="-unlock-port"
	then
	settings.unlock_ports=settings.unlock_ports..args[i+1]..","
	args[i+1]=""
	elseif arg=="-syslog"
	then
		settings.syslog=args[i+1]
		args[i+1]=""
	elseif arg=="-banner"
	then
		settings.banner=args[i+1]
		args[i+1]=""
	elseif arg=="-showlog" then settings.action="showlog" 
	elseif arg=="-ports" then settings.action="ports"
	elseif arg=="-save" then settings.save="true"
	elseif arg=="-?" or arg=="-h" or arg=="-help" or arg=="--help" then PrintUsage()
	else settings.target=arg
	end
end
end

if strutil.strlen(settings.target)==0 then PrintUsage() end

return settings
end


function ProsafeGatherConfig(S)
local SysInfo

		SysInfo=SysInfoCreate()

		ProsafeGatherSysInfo(S, SysInfo, "show sysinfo", "", ".", ". ", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show hardware","", ".", ". ", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show network", "", ".", ". ", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show ip http", "", ".", ". ", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show logging", "", ":", "", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show port-security", "", ":", "", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show sntp server", "SNTP ", ":", "", "]")
		ProsafeGatherSysInfo(S, SysInfo, "show sntp client", "SNTP ", ":", "", "]")
		ProsafeGatherLoggingHosts(S, SysInfo)

return SysInfo
end	







-- 'main' starts here
Term=terminal.TERM()
settings=ParseCommandLine(arg)


print("act="..settings.action.." target="..settings.target)
if strutil.strlen(settings.target) > 0
then
	if strutil.strlen(settings.proxy) > 0
	then
	net.setProxy(settings.proxy)
	end
	
	print("Attempting connection...")
	S=ConnectLogin(settings.target, settings.port, "admin", settings.password)
	if S ~= nil
	then
		Term:puts("~gconnected!~0\n")
		TelnetWriteLine(S, "enable")
		TelnetWriteLine(S, "terminal length 0")
	
		if strutil.strlen(settings.new_password) > 0 then ProsafeChangePassword(S, settings.password, settings.new_password) end
		if settings.sync_clock==true then ProsafeSetClock(S) end
		if settings.ip4 ~="" then ProsafeSetIP4(S) end
	

	
		--commands that need config level
		TelnetWriteLine(S, "configure")
		if strutil.strlen(settings.sntp_source) > 0
		then
			ProsafeSetSntpSource(S, settings.sntp_source)
		end
		
		if settings.banner ~=nil then ProsafeSetBanner(S, settings.banner) end
	
		if strutil.strlen(settings.syslog) > 0
		then
			if settings.syslog=="off" or settings.syslog=="disable"
			then
			ProsafeSyslogConfig(S, false, "")
			else
			ProsafeSyslogConfig(S, true, settings.syslog)
			end
		end


		--Stuff to do with SNMP
		SNMPCommunities=ProsafeGatherSNMP(S, SysInfo)
		if settings.snmp=="off" or settings.snmp=="disable" 
		then 
			ProsafeClearSNMPCommunities(S, SNMPCommunities) 
		elseif settings.snmp=="on" or settings.snmp=="enable"
		then
			ProsafeAddSNMPCommunity(S, "public",  "", "", "ro");
   		ProsafeAddSNMPCommunity(S, "private", "", "", "rw");
		end
		SNMPCommunities=ProsafeGatherSNMP(S, SysInfo)
	
		
		if strutil.strlen(settings.disable_ports) > 0 then ProsafeEnablePortList(S, settings.disable_ports, false) end
		if strutil.strlen(settings.enable_ports) > 0 then ProsafeEnablePortList(S, settings.enable_ports, true) end
	
		SysInfo=ProsafeGatherConfig(S)
		Ports=ProsafeGatherPortInfo(S)
		ProsafeGatherMACAddressesOnPorts(S, Ports)
	
		if strutil.strlen(settings.lock_ports) > 0 then ProsafeLockPortList(S, Ports, settings.lock_ports, true) end
		if strutil.strlen(settings.unlock_ports) > 0 then ProsafeLockPortList(S, Ports, settings.lock_ports, false) end
	
		if settings.action == "" then DisplaySysInfo(Term, SysInfo)
		elseif settings.action== "showlog" then ProsafeReadSystemLog(S)
		elseif settings.action== "ports" then ProsafeShowPorts(Term, Ports)
		elseif settings.action== "unused-off" then ProsafeUnusedPortsOff(Ports)
		elseif settings.action== "all-on" then ProsafeAllPortsOn(Ports)
		elseif settings.action== "unlock" then 
			TelnetWriteLine(S, "no port-security")
		end
	
		TelnetWriteLine(S, "exit")
		if settings.save==true then TelnetWriteLine(S, "save") end
	else
		print("ERROR: Login failed to "..settings.target..":"..settings.port)	
	end
end

Term:reset()
