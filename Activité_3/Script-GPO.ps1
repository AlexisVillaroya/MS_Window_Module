#GPO --> importer des objet dans des OU

#DDP (Default Domain Policy) --> Ensemble des objets du domaine
#DDCP (Default Domain Controller Policy) --> Ensemble des controleurs

#Au moment de la création ils ont le même GUID

#DDP fixe les règles de sécurité

#Rediriger les nouveaux objets dans des OU spécifique est une bonne pratique

#Ordre règles GPO OU --> Local Site Domain OU

#GPO 2 ou 3 paramètres maximum
#GPO noeuds de configuration --> noeud ordinateur et utilisateur ()
#On la lie sur une OU contenant le bon type
#Dossier Sysvol intégralité de l'AD 
#Policy --> GUID 

#GPO --> couple fichier adm et adml

#GPUpdate mis à jour des OU 
 
Import-Module ActiveDirectory

$tld = "dom"
$comp = "ESN"

New-ADOrganizationalUnit -Name "Groupes" -Path "OU=Sites,DC=$comp,DC=$tld" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "Domaine Local" -Path "OU=Groupes,OU=Sites,DC=$comp,DC=$tld" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "Globaux" -Path "OU=Groupes,OU=Sites,DC=$comp,DC=$tld" -ProtectedFromAccidentalDeletion $false

$services = ('Informatique','Comptabilité','Direction','Marketing','Production')

foreach($service in $services){
    $serv = -join ("Responsable", "", $service)
    $user = Get-ADUser -Filter 'title -eq $serv'

    foreach($u in $user){
        Add-ADGroupMember -Identity G-Responsable -Members $u.SamAccountName
    }
}