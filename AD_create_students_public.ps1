Param([Switch]$execute)

function Be-Sure($execute) {
  'This script requires a CSV file named new_students.csv on the Desktop'
  'with the headers: username,password,uidnumber,firstname,lastname,finishing_year,campus,ACL'
  if ($execute -ne $True) {
    'The script will run in test mode and will NOT create users unless -Execute is explicitly specified'
    Pause
  } else {
    'The script WILL create users if you proceed. Have you got the correct new_students.csv and headers?'
    $proceed = Read-Host 'Enter "yes" to proceed'
    if ($proceed -ne 'yes') {Throw 'No users were created.'}
  }
}
## if conditions met, exit function and continue script
Be-Sure -Execute $execute

Import-Module ActiveDirectory
## import / create required files and test for existence
$new_students_csv = '~\Desktop\new_students.csv'
$new_students_csv_import = Import-Csv $new_students_csv
if ($new_students_csv_import) {'SCRIPT: new_students.csv was found'} else {Throw 'SCRIPT: new_students.csv NOT found'}
$errors_log = '~\Desktop\errors.txt'
if (Test-Path $errors_log) {Throw 'SCRIPT: Remove old errors.txt first!'} else {New-Item $errors_log}
$created_log = '~\Desktop\created.txt'
if (Test-Path $created_log) {Throw 'SCRIPT: Remove old created.txt first!'} else {New-Item $created_log}

## begin user testing / creation
foreach ($student in $new_students_csv_import) {

  ## parameters from CSV file
  $username = $student.username
  $password = $student.password
  $uidnumber = $student.uidnumber
  $firstname = $student.firstname
  $lastname = $student.lastname
  $finishing_year = $student.finishing_year
  $campus = $student.campus
  $ACL = $student.ACL

  ## derived parameters
  $emailaddress = $username+'@student.example.com'
  $OU = "OU=FY$finishing_year,OU=$campus,OU=Students,OU=Users,DC=ad,DC=example,DC=com"

  $student_security_groups = @($ACL, 'network-student', 'file-storage-student', 'printers-student')

  ## run checks on parameters
  if (Get-ADUser -Filter {UIDNumber -eq $uidnumber}) {
    "USER NOT CREATED: $uidnumber is already in use!" | Tee-Object $errors_log -Append
  } elseif (Get-ADUser -Filter {SamAccountName -eq $username}) {
    "USER NOT CREATED: $username is already in use!" | Tee-Object $errors_log -Append
  } elseif ($username.length -gt 20) {
    "USER NOT CREATED: $username is >20 characters!" | Tee-Object $errors_log -Append
  } elseif ($username -notmatch '^[a-zA-Z0-9.]+$') {
    "USER NOT CREATED: $username contains illegal characters!" | Tee-Object $errors_log -Append
  } elseif ($password.length -lt 8) {
    "USER NOT CREATED: $username's password is <8 characters!" | Tee-Object $errors_log -Append
  } elseif (!([ADSI]::Exists("LDAP://$OU"))) {
    "USER NOT CREATED: The OU for $username does not exist!" | Tee-Object $errors_log -Append
  } else {

    ## only create users if all checks pass
    if ($execute -ne $True) {

      ## IN TEST MODE
      "$username will be created if script is run with -Execute" | Tee-Object $created_log -Append
    } else {

      ## IN EXECUTE MODE
      New-ADUser `
        -SamAccountName "$username" `
        -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
        -OtherAttributes @{'UIDNumber'=$uidnumber} `
        -GivenName "$firstname" `
        -Surname "$lastname" `
        -Name "$firstname $lastname" `
        -DisplayName "$firstname $lastname" `
        -UserPrincipalName "$emailaddress" `
        -EmailAddress "$emailaddress" `
        -Path "$OU" `
        -Enabled $True `
        -PasswordNeverExpires $True

      foreach ($group in $student_security_groups) {Add-ADGroupMember -Identity $group -Members $username}

      "$username was created with studentID $uidnumber" | Tee-Object $created_log -Append
    }
  }
}
