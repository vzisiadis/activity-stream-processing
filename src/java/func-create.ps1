$groupId="com.contoso.functions"
$javaVersion="11"
$artifactId=$args[0]

## Azure Specific parts
$resourceGroup="rg-app-name"
$appName="func-app-name"
$appRegion="westeurope"
$appServicePlanName="asp-app-name"

mvn archetype:generate `
  "-DarchetypeGroupId=com.microsoft.azure" `
  "-DarchetypeArtifactId=azure-functions-archetype" `
  "-DgroupId=$groupId" `
  "-DjavaVersion=$javaVersion" `
  "-DartifactId=$artifactId" `
  "-Ddocker=true" `
  "-Dversion=1.0-SNAPSHOT" `
  "-DresourceGroup=$resourceGroup" `
  "-DappServicePlanName=$appServicePlanName" `
  "-DappName=$appName" `
  "-DappRegion=$appRegion" `
  "-DinteractiveMode=false"