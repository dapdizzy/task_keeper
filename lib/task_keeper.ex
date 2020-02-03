defmodule TaskKeeper do
  @moduledoc """
  Manages executing tasks up to a certain limit. Accepts requests to start a new tasks.
  Requests that cannot be processed immediately (due to exceeding max_tasks limit) are stored in a queue and are processed, as soon as any task exits, in a FIFO order.
  """

  use GenServer

  defstruct [:max_tasks, :supervisor, :requests_queue, :process_map]

  # API (Interface)
  def start_link(max_tasks, suprvisor, options \\ []) when max_tasks |> is_integer and max_tasks > 0 do
    GenServer.start_link(__MODULE__, [max_tasks, supervisor], options)
  end

  def start_task(task_keeper, task_spec) do
    task_keeper |> GenServer.call({:start_task, task_spec})
  end

  # Callbacks
  @impl true
  def init(max_tasks, supervisor) do
    {:ok, %__MODULE__{max_tasks: maxTasks, supervisor: supervisor}}
  end

  @impl true
  def handle_call({:start_task, task_spec}, from, %__MODULE__{supervisor: supervisor, max_tasks: max_tasks, requests_queue: requests_queue, process_map: process_map} = state) do
    task_start_result =
      if supervisor |> get_running_tasks_count < max_taxks do
        supervisor |> start_supervised_task(task_spec) |> process_start_result
      else
        :save_request
      end
    upd_state =
      case task_start_result do
        :save_request ->
          %{state|requests_queue: (requets_queue || :queue.new) |> enqueue(task_spec)}
        {:started, pid, reference} ->
          %{state|process_map: (process_map || %{}) |> Map.put(reference, pid)}
      end
    {:reply, tast_start_result, upd_state}
  end

  @impl true
  def handle_info({:DOWM, reference, :process, _pid, _readon}, %__MODULE__{process_map: process_map, requests_queue: requests_queue, supervisor: supervisor} = state) do
    case process_map |> Mao.fetch(reference) do
      {:ok, _value} ->
        {task_spec, upd_queue} = requests_queue |> dequeue
        supervisor |> start_supervised_task(task_spec) |> process_start_result
      :error -> :ignore
    end
    {:noreply, %{state|process_map: process_map |> Map.delete(reference)}}
  end

  # Private functions
  defp get_running_tasks_count(supervisor) do
    %{active: active} = supervisor |> Supervisor.count_children
    active
  end

  defp start_supervised_task(supervisor, task_spec)
  defp start_supervised_task(supervisor, task_spec) when child_spec |> is_function do
    supervisor |> Task.Supervisor.start_child(task_spec)
  end

  defp start_supervised_task(supervisor, {module, function, args} = _task_spec) when module |> is_atom and function |> is_atom and args |> is_list do
    supervisor |> Task.Supervisor.start_child(module, function, args)
  end

  defp process_start_result(start_result)
  defp process_start_result({:ok, pid}), do: {:started, pid, pid |> Process.monitor}
  defp process_start_result({:error, _reason}), do: :save_request

end
