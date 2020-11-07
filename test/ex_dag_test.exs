defmodule ExDagTest do
  use ExUnit.Case
  doctest ExDag

  alias ExDag.DAG.Server
  alias ExDag.DAG.DAGTask
  alias ExDag.DAG

  test "greets the world" do
  end

  test "add dag task" do
    callback = fn _task, _payload ->
      {:ok, :done}
    end

    task = DAGTask.new(id: :a, handler: __MODULE__, data: {:op, :+})
    dag = DAG.new("my dag")
    {:ok, dag} = DAG.add_task(dag, task)
    t = DAG.get_task(dag, :a)
    assert t == task
  end

  test "add invalid dag task should give error" do
    dag = DAG.new("my dag")
    task = DAGTask.new(id: :a,  data: {:op, :+})
    assert {:error, :invalid_task} = DAG.add_task(dag, task)

    task = DAGTask.new(id: nil, data: {:op, :+})
    assert {:error, :invalid_task} = DAG.add_task(dag, task)
  end

  test "adding duplicate tasks should result in error" do
    callback = fn _task, _payload ->
      {:ok, :done}
    end

    dag = DAG.new("my dag")
    |> DAG.set_default_task_handler(__MODULE__)
    a = DAGTask.new(id: :a, data: {:op, :+})
    b = DAGTask.new(id: :b, data: {:op, :+})
    c = DAGTask.new(id: :a, data: {:op, :+})
    dag = DAG.add_task!(dag, a)
    dag = DAG.add_task!(dag, b)
    assert {:error, :task_exists} = DAG.add_task(dag, c)
  end

  test "invalid dag should result error" do

    dag = DAG.new("my dag")
    |> DAG.set_default_task_handler(__MODULE__)
    a = DAGTask.new(id: :a, data: {:op, :+})
    b = DAGTask.new(id: :b, data: {:op, :+})
    {:ok, dag} = DAG.add_task(dag, a)
    {:ok, dag} = DAG.add_task(dag, b)

    assert :invalid_dag == Server.run_dag(dag)
  end

  test "add dag task with parent task" do

    dag = DAG.new("my dag")
    |> DAG.set_default_task_handler(__MODULE__)
    a = DAGTask.new(id: :a, data: {:op, :+})
    b = DAGTask.new(id: :b, data: {:op, :+})
    {:ok, dag} = DAG.add_task(dag, a)
    assert {:ok, dag} = DAG.add_task(dag, b, :a)

    assert [:b] == DAG.get_deps(dag, :a)
    assert true == DAG.validate_for_run(dag)
  end

  test "add dag task with no existing parent task should return error" do

    dag = DAG.new("my dag")
    |> DAG.set_default_task_handler(__MODULE__)
    a = DAGTask.new(id: :a, data: {:op, :+})
    assert {:error, :no_parent_task} = DAG.add_task(dag, a, :c)
  end
end
