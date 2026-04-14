%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
-module(web_page).

% http://erlang.org/doc/design_principles/gen_server_concepts.html
-behaviour(gen_server).

% API
-export([start_link/0, start_link/1, start_link/2]).
-export([start_link_local/0, start_link_local/1, start_link_local/2]).

% Callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {}).

% API

% see: http://erlang.org/doc/man/gen_server.html#start_link-3
start_link_local() ->
    start_link_local(#{}).

start_link_local(Args) ->
    start_link_local(Args, []).

start_link_local(Args, Opts) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Args, Opts).

start_link() ->
    start_link(#{}).

start_link(Args) ->
    start_link(Args, []).

start_link(Args, Opts) ->
    gen_server:start_link(?MODULE, Args, Opts).

% Callbacks

init(_Args) ->

	%% Start wade supervisor directly with a map for options
	%% because wade_app:start(Port) defaults to [] which causes a crash.
	application:ensure_all_started(wade),
	wade_sup:start_link(8080, #{}), 

	%% Add memory status route at root
	wade:route(get, "/", fun(_Req) ->
        Memory = erlang:memory(),
        Rows = [io_lib:format(
            "<tr>"
            "  <td style='padding: 12px; border-bottom: 1px solid #eee; font-weight: bold; color: #555;'>~p</td>"
            "  <td style='padding: 12px; border-bottom: 1px solid #eee; text-align: right; font-family: monospace;'>~s</td>"
            "</tr>", 
            [K, format_bytes(V)]) || {K, V} <- Memory],
        
        Html = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "  <meta name='viewport' content='width=device-width, initial-scale=1'>",
            "  <title>Erlang Memory Status</title>",
            "  <style>",
            "    body { font-family: -apple-system, system-ui, sans-serif; margin: 0; padding: 20px; background-color: #f0f2f5; color: #1c1e21; }",
            "    .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }",
            "    h1 { margin-top: 0; color: #1a73e8; border-bottom: 2px solid #e8f0fe; padding-bottom: 10px; font-size: 24px; }",
            "    table { width: 100%; border-collapse: collapse; margin-top: 10px; }",
            "    th { text-align: left; padding: 12px; background-color: #f8f9fa; border-bottom: 2px solid #dee2e6; color: #495057; }",
            "    tr:last-child td { border-bottom: none; }",
            "    tr:hover { background-color: #f8f9fa; }",
            "  </style>",
            "</head>",
            "<body>",
            "  <div class='container'>",
            "    <h1>Erlang Memory Status</h1>",
            "    <table>",
            "      <thead><tr><th>Metric</th><th style='text-align: right;'>Usage</th></tr></thead>",
            "      <tbody>", Rows, "</tbody>",
            "    </table>",
            "  </div>",
            "</body>",
            "</html>"
        ],
        {200, lists:flatten(Html)}
	end, []), 

	%% Add route
	wade:route(get, "/hello/[name]", fun(Req) ->
        try
            Name = case wade:param(Req, name) of
                        undefined -> "Unknown";
                        N when is_binary(N) -> binary_to_list(N);
                        N -> N
                    end,
            Result = lists:flatten(io_lib:format("Hello ~s!", [Name])),
            error_logger:info_msg("Handler success: ~p~n", [Result]),
            {200, Result}
        catch
            E:R:S ->
                error_logger:error_msg("Handler crashed: ~p:~p~nStack: ~p~n", [E, R, S]),
                throw({error, R})
        end
	end, []), 

    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Internal functions

format_bytes(Bytes) when Bytes < 1024 ->
    io_lib:format("~p B", [Bytes]);
format_bytes(Bytes) when Bytes < 1048576 ->
    io_lib:format("~.2f KB", [Bytes / 1024.0]);
format_bytes(Bytes) ->
    io_lib:format("~.2f MB", [Bytes / 1048576.0]).
