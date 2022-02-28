# Activate module 
Import-Module ActiveDirectory


function New-RandomUser {
    <#
    .SYNOPSIS
    Generate random user data from Https://randomuser.me/.
    .DESCRIPTION
    This function uses the free API for generating random user data from https://randomuser.me/
    .EXAMPLE
    Get-RandomUser 10
    .EXAMPLE
    Get-RandomUser -Amount 25 -Nationality us,gb 
    .LINK
    https://randomuser.me/
    #>
    
    [CmdletBinding()]
    param (
    [Parameter(Position = 0)]
    [ValidateRange(1,500)]
    [int] $Amount,
    
    [Parameter()]
    [ValidateSet('Male','Female')]
    [string] $Gender,
    
    # Supported nationalities: AU, BR, CA, CH, DE, DK, ES, FI, FR, GB, IE, IR, NL, NZ, TR, US
    [Parameter()]
    [string[]] $Nationality,
    
    
    [Parameter()]
    [ValidateSet('json','csv','xml')]
    [string] $Format = 'json',
    
    # Fields to include in the results.
    # Supported values: gender, name, location, email, login, registered, dob, phone, cell, id, picture, nat
    [Parameter()]
    [string[]] $IncludeFields,
    
    # Fields to exclude from the the results.
    # Supported values: gender, name, location, email, login, registered, dob, phone, cell, id, picture, nat
    [Parameter()]
    [string[]] $ExcludeFields
    )
    
    $rootUrl = "http://api.randomuser.me/?format=$($Format)"
    
    if ($Amount) {
    $rootUrl += "&results=$($Amount)"
    }
    
    if ($Gender) {
    $rootUrl += "&gender=$($Gender)"
    }
    
    
    if ($Nationality) {
    $rootUrl += "&nat=$($Nationality -join ',')"
    }
    
    if ($IncludeFields) {
    $rootUrl += "&inc=$($IncludeFields -join ',')"
    }
    
    if ($ExcludeFields) {
    $rootUrl += "&exc=$($ExcludeFields -join ',')"
    }
    
    Invoke-RestMethod -Uri $rootUrl
}

function New-Password
{
    $Alphabets = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
    $numbers = 0..9
    $specialCharacters = '~,!,@,#,$,%,^,&,*,(,),>,<,?,\,/,_,-,=,+'
    $array = @()
    $array += $Alphabets.Split(',') | Get-Random -Count 4
    $array[0] = $array[0].ToUpper()
    $array[-1] = $array[-1].ToUpper()
    $array += $numbers | Get-Random -Count 3
    $array += $specialCharacters.Split(',') | Get-Random -Count 3
    ($array | Get-Random -Count $array.Count) -join ""
}

# Create OU
$sites = ('Lyon', 'Paris')
$services = ('Informatique','Comptabilité','Direction','Marketing','Production')
$tld = "dom"

New-ADOrganizationalUnit -Name "Sites" -Path "DC=ESN,DC=$tld" -ProtectedFromAccidentalDeletion $false

Foreach($site in $sites){
    New-ADOrganizationalUnit -Name "$site" -Path "OU=Sites,DC=ESN,DC=$tld" -ProtectedFromAccidentalDeletion $false
    Foreach($service in $services){
        New-ADOrganizationalUnit -Name "$service" -Path "OU=$site,OU=Sites,DC=ESN,DC=$tld" -ProtectedFromAccidentalDeletion $false
        
        $users = New-RandomUser -Amount 30 -Nationality FR -IncludeFields name,location,dob,phone,cell -ExcludeFields picture | Select-Object -ExpandProperty results
        $usersResp = New-RandomUser -Amount 2 -Nationality FR -IncludeFields name,location,dob,phone,cell -ExcludeFields picture | Select-Object -ExpandProperty results
        Foreach($user in $users){
            $pass = New-Password 
            $userattributes = @{
                Name = -join ($user.name.first, " ", $user.name.last)
                AccountPassword = (ConvertTo-SecureString $pass -AsPlainText -Force)
                Title = -join ("Employé", " ", $service)
                Company = "$tld"
                CannotChangePassword = $true
                Path = "OU=$service,OU=$site,OU=Sites,DC=ESN,DC=$tld"
                City = $site

            }
            New-ADUser @userattributes
        }
        Foreach($user in $usersResp){
            $userattributes = @{
                Name = -join ($user.name.first, " ", $user.name.last)
                AccountPassword = (ConvertTo-SecureString $pass -AsPlainText -Force)
                Title = -join ("Responsable", " ", $service)
                CannotChangePassword = $false
                Path = "OU=$service,OU=$site,OU=Sites,DC=ESN,DC=$tld"
                City = $site

            }
            New-ADUser @userattributes

        }
    }
}

