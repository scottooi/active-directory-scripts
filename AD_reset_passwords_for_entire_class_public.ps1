Import-Module ActiveDirectory
## define the classroom of students to reset passwords for
$finishing_year = Read-Host 'Finishing Year'
$campus = Read-Host 'Campus'
$OU = "OU=FY$finishing_year,OU=$campus,OU=Students,OU=Users,DC=ad,DC=example,DC=com"

## get the list of students in that classroom
$properties_to_export = 'SamAccountName'
$to_reset_passwd_csv = '~\Desktop\to_reset_passwd.csv'

Get-ADUser -Filter * -SearchBase $OU -Properties $properties_to_export |
  Select-Object $properties_to_export |
  Export-Csv -Path $to_reset_passwd_csv -NoTypeInformation

## pause script to populate passwords
"Populate $to_reset_passwd_csv with new passwords"
'Set the header to "AccountPassword"'
'THEN'
Pause

## reset passwords
$to_reset_passwd_csv_import = Import-Csv $to_reset_passwd_csv
foreach ($student in $to_reset_passwd_csv_import) {
  $username = $student.SamAccountName
  $password = $student.AccountPassword
  Set-ADAccountPassword $username -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
}
