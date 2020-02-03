defmodule TaskKeeper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
     {Task.Supervisor, name: TaskKeeper.TaskSupervisor},
     {TaskKeeper, [10, TaskKeeper.TaskSupervisor]}
      # Starts a worker by calling: TaskKeeper.Worker.start_link(arg)
      # {TaskKeeper.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TaskKeeper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
