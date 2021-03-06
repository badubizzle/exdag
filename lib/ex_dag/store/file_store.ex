defmodule ExDag.Store.FileStore do
  @moduledoc """
  DAGs store implementation using file system.
  """
  @behaviour ExDag.Store.Adapter

  @impl true
  def save_dag(options, dag) do
    dags_path = get_dags_path(options)
    file_name = "dag_file_#{dag.dag_id}"
    path = Path.join(dags_path, file_name)
    File.write(path, :erlang.term_to_binary(dag), [:write])
  end

  @impl true
  def get_dag_path(options, dag) do
    dags_path = get_dags_path(options)
    file_name = "dag_file_#{dag.dag_id}"
    {:ok, Path.join([dags_path, file_name])}
  end

  @impl true
  def save_dag_run(options, dag_run) do
    dags_path = get_dags_path(options)
    dag = dag_run.dag
    runs_path = Path.join([dags_path, "runs", dag.dag_id])
    File.mkdir_p(runs_path)
    path = Path.join([runs_path, dag_run.id])
    File.write(path, :erlang.term_to_binary(dag_run), [:write])
  end

  @impl true
  def get_dags(options) do
    dags_path = Keyword.get(options, :dags_path)

    case File.dir?(dags_path) do
      true ->
        File.ls!(dags_path)
        |> Enum.map(fn path ->
          dag =
            File.read!(Path.join([dags_path, path]))
            |> :erlang.binary_to_term()

          {dag.dag_id, dag}
        end)
        |> Map.new()
    end
  end

  def get_dag_runs(options, dag) do
    dags_path = get_dags_path(options)
    runs_path = Path.join([dags_path, "runs", dag.dag_id])

    if File.dir?(runs_path) do
      File.ls!(dags_path)
      |> Enum.map(fn path ->
        dag_run =
          File.read!(Path.join([dags_path, path]))
          |> :erlang.binary_to_term()

        {dag_run.id, dag_run}
      end)
      |> Map.new()
    else
      %{}
    end
  end

  defp get_dags_path(options) do
    Keyword.get(options, :dags_path)
  end
end
