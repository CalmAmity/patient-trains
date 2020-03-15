script.on_event(defines.events.on_train_changed_state, function(event)
	pcall(function()
		local train = event.train
		
		if (train.state == defines.train_state.wait_station) then
			handle_train_arriving(train)
			return
		end
	
		if (event.old_state == defines.train_state.wait_station) then
			handle_train_leaving(train)
			return
		end		
	end)
end)

function handle_train_arriving(train)
	local arrived_at_stop_index = train.schedule.current
	local train_table = retrieve_table_for_train(train.id)
	train_table.last_visited_stop_index = arrived_at_stop_index
end

function handle_train_leaving(train)
	local possible_next_stops = determine_possible_next_stops(train)
	
	if (not contains_enabled_stop(possible_next_stops)) then
		send_train_to_last_visited_stop(train)
	end
end

function determine_possible_next_stops(train)
	local train_table = retrieve_table_for_train(train.id)
	local leaving_stop_index = train_table.last_visited_stop_index
	local schedule = train.schedule
	local schedule_length = #schedule.records
	local next_stop_index = leaving_stop_index % schedule_length + 1
	local next_stop_schedule_record = schedule.records[next_stop_index]
	local next_stop_name = next_stop_schedule_record.station
	return game.get_train_stops({
		name = next_stop_name
	})
end

function contains_enabled_stop(stops)
	for i, train_stop in ipairs(stops) do
		local stop_is_disabled = train_stop.get_control_behavior().disabled
		if(not stop_is_disabled) then
			return true
		end
	end
	
	return false
end

function send_train_to_last_visited_stop(train)
	local train_table = retrieve_table_for_train(train.id)
	local leaving_stop_index = train_table.last_visited_stop_index
	local schedule = train.schedule
	schedule.current = leaving_stop_index
	train.schedule = schedule
end

function retrieve_table_for_train(id)
	if (not global.trains) then
		global.trains = {}
	end
	if (not global.trains[id]) then
		global.trains[id] = {}
	end
	return global.trains[id]
end