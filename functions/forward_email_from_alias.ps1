<#
Created by Adam Rabenstein

.todo

.refs
http://exchangeshare.wordpress.com/2008/12/08/how-to-schedule-powershell-script-for-an-exchange-task/

#>

function forward_email_from_alias{
Param(
	[Parameter(Mandatory=$true)]
	$userAlias,
    [Parameter(Mandatory=$true)]
    $forwardToEmail
    )
Set-Mailbox -Identity $userAlias -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $forwardToEmail

}