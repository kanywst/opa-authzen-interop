package authzen

import rego.v1

default allow := false

# Resolve user from subject ID (base64-encoded PID)
user := data.users[input.subject.id]

# can_read_user: always allow for authenticated users
allow if {
	input.action.name == "can_read_user"
	user
}

# can_read_todos: always allow for authenticated users
allow if {
	input.action.name == "can_read_todos"
	user
}

# can_create_todo: allow for admin or editor roles
allow if {
	input.action.name == "can_create_todo"
	some role in user.roles
	role in {"admin", "editor"}
}

# can_update_todo: admin can update any todo
allow if {
	input.action.name == "can_update_todo"
	"admin" in user.roles
}

# can_update_todo: evil_genius can update any todo
allow if {
	input.action.name == "can_update_todo"
	"evil_genius" in user.roles
}

# can_update_todo: editor can update only their own todos
allow if {
	input.action.name == "can_update_todo"
	"editor" in user.roles
	input.resource.properties.ownerID == user.email
}

# can_delete_todo: admin can delete any todo
allow if {
	input.action.name == "can_delete_todo"
	"admin" in user.roles
}

# can_delete_todo: editor can delete only their own todos
allow if {
	input.action.name == "can_delete_todo"
	"editor" in user.roles
	input.resource.properties.ownerID == user.email
}

# --- AuthZEN Search APIs (spec Section 8) -----------------------------------
# These rules are queried by the opa-authzen-plugin when the matching
# `search.*` field is set in config.yaml. Each rule enumerates candidate
# entities and re-evaluates `allow` with the candidate filled in, so search
# semantics stay consistent with single-evaluation semantics.

known_actions := {
	"can_read_user",
	"can_read_todos",
	"can_create_todo",
	"can_update_todo",
	"can_delete_todo",
}

# Subject Search: users (by PID) that would be permitted for the input
# action + resource. `input.subject.id` is absent (spec Section 8.1).
subject_search contains {"type": "user", "id": pid} if {
	some pid, _ in data.users
	allow with input as {
		"subject": {"type": "user", "id": pid},
		"action": input.action,
		"resource": input.resource,
	}
}

# Resource Search: todos that the input subject can act upon. The candidate
# resource carries the owner from data so ownership-based rules apply
# correctly (spec Section 8.2).
resource_search contains {
	"type": "todo",
	"id": tid,
	"properties": {"ownerID": todo.ownerID},
} if {
	some tid, todo in data.todos
	allow with input as {
		"subject": input.subject,
		"action": input.action,
		"resource": {
			"type": "todo",
			"id": tid,
			"properties": {"ownerID": todo.ownerID},
		},
	}
}

# Action Search: action names the input subject can perform on the input
# resource. `input.action` is absent in this request (spec Section 8.3).
action_search contains {"name": name} if {
	some name in known_actions
	allow with input as {
		"subject": input.subject,
		"action": {"name": name},
		"resource": input.resource,
	}
}
