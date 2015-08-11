%% Copyright (c) 2013 - 2014, Dmitry Kataskin
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%
%% * Redistributions of source code must retain the above copyright notice,
%% this list of conditions and the following disclaimer.
%% * Redistributions in binary form must reproduce the above copyright
%% notice, this list of conditions and the following disclaimer in the
%% documentation and/or other materials provided with the distribution.
%% * Neither the name of erlazure nor the names of its contributors may be used to
%% endorse or promote products derived from this software without specific
%% prior written permission.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%% POSSIBILITY OF SUCH DAMAGE.

-module(erlazure_blob_cloud_tests).
-author("Howard Su").

-compile(export_all).

-define(DEBUG, true).

-include("erlazure.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(account_name, "devstoreaccount1").
-define(account_key, "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==").

create_block_blob_test_() ->
                {setup,
                 fun start/0,
                 fun stop/1,
                 fun create_block_blob/1}.

create_page_blob_test_() ->
                {setup,
                 fun start/0,
                 fun stop/1,
                 fun create_page_blob/1}.

modify_page_blob_test_() ->
                {setup,
                 fun start/0,
                 fun stop/1,
                 fun modify_page_blob/1}.

modify_page_blob_large_test_() ->
                {setup,
                 fun start/0,
                 fun stop/1,
                 fun modify_page_blob_large/1}.


start() ->
    inets:start(),
    {ok, Pid} = erlazure:start(?account_name, ?account_key),
    UniqueContainerName = get_blobcontainer_unique_name(),
    {ok, created} = erlazure:create_container(Pid, UniqueContainerName),
    {Pid, UniqueContainerName}.

start_create() ->
    inets:start(),
    {ok, Pid} = erlazure:start(?account_name, ?account_key),
    UniqueContainerName = get_blobcontainer_unique_name(),
    {ok, created} = erlazure:create_container(Pid, UniqueContainerName),
    {Pid, UniqueContainerName}.

stop({Pid, ContainerName}) ->
    try erlazure:delete_container(Pid, ContainerName)
    catch
      throw:X -> X
    end.

get_blobcontainer_unique_name() ->
                test_utils:append_ticks("container").

create_block_blob({Pid, ContainerName}) ->
                Response = erlazure:put_block_blob(Pid, ContainerName, "testblockblob", <<"AAA">>),
                ?_assertMatch({ok, created}, Response).

create_page_blob({Pid, ContainerName}) ->
                Response = erlazure:put_page_blob(Pid, ContainerName, "testpageblob", 1024),
                ?_assertMatch({ok, created}, Response).

modify_page_blob({Pid, ContainerName}) ->
                Response = erlazure:put_page_blob(Pid, ContainerName, "testpageblob", 1024),
                ?_assertMatch({ok, created}, Response),
                TestData = test_utils:get_random_string(512, lists:seq(0, 255)),
                Response2 = erlazure:put_page(Pid, ContainerName, "testpageblob", 0, TestData),
                ?_assertMatch({ok, created}, Response2),
                {ok, ReadData} = erlazure:get_blob(Pid, ContainerName, "testpageblob", 
                  [{blob_range, "bytes=0-511"}]
                  ),
                ReadList = binary_to_list(ReadData),
                ?_assertMatch(ReadList, TestData),
                {ok, created} = erlazure:clear_page(Pid, ContainerName, "testpageblob", 0, 512),
                {ok, ReadData3} = erlazure:get_blob(Pid, ContainerName, "testpageblob", 
                  [{blob_range, "bytes=0-511"}]
                  ),
                ReadList3 = [X || X <- binary_to_list(ReadData3), X =/= 0],
                ?_assertMatch(ReadList3, []).


modify_page_blob_large({Pid, ContainerName}) ->
                Response = erlazure:put_page_blob(Pid, ContainerName, "testpageblob", 4194304 * 4),
                ?_assertMatch({ok, created}, Response),
                TestData = test_utils:get_random_string(4194304, lists:seq(0, 255)),
                Response2 = erlazure:put_page(Pid, ContainerName, "testpageblob", 0, TestData),
                ?_assertMatch({ok, created}, Response2),
                {ok, ReadData} = erlazure:get_blob(Pid, ContainerName, "testpageblob", 
                  [{blob_range, "bytes=0-4194303"}]
                  ),
                ReadList = binary_to_list(ReadData),
                ?_assertMatch(ReadList, TestData),
                {ok, created} = erlazure:clear_page(Pid, ContainerName, "testpageblob", 0, 4194304),
                {ok, ReadData3} = erlazure:get_blob(Pid, ContainerName, "testpageblob", 
                  [{blob_range, "bytes=0-4194303"}]
                  ),
                ReadList3 = [X || X <- binary_to_list(ReadData3), X =/= 0],
                ?_assertMatch(ReadList3, []).