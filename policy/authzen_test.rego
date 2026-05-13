package authzen_test

import rego.v1

import data.authzen

# User PIDs
rick_pid := "CiRmZDA2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"
morty_pid := "CiRmZDE2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"
summer_pid := "CiRmZDI2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"
beth_pid := "CiRmZDM2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"
jerry_pid := "CiRmZDQ2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"

# --- can_read_user: always allow ---

test_rick_can_read_user if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": rick_pid},
		"action": {"name": "can_read_user"},
		"resource": {"type": "user", "id": "beth@the-smiths.com"},
	}
}

test_jerry_can_read_user if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": jerry_pid},
		"action": {"name": "can_read_user"},
		"resource": {"type": "user", "id": "beth@the-smiths.com"},
	}
}

# --- can_read_todos: always allow ---

test_beth_can_read_todos if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": beth_pid},
		"action": {"name": "can_read_todos"},
		"resource": {"type": "todo", "id": "todo-1"},
	}
}

# --- can_create_todo ---

test_rick_can_create_todo if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": rick_pid},
		"action": {"name": "can_create_todo"},
		"resource": {"type": "todo", "id": "todo-1"},
	}
}

test_morty_can_create_todo if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": morty_pid},
		"action": {"name": "can_create_todo"},
		"resource": {"type": "todo", "id": "todo-1"},
	}
}

test_beth_cannot_create_todo if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": beth_pid},
		"action": {"name": "can_create_todo"},
		"resource": {"type": "todo", "id": "todo-1"},
	}
}

test_jerry_cannot_create_todo if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": jerry_pid},
		"action": {"name": "can_create_todo"},
		"resource": {"type": "todo", "id": "todo-1"},
	}
}

# --- can_update_todo ---

test_rick_can_update_any_todo if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": rick_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "morty@the-citadel.com"}},
	}
}

test_morty_can_update_own_todo if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": morty_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "morty@the-citadel.com"}},
	}
}

test_morty_cannot_update_rick_todo if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": morty_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "rick@the-citadel.com"}},
	}
}

test_beth_cannot_update_own_todo if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": beth_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "beth@the-smiths.com"}},
	}
}

# --- can_delete_todo ---

test_rick_can_delete_any_todo if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": rick_pid},
		"action": {"name": "can_delete_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "morty@the-citadel.com"}},
	}
}

test_summer_can_delete_own_todo if {
	authzen.allow with input as {
		"subject": {"type": "user", "id": summer_pid},
		"action": {"name": "can_delete_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "summer@the-smiths.com"}},
	}
}

test_summer_cannot_delete_rick_todo if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": summer_pid},
		"action": {"name": "can_delete_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "rick@the-citadel.com"}},
	}
}

test_jerry_cannot_delete_own_todo if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": jerry_pid},
		"action": {"name": "can_delete_todo"},
		"resource": {"type": "todo", "id": "1", "properties": {"ownerID": "jerry@the-smiths.com"}},
	}
}

# --- unknown user: always deny ---

test_unknown_user_denied if {
	not authzen.allow with input as {
		"subject": {"type": "user", "id": "unknown-pid"},
		"action": {"name": "can_read_user"},
		"resource": {"type": "user", "id": "beth@the-smiths.com"},
	}
}

# --- Subject Search (spec Section 8.1) -------------------------------------

# can_read_user is allowed for every known user, so subject_search returns all 5.
test_subject_search_read_user_returns_all_known_users if {
	result := authzen.subject_search with input as {
		"subject": {"type": "user"},
		"action": {"name": "can_read_user"},
		"resource": {"type": "user", "id": "beth@the-smiths.com"},
	}
	count(result) == 5
}

# can_create_todo is restricted to admin/editor → Rick, Morty, Summer (3 users).
test_subject_search_create_todo_returns_admin_and_editors if {
	result := authzen.subject_search with input as {
		"subject": {"type": "user"},
		"action": {"name": "can_create_todo"},
		"resource": {"type": "todo", "id": "todo-1"},
	}
	count(result) == 3
	{"type": "user", "id": rick_pid} in result
	{"type": "user", "id": morty_pid} in result
	{"type": "user", "id": summer_pid} in result
}

# can_update_todo on a Rick-owned todo → only Rick (admin/evil_genius).
test_subject_search_update_owned_by_rick if {
	result := authzen.subject_search with input as {
		"subject": {"type": "user"},
		"action": {"name": "can_update_todo"},
		"resource": {
			"type": "todo",
			"id": "7240d0db-8ff0-41ec-98b2-34a096273b92",
			"properties": {"ownerID": "rick@the-citadel.com"},
		},
	}
	result == {{"type": "user", "id": rick_pid}}
}

# --- Resource Search (spec Section 8.2) ------------------------------------

# Rick can update every todo in data (admin).
test_resource_search_rick_update_returns_all_todos if {
	result := authzen.resource_search with input as {
		"subject": {"type": "user", "id": rick_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo"},
	}
	count(result) == count(data.todos)
}

# Morty can only update todos owned by morty@... (only one such todo in data).
test_resource_search_morty_update_returns_only_own if {
	result := authzen.resource_search with input as {
		"subject": {"type": "user", "id": morty_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo"},
	}
	count(result) == 1
	some item in result
	item.properties.ownerID == "morty@the-citadel.com"
}

# Beth (viewer) cannot update any todo.
test_resource_search_beth_update_returns_empty if {
	result := authzen.resource_search with input as {
		"subject": {"type": "user", "id": beth_pid},
		"action": {"name": "can_update_todo"},
		"resource": {"type": "todo"},
	}
	count(result) == 0
}

# --- Action Search (spec Section 8.3) --------------------------------------

# Rick (admin) is allowed every modeled action.
test_action_search_rick_returns_all_actions if {
	result := authzen.action_search with input as {
		"subject": {"type": "user", "id": rick_pid},
		"resource": {
			"type": "todo",
			"id": "7240d0db-8ff0-41ec-98b2-34a096273b92",
			"properties": {"ownerID": "rick@the-citadel.com"},
		},
	}
	count(result) == 5
}

# Morty (editor) on a Rick-owned todo: read_user/read_todos/create_todo only
# (no update/delete because ownership doesn't match).
test_action_search_morty_on_rick_todo if {
	result := authzen.action_search with input as {
		"subject": {"type": "user", "id": morty_pid},
		"resource": {
			"type": "todo",
			"id": "7240d0db-8ff0-41ec-98b2-34a096273b92",
			"properties": {"ownerID": "rick@the-citadel.com"},
		},
	}
	result == {
		{"name": "can_read_user"},
		{"name": "can_read_todos"},
		{"name": "can_create_todo"},
	}
}

# Morty (editor) on his own todo: full set including update/delete.
test_action_search_morty_on_own_todo if {
	result := authzen.action_search with input as {
		"subject": {"type": "user", "id": morty_pid},
		"resource": {
			"type": "todo",
			"id": "7240d0db-8ff0-41ec-98b2-34a096273b91",
			"properties": {"ownerID": "morty@the-citadel.com"},
		},
	}
	result == {
		{"name": "can_read_user"},
		{"name": "can_read_todos"},
		{"name": "can_create_todo"},
		{"name": "can_update_todo"},
		{"name": "can_delete_todo"},
	}
}

# Beth (viewer) on any todo: read-only.
test_action_search_beth_read_only if {
	result := authzen.action_search with input as {
		"subject": {"type": "user", "id": beth_pid},
		"resource": {
			"type": "todo",
			"id": "7240d0db-8ff0-41ec-98b2-34a096273b94",
			"properties": {"ownerID": "beth@the-smiths.com"},
		},
	}
	result == {
		{"name": "can_read_user"},
		{"name": "can_read_todos"},
	}
}
