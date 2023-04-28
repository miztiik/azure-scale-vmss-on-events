targetScope = 'subscription'
param location string = deployment().location
param tags object

param rgName string

resource r_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

output rgName string = r_rg.name
output rgId string = r_rg.id

output stringOutput string = deployment().name
output integerOutput int = length(environment().authentication.audiences)
output booleanOutput bool = contains(deployment().name, 'Miztiik')
output arrayOutput array = environment().authentication.audiences
output objectOutput object = subscription()
