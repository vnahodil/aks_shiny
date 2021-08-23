# login to azure
az login

# register your app within AD group
az ad app create --display-name shiny-test

# supported account types: Accounts in any organizational directory (Any Azure AD directory - Multitenant) and personal Microsoft accounts (e.g. Skype, Xbox)


# get application ID from Azure
# get tenant ID from Azure

# add platform configuration - Authentication -> padd a platform -> for localhost: mobile and desktop applications, redirect URI: http://localhost:8100

# add token configuration: additional clains
