import pulumi
from pulumi_azuread import get_user
from azure.identity import DefaultAzureCredential
from azure.mgmt.authorization import AuthorizationManagementClient
from pulumi_azure_native import authorization, resources
import uuid

email = "wi21b018@technikum-wien.at"
resource_group_name = "<resource_group_name>"

user = get_user(user_principal_name=email)

config = pulumi.Config("azure")
subscription_id = config.require("subscriptionId")

credential = DefaultAzureCredential()

auth_client = AuthorizationManagementClient(credential, subscription_id)
scope = f"/subscriptions/{subscription_id}"
assignments = auth_client.role_assignments.list_for_scope(scope, filter=f"principalId eq '{user.object_id}'")


assignments_list = []
for assignment in assignments:
    assignments_list.append({
        "name": assignment.name,
        "roleDefinitionId": assignment.role_definition_id,
        "scope": assignment.scope
    })

pulumi.export("roleAssignments", assignments_list)


role_definitions = authorization.get_role_definition_output(
    scope="/",
)

def get_roles_output(role_defs):
    roles = []
    for role in role_defs.value:
        roles.append({
            "name": role.role_name,
            "id": role.id,
            "roleDefinitionId": role.name,
            "description": role.description
        })
    return roles

roles_list = role_definitions.apply(get_roles_output)

pulumi.export("roles", roles_list)

user = get_user(user_principal_name=email)

role_definition = authorization.get_role_definition_output(
    role_name="Reader",
    scope="/"
)

resource_group = resources.get_resource_group_output(
    resource_group_name=resource_group_name
)

role_assignment_name = str(uuid.uuid4())

role_assignment = authorization.RoleAssignment(
    "readerRoleAssignment",
    scope=resource_group.id,
    role_assignment_name=role_assignment_name,
    principal_id=user.object_id,
    role_definition_id=role_definition.id,
    principal_type="User"
)

pulumi.export("roleAssignmentId", role_assignment.id)