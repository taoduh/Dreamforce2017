# Queries

Select Id, DeveloperName, Language, MasterLabel, Description, Priority
FROM Territory2Type

Select Id, Name, Description, ActivatedDate, DeactivatedDate, State, DeveloperName, LastRunRulesEndDate, LastOppTerrAssignEndDate
FROM Territory2Model
WHERE Id IN ('xx')

Select Id, Territory2ModelId, DeveloperName, MasterLabel, ObjectType, IsActive, BooleanFilter
FROM ObjectTerritory2AssignmentRule
WHERE Territory2ModelId IN ('xx')

Select Id, RuleId, Field, Operation, SortOrder, Value
FROM ObjectTerritory2AssignmentRuleItem
WHERE Rule.Territory2ModelId IN ('xx')

Select Id, Name, Territory2TypeId, Territory2ModelId, ParentTerritory2Id, Description, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, DeveloperName
FROM Territory2
WHERE Territory2ModelId IN ('xx')

Select Id, UserId, Territory2Id, IsActive, RoleInTerritory2
FROM UserTerritory2Association
WHERE Territory2.Territory2ModelId IN ('xx')

Select Id, Territory2Id, RuleId, IsInherited
FROM RuleTerritory2Association
WHERE Territory2.Territory2ModelId IN ('xx')

Select Id, ObjectId, Territory2Id, AssociationCause, SobjectType
FROM ObjectTerritory2Association
WHERE Territory2.Territory2ModelId IN ('xx')

## VLOOKUPs to do if migrating

### No references, top level
- Territory2Model
- Territory2Type

### Refers to model
ObjectTerritory2AssignmentRule

### Refers to rule
ObjectTerritory2AssignmentRuleItem

### Refers to model and self
Territory2

### Refers to territory2
UserTerritory2Association
ObjectTerritory2Association (NOTE: only need rows where type = Territory2Manual)

### Refers to rule and territory2
RuleTerritory2Association
