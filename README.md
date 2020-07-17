### Features

- Simple input (via CSV) for new user provisioning
	[![Inputfile example](https://github.com/Krapulax80/WC-Onboarding/raw/master/images/inputfile_example.png "Inputfile example")](Inputfile example "Inputfile example")

- Multiple domain configuration support  (via CSV configs)
	[![multi_domain](https://github.com/Krapulax80/WC-Onboarding/raw/master/images/domain_configs.png "multi_domain")](multi_domain "multi_domain")

- provisioning of Active Directory user object with custom attributes
- provisioning of cloud / on-prem mailbox (based on template account provided)
- o365 licensing (based on template account)
- DFS provisioning
- reporting

# How to use / Pre-requisites
The script assumes the following folder structure:

[![folder structure](https://github.com/Krapulax80/WC-Onboarding/raw/master/images/folder_structure.png "folder structure")](folder structure "folder structure")

The function folders and the main script entry is available on GitHub.
As the Credentials folder and the Config folder contain sensitive data, these are not uploaded.
- You will need to create the folders Credentials, Input, Logs, Output under the Onboarding folder
- You will also need to create the Config folder, and fill this with the domain specifics (found in Process-Onboarding01,ps1, staarting with $config.)
- You will also need to run the Create-Credential function with the -PasswordUpdate switch for AD, AAD (MS online) and Exchange credentials. This will generate (encrypted) text files containing the password of the admin accounts that will be used during the script run

# Process logic

The script meant to be called as a scheduled task using Powershell. It is possible to call manually as well.

```
\\<server>\c$\Scripts\AD\OnBoarding\STARTME_Process-Onboarding01.ps1 -Verbose
```
- This file *(STARTME_Process-Onboarding01.ps1)* will collect all input files (.csv-s) from the /output folder. Each file should contain as a very minimum the new starter's first and last name, a template account (an existing AD user, that will server as a template) and the employee ID (as given by HR usually), also the relevant domain. Ideally further details (start date, if the account is temporary, end date, contract type, holiday entitlement) should also be provided
- The script will run the starter processing against each line of each .csv (each line should be an individual new account)
- The actual provisinoning is being done by the *Process-OnBoarding01.ps1*  script. This script will be called on each user account. The script will use the other functions included to execute various provisions.
### Active Directory
- first the script will collect the basic AD parameters of the user (SAMAccountName, UserPrincipalName, etc.) and a few other AD-specific values (for example alternative proxy/smtp addresses); the logic shuld take care for duplicates, so for example if john.smith SAM is already taken, the user should get john.smith1 as his SAM. This will also affect UPN and other names. if the john.smith1 is also taken, john.smith2 will be used, ect.
- once all the name values, employee ID, etc. is unique, the script will create a new AD object; most of the settings will come from the provided template user
- the script then going to configure this object:
	- it will set the manager of the new user to match to the template account
	- it will provide JBA Access (a custom program relying on a custom AD attribute) to the user
	- it will adjust parameters based on the input file (employee id, holiday, start date, end date, etc.)
	- it will move the AD object to the same OU as the template and add it to each groups of the template object

### Exchange
- the script will also detect the current exchange type (in the company I am working for we both use office 365 accounts and on-prem users for undisclosed reasons) of the template account and will create the new user on the same environment
- the script will ensure the user has the matching location domain (.uk, .fr, .ie .etc) on the main SMTP of the new user
- the script will generate some secondary SMTP to the user account (for example, if the user's primary is NOT .uk, it will add .uk as a seconday; it will also generate a FirstnameS@ address next to the FirstnameSurname@ address)

### Syncronisations
- Before the exchange work the script will do an inter-site AD syncronisation.
After the exchange work it will be inter-site AD + AD <--> AAD sync

### Licensing
- The script in the next phase will wait, until the AAD object of the user is available, and it will attempt to license the user (based on the template account) using AD groups or individual licensing.

# Reporting

The script reports the outcome of each runs in a number of ways:

- During the run in PowerShell (ISE) it displays the ongoing actions via the console. This also includes a short summary.
- The "Logs" folder should contain logs of the actions, to be reviewed by IT staff
- The "Output" folder should contain CSV logs, for wider audiance
- Various details (password, summary, etc.) are also being sent to the selected email addresses at the end of the script run to inform selected members of the audience

(#TODO: Add example image here)
