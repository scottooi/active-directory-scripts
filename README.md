# active-directory-scripts
Examples of my PowerShell scripts for AD

### AD_create_students_public.ps1
* I use this to create entire classes of students from a CSV file provided by the powers-that-be.
* The script checks parameters before executing, logs errors and successes, and forces test mode unless an -Execute switch is explicitly passed.

>If you use it (and I would be stoked if you did, being a newbie), note that you will have to update the ## derived parameters (lines 41-45) to suit your domain. Yes, I could abstract it out, but I was getting the evil eye for scripting rather than actually creating AD accounts so I decided good enough was enough...

### AD_reset_passwords_for_entire_class_public.ps1

I get requests to reset the passwords for an entire class of students so this script does two things:

* Build a CSV with the SamAccountName of everyone in that class for me to generate passwords against
* Pause for me to update the CSV

> I cannot automate the generation of the passwords sensibly because we need to use dictionary words but sometimes you get "interesting" word combinations... so we need a human.
