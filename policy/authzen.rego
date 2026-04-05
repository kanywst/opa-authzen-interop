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
