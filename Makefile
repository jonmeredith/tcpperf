all : compile

compile :
	rebar compile

release :
	rebar generate
