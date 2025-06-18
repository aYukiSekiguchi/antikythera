# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Antikythera.GearApplication.HttpcLogger do
  @moduledoc """
  Helper module for gear's custom error handler.

  To customize HTTP responses returned on errors, gear must implement an error handler module which

  - is named `YourGear.Controller.Error`, and
  - defines the following functions:
      - Mandatory error handlers
          - `error(Antikythera.Conn.t, Antikythera.ErrorReason.gear_action_error_reason) :: Antikythera.Conn.t`
          - `no_route(Antikythera.Conn.t) :: Antikythera.Conn.t`
          - `bad_request(Antikythera.Conn.t) :: Antikythera.Conn.t`
      - Optional error handlers
          - `bad_executor_pool_id(Antikythera.Conn.t, Antikythera.ExecutorPool.BadIdReason.t) :: Antikythera.Conn.t`
          - `ws_too_many_connections(Antikythera.Conn.t) :: Antikythera.Conn.t` (when your gear uses websocket)
          - `parameter_validation_error(Antikythera.Conn.t, Antikythera.Plug.ParamsValidator.parameter_type_t, AntikytheraCore.BaseParamStruct.validate_error_t) :: Antikythera.Conn.t` (when your gear uses parameter validation)

  This module generates `YourGear.error_handler_module/0` function, which is called by antikythera when handling errors.
  """

  alias Antikythera.GearName
  alias AntikytheraCore.GearModule

  @handlers [
    log: 9
  ]

  @doc false
  defun find_logger_module(gear_name :: v[GearName.t()]) :: nil | module do
    # during compilation of gear, allowed to call unsafe function
    mod = GearModule.httpc_logger_unsafe(gear_name)

    try do
      exported_funs = mod.module_info(:exports)
      not_defined_handlers = Enum.reject(@handlers, &(&1 in exported_funs))

      if Enum.empty?(not_defined_handlers) do
        mod
      else
        IO.puts("""
        [antikythera] warning: #{mod} exists but some of the Httpc log handlers are not defined: #{inspect(not_defined_handlers)};
        [antikythera]   #{mod} is not eligible for a Httpc log handler module.
        """)

        nil
      end
    rescue
      # module not defined
      UndefinedFunctionError -> nil
    end
  end

  defmacro __using__(_) do
    quote do
      # Assuming that module attribute `@gear_name` is defined in the __CALLER__'s context
      @error_handler_module Antikythera.GearApplication.HttpcLogger.find_logger_module(@gear_name)
      defun httpc_logger_module() :: nil | module do
        @error_handler_module
      end
    end
  end
end
