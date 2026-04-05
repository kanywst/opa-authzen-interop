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
