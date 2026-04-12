-module(android_bridge).
-behaviour(gen_server).

%% API
-export([start_link/0, load_url/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {socket, port, next_ref = 1}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

load_url(URL) ->
    gen_server:call(?MODULE, {load_url, URL}).

init([]) ->
    PortStr = os:getenv("BRIDGE_PORT"),
    case PortStr of
        false ->
            {stop, no_bridge_port};
        _ ->
            Port = list_to_integer(PortStr),
            {ok, Socket} = gen_tcp:connect("localhost", Port, [binary, {packet, 4}, {active, true}]),
            %% Let's send a default URL to show something
            gen_server:cast(self(), {load_url, <<"https://www.erlang.org">>}),
            {ok, #state{socket = Socket, port = Port}}
    end.

handle_call({load_url, URL}, _From, State) ->
    NewState = do_load_url(URL, State),
    {reply, ok, NewState};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({load_url, URL}, State) ->
    NewState = do_load_url(URL, State),
    {noreply, NewState};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({tcp, _Socket, Data}, State) ->
    <<_Ref:8/binary, JSON/binary>> = Data,
    %% In a real app we'd decode JSON and handle it, but for now just echo
    io:format("Received from Android: ~s~n", [JSON]),
    {noreply, State};

handle_info({tcp_closed, _Socket}, State) ->
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Internal functions
do_load_url(URL, State) ->
    Ref = make_ref_bin(State#state.next_ref),
    %% Using standard JSON format expected by the Android side
    Msg = [<<"Android">>, <<":loadURL">>, [null, URL]],
    JSON = jsx:encode(Msg),
    gen_tcp:send(State#state.socket, <<Ref/binary, JSON/binary>>),
    State#state{next_ref = State#state.next_ref + 1}.

make_ref_bin(N) ->
    <<N:64/big>>.
