function Set-HorizonLog4jMitigation 
{

	<#
	.SYNOPSIS
	Set Log4j workaround
	.EXAMPLE
	Set-Log4jMitigation -HorizonRole Agent
	.EXAMPLE
	Set-Log4jMitigation -HorizonRole Server
	.PARAMETER HorizoRole
	Client or Server in the Horizon stack
	#>


    [CmdletBinding()]
    param(
        [ValidateSet(“Agent”,”Server”)]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$HorizonRole
    )

	PROCESS
	{
		IF($HorizonRole -eq "Server")	
		{
			#Grab reg path
			$RegVal1 = "HKLM:\SOFTWARE\VMware, Inc.\VMware VDM\plugins\wsnm\MessageBusService\Params"
			$RegVal2 = "HKLM:\SOFTWARE\VMware, Inc.\VMware VDM\plugins\wsnm\TomcatService\Params\"
			$RegVal3 = "HKLM:\SOFTWARE\VMware, Inc.\VMware VDM\plugins\wsnm\TunnelService\Params\"

			#Check Regpath
			$Path1 = Test-Path $RegVal1 -ErrorAction SilentlyContinue
			$Path2 = Test-Path $RegVal2 -ErrorAction SilentlyContinue
			$Path3 = Test-Path $RegVal3 -ErrorAction SilentlyContinue    

			IF(($Path1 -eq "$true") -and ($Path2 -eq "$true") -and ($Path3 -eq "$true"))
			{
				Try
				{
					#Create New values 
					$TomcatService = '-Xms128m -Xrs -XX:-OmitStackTraceInFastThrow -XX:+UseConcMarkSweepGC -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.util.logging.config.file=C:\Program Files\VMware\VMware View\Server\broker\conf\logging.properties -Dorg.apache.cxf.stax.maxElementDepth=1000 -Djava.locale.providers=COMPAT,CLDR -Dcatalina.base=C:\Program Files\VMware\VMware View\Server\broker\ -Dcatalina.home=C:\Program Files\VMware\VMware View\Server\broker\ -Djava.io.tmpdir=C:\Program Files\VMware\VMware View\Server\broker\temp -Djdk.tls.ephemeralDHKeySize=2048 -Djava.security.krb5.conf=C:\ProgramData\VMware\VDM\krb\krb5.conf -Dgraphic.profiles.properties=C:\Program Files\VMware\VMware View\Server\broker\conf\graphic-profiles.properties -Dlog4j2.formatMsgNoLookups=true'
					$MessageBusService = '-Xms128m -Xrs -XX:+UseConcMarkSweepGC -Djdk.tls.ephemeralDHKeySize=2048 -Dlog4j2.formatMsgNoLookups=true'
					$TunnelService = '-Xms128m -Xrs -XX:+UseConcMarkSweepGC -Dsimple.http.poller=simple.http.FastGranularPoller -Dsimple.http.connect.configurator=com.vmware.vdi.front.SimpleConfigurator -Djdk.tls.ephemeralDHKeySize=2048 -Djdk.tls.rejectClientInitiatedRenegotiation=true -Dlog4j2.formatMsgNoLookups=true'
					
					#Set log4j patch reg value MessageBusService
					Set-ItemProperty -Path $RegVal1 -Name JvmOptions -Value $MessageBusService -Force
					
					#Set log4j patch reg value TomcatService
					Set-ItemProperty -Path $RegVal2 -Name JvmOptions -Value $TomcatService -Force
					
					#Set log4j patch reg value TunnelService
					Set-ItemProperty -Path $RegVal3 -Name JvmOptions -Value $TunnelService -Force
				}
				
				Catch
				{
					
				Write-Host -ForegroundColor Red -BackgroundColor Black `
				"FAILED: Something unexpected happened. Please see https://kb.vmware.com/s/article/87073 for manual Server fix"					
				$_
				}
			}
			
			Else
			{
				Write-Host -BackgroundColor Black -ForegroundColor Yellow "WARNING: Log4j Mitigation does not apply to this product"
			}
			
			$Mitigated1 = (Get-ItemProperty -Path "$RegVal1").JVMOptions
			$Mitigated2 = (Get-ItemProperty -Path "$RegVal2").JVMOptions
			$Mitigated3 = (Get-ItemProperty -Path "$RegVal3").JVMOptions
			
			IF(($Mitigated1 -eq $MessageBusService) -and ($Mitigated2 -eq $TomcatService) -and ($Mitigated3 -eq $TunnelService))
			{
				Write-Host -ForegroundColor Green -BackgroundColor Black "SUCCESS: Log4j workaround has been applied. See new values below:"
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "
				WARNING: *** Server needs to be rebooted ASAP to complete mitigation ***
				"
				Write-Host -ForegroundColor Cyan -BackgroundColor Black "NEW_VALUE:  $((get-itemproperty $RegVal1).JVMOptions)"
				Write-Host -ForegroundColor Cyan -BackgroundColor Black "NEW_VALUE:  $((get-itemproperty $RegVal2).JVMOptions)"
				Write-Host -ForegroundColor Cyan -BackgroundColor Black "NEW_VALUE:  $((get-itemproperty $RegVal3).JVMOptions)"

			}
			
			Else
			{
				Write-Host -ForegroundColor Red -BackgroundColor Black `
				"FAILED: Log4j workaround was not applied. Please see https://kb.vmware.com/s/article/87073 for manual Server fix"
			}
			

		}

		ElseIF($HorizonRole -eq "Agent")
		{
			#Grab reg path
			$ClientRegVal = "HKLM:\SOFTWARE\VMware, Inc.\VMware VDM\Node Manager\JVM"
			$PathCheck = Test-Path $ClientRegVal
			
			IF($PathCheck -eq $true)
			{
				#New value
				$AgentJVM = '-Xmx32m -Djdk.tls.ephemeralDHKeySize=2048 -Dlog4j2.formatMsgNoLookups=true'
				
				Try
				{			
					#Set log4j patch reg value
					Set-ItemProperty -Path $ClientRegVal -Name JVMOptions -Value $AgentJVM -Force 
				}
				
				Catch
				{
					Write-Host -ForegroundColor Red -BackgroundColor Black "Something unexpected happened. Looke at this: "
					$_
				}
			}
			
			Else 
			{
				Write-Host -BackgroundColor Black -ForegroundColor Yellow "WARNING: Log4j Mitigation does not apply to this product"
			}
			
			$Mitigated = (Get-ItemProperty -Path "$ClientRegVal").JVMOptions
			
			IF(($Mitigated -eq "$AgentJVM" ))
			{
				Write-Host -ForegroundColor Green -BackgroundColor Black "SUCCESS: Log4j workaround has been applied."
				Write-Host -ForegroundColor Yellow -BackgroundColor Black "
				WARNING: *** Agent needs to be rebooted ASAP to complete mitigation ***
				"
				Write-Host -ForegroundColor Cyan -BackgroundColor Black "NEW_VALUE:$((get-itemproperty $ClientRegVal).JVMOptions)"
			}
			
			ElseIF (($Mitigated -ne "$AgentJVM" ))
			{
				Write-Host -ForegroundColor Red -BackgroundColor Black `
				"FAILED: Log4j workaround was not applied. Please see https://kb.vmware.com/s/article/87073 for manual Agent fix"
			}
		}
	}
}
