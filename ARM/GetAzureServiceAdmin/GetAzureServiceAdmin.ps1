Login-AzureRmAccount -EnvironmentName AzureChinaCloud
#登录账户，账户最好是有Azure AD管理员权限的

#选择订阅
Select-AzureRmSubscription -SubscriptionName '[订阅名称]'| Select-AzureRmSubscription

#获得Service Admin和 Co-Admin
Get-AzureRmRoleAssignment -IncludeClassicAdministrators | SELECT DisplayName,SignInName,RoleDefinitionName
